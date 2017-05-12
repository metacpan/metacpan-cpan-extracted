package Graph::Dijkstra;

use strict;
use warnings;

use Carp qw(croak carp);

use English qw(-no_match_vars);
$OUTPUT_AUTOFLUSH=1;

 
use vars qw($VERSION);
$VERSION = '0.70';

my $VERBOSE = 0;
my $verboseOutfile = *STDOUT;

use Readonly;

Readonly my $EMPTY_STRING => q{};
Readonly my %IS_GRAPHML_WEIGHT_ATTR => map { ($_ => 1) } qw(weight value cost distance height);
Readonly my %IS_GRAPHML_LABEL_ATTR => map { ($_ => 1) } qw(label name description nlabel);
Readonly my $PINF => 1e9999;         # positive infinity
Readonly my %GRAPH_ATTRIBUTES => (label=>$EMPTY_STRING, creator=>$EMPTY_STRING, edgedefault=>'undirected');
Readonly my %NODE_ATTRIBUTES => (label=>$EMPTY_STRING);
Readonly my %EDGE_ATTRIBUTES => (id=>$EMPTY_STRING, label=>$EMPTY_STRING, directed=>'undirected', weight=>0);
	
## no critic (PostfixControls)

#############################################################################
#used Modules                                                               #
#############################################################################


use Benchmark qw(:hireswallclock);
use Array::Heap::ModifiablePriorityQueue;
use Scalar::Util qw(looks_like_number);
use HTML::Entities qw(encode_entities);
use utf8;

#############################################################################
#Class Methods                                                              #
#############################################################################

sub verbose {
	VERBOSE(@_);
}

sub VERBOSE {
	my ($either, $verbose, $vOutfile) = @_;
	return $VERBOSE if !defined($verbose);
	$VERBOSE = $verbose;
	print {$verboseOutfile} 'verbose output ', (($VERBOSE) ? 'set' : 'unset'), "\n";
	if (defined($vOutfile) and (ref($vOutfile) eq 'GLOB' or ref($vOutfile) eq 'IO')) {
		$verboseOutfile = $vOutfile;
		print {$verboseOutfile} "verbose output redirected\n";
	}
}

sub stringifyAttribs {
	my ($either, $attribHref) = @_;
	
	return if ref($attribHref) ne 'HASH';
	
	my $val = '';
	foreach my $attrib (sort keys %$attribHref) {
		$val .= ', ' if $val;
		my $printval = (looks_like_number($attribHref->{$attrib})) ? "$attribHref->{$attrib}" : "'".encode_entities($attribHref->{$attrib})."'";
		$val .= "$attrib=>$printval";
	}
	return "( $val )";
}

sub hashifyAttribs {
	my ($either, $attribStr) = @_;
	
	my %keyvals = ();
	
	if ($attribStr =~ /^\(\s*(.+)\s*\)$/) {
		$attribStr = $1;
	}
	while ($attribStr =~ /([a-z]+) => ([+-]? [0-9]+ (?: \. [0-9]+ )?+|(?:(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')))/igx) {
		my $id = $1;
		my $val = $2;
		$val = substr($val,1,-1) if substr($val,0,1) eq "'";
		$keyvals{$id} = $val;
	}
	return \%keyvals;
}


sub _initialize {
	my ($self, $options) = @_;
	$self->{edges} = ();
	$self->{nodes} = ();
	
	foreach my $attrib (keys %GRAPH_ATTRIBUTES) {
		$self->{$attrib} = $GRAPH_ATTRIBUTES{$attrib};
	}
	
	if (ref($options) eq 'HASH') {
		foreach my $attrib (keys %$options) {
			if (exists($GRAPH_ATTRIBUTES{$attrib})) {
				$self->{$attrib} = $options->{$attrib};
			}
			else {
				carp "new: unrecognized graph attribute '$attrib'";
			}
		}
	}
	return $self;
}

sub new {
	my ($class, $options) = @_;
	
	my $self = {};
  bless $self, $class;

  return $self->_initialize($options);

  #return $self;
}


#############################################################################
#Graph Method(s)                                                            #
#############################################################################

sub graph {
	my ($self, $options) = @_;
	if (defined($options) and ref($options) eq 'HASH') {  #SET method call
		foreach my $attrib (keys %$options) {
			if (exists($GRAPH_ATTRIBUTES{$attrib})) {
				utf8::upgrade($options->{$attrib});
				$self->{$attrib} = $options->{$attrib};
			}
			else {
				carp "graph: unrecognized graph attribute '$attrib'";
			}
		}
		return $self;
	}
	#GET method call
	
	return( {map { ($_ => $self->{$_} ) } (keys %GRAPH_ATTRIBUTES)} );
}

#############################################################################
#Node Methods                                                               #
#############################################################################

sub node {
	my ($self, $nodeParam) = @_;
	
	croak "node: missing nodeID / options parameter" if !defined($nodeParam);
	
	if (ref($nodeParam) eq $EMPTY_STRING) {  #GET method call
		#my $nodeID = $nodeParam;
	
		if (exists($self->{nodes}{$nodeParam})) {
			my %node = map { ($_ => $self->{nodes}{$nodeParam}{$_} ) } (keys %NODE_ATTRIBUTES);
			$node{id} = $nodeParam;
			return( \%node );
		}
		return;
	}
	
	if (ref($nodeParam) eq 'HASH') {  #SET method call
		
		croak "node: missing \"id\" attribute in attributes hash" if !exists($nodeParam->{id});
		my $nodeID = $nodeParam->{id};
		croak "node: nodeID is not a SCALAR value" if ref($nodeID) ne $EMPTY_STRING;
		
		if (!exists($self->{nodes}{$nodeID})) {  #set default node attribute values for new node
			foreach my $attrib (keys %NODE_ATTRIBUTES) {
				$self->{nodes}{$nodeID}{$attrib} = $NODE_ATTRIBUTES{$attrib};
			}
		}
		
		foreach my $attrib (keys %$nodeParam) { #update node attribute values from parameter values
			if ( exists($NODE_ATTRIBUTES{$attrib}) ) {
				utf8::upgrade($nodeParam->{$attrib});
				$self->{nodes}{$nodeID}{$attrib} = $nodeParam->{$attrib};
			}
			elsif ($attrib ne 'id') {
				carp "node: unrecognized node attribute '$attrib'";
			}
		}
		
		return $self;
	}
	croak "node: invalid parameter: must be either a nodeID (simple scalar) or an attributes hash (reference)";
}

sub nodeExists {
	my ($self, $nodeID) = @_;
	
	croak "nodeExists: missing nodeID parameter" if !defined($nodeID);
	
	return (exists($self->{nodes}{$nodeID})) ? 1 : 0;
}


sub nodeList {
	my $self = shift;
	
	my @nodeList = ();
	foreach my $node (keys %{$self->{nodes}}) {
		push(@nodeList, { id=>$node, map {($_ => $self->{nodes}{$node}{$_})} (keys %NODE_ATTRIBUTES) } );
	}
	return @nodeList;
}


sub nodeIDsList {
	my $self = shift;
	
	my @nodeList = ();
	foreach my $node (keys %{$self->{nodes}}) {
		push(@nodeList, $node);
	}
	return @nodeList;
}


sub removeNode {
	my ($self, $nodeID) = @_;
	
	croak "removeNode: missing nodeID parameter" if !defined($nodeID);
	
	if (exists($self->{nodes}{$nodeID})) {
		
		if (exists($self->{edges}{$nodeID})) {  #delete edges where nodeID is source
			delete($self->{edges}{$nodeID});
		}
		
		foreach my $sourceID (keys %{$self->{edges}}) {	#delete edges where nodeID is target
			if (exists($self->{edges}{$sourceID}{$nodeID})) {
				delete($self->{edges}{$sourceID}{$nodeID});
			}
		}
		
		delete($self->{nodes}{$nodeID});
		return $self;
	}
	return;
}

#############################################################################
#Edge Methods                                                               #
#############################################################################

		
sub edge {
	my ($self, $edgeHref) = @_;
	
	croak "edge: missing parameter hash reference" if !defined($edgeHref) or ref($edgeHref) ne 'HASH';
	croak "edge: parameter hash missing sourceID" if !exists($edgeHref->{sourceID});
	croak "edge: parameter hash missing targetID" if !exists($edgeHref->{targetID});
	
	my $sourceID = $edgeHref->{sourceID};
	my $targetID = $edgeHref->{targetID};
	
	#checks that apply to both set & get calls
	
	if ($sourceID eq $targetID) {
		carp 'edge: source and target node IDs must be different: ' . $self->stringifyAttribs( $edgeHref );
		return;
	}
	
	if (!exists($self->{nodes}{$sourceID})) {
		carp "edge: sourceID $sourceID does not exist.";
		return;
	}
	
	if (!exists($self->{nodes}{$targetID})) {
		carp "edge: targetID $targetID does not exist.";
		return;
	}
	
	
	if (scalar(keys %$edgeHref) == 2) { #get method call, must be just sourceID, targetID
	
		if (exists($self->{edges}{$sourceID}{$targetID})) {
			return( {sourceID=>$sourceID, targetID=>$targetID, map { ($_ => $self->{edges}{$sourceID}{$targetID}{$_} ) } (keys %EDGE_ATTRIBUTES) } );
		}
	
		if (exists($self->{nodes}{$sourceID}) and exists($self->{nodes}{$targetID})) {
			return( {sourceID=>$sourceID, targetID=>$targetID, weight=>0} );
		}
		
		if (!exists($self->{nodes}{$sourceID})) {
			carp "edge: sourceID $sourceID does not exist";
			return;
		}
		
		carp "edge: targetID $targetID does not exist";
		return;
	}
	
	#set method call
	
	#directed value check
	if (exists($edgeHref->{directed}) and ($edgeHref->{directed} ne 'directed' and $edgeHref->{directed} ne 'undirected')) {
		carp "edge: unrecognized 'directed' attribute value '$edgeHref->{directed}'.";
		return;
	}
	
	#weight value check
	if (exists( $edgeHref->{weight} ) and (!looks_like_number($edgeHref->{weight}) or $edgeHref->{weight} <= 0)) {
		carp "edge: invalid edge weight (cost) $edgeHref->{weight}.";
		return;
	}
	
	if (exists($self->{edges}{$sourceID}{$targetID})) {  #update existing edge
		
		if (exists($edgeHref->{directed}) and $edgeHref->{directed} ne $self->{edges}{$sourceID}{$targetID}{directed}) {
			carp "edge: cannot change directed value for existing edge $sourceID $targetID '$self->{edges}{$sourceID}{$targetID}{directed}'. To change edge directed value, remove and re-add.";
			return;
		}
		my $edgeDirected = $self->{edges}{$sourceID}{$targetID}{directed};
		
		foreach my $attrib (keys %$edgeHref) { #update node attribute values from parameter values
			
			if ( exists($EDGE_ATTRIBUTES{$attrib}) ) {
				
				utf8::upgrade($edgeHref->{$attrib}) if !looks_like_number($edgeHref->{$attrib});
				
				$self->{edges}{$sourceID}{$targetID}{$attrib} = $edgeHref->{$attrib};
				$self->{edges}{$targetID}{$sourceID}{$attrib} = $edgeHref->{$attrib} if $edgeDirected eq 'undirected';
			}
			elsif ($attrib ne 'sourceID' and $attrib ne 'targetID') {
				carp "edge: unrecognized attribute '$attrib' not set";
			}
		}
		return $self;
	}

	#create new edge
	
	$edgeHref->{directed} = $self->{edgedefault} if !exists($edgeHref->{directed});
	
	if ($edgeHref->{directed} eq 'undirected' and exists($self->{edges}{$targetID}{$sourceID}) and $self->{edges}{$targetID}{$sourceID}{directed} eq 'directed') {
		carp "edge: $targetID $sourceID directed arc (edge) exists. Undirected edge $sourceID $targetID not created.  Remove then add.";
		return;
	}
	
	#set default attribute values
	foreach my $attrib (keys %EDGE_ATTRIBUTES) {
		$self->{edges}{$sourceID}{$targetID}{$attrib} = $EDGE_ATTRIBUTES{$attrib};
		$self->{edges}{$targetID}{$sourceID}{$attrib} = $EDGE_ATTRIBUTES{$attrib} if $edgeHref->{directed} eq 'undirected';
	}
		
	foreach my $attrib (keys %$edgeHref) { #set edge attribute values from parameter values
		
		next if ($attrib eq 'sourceID' or $attrib eq 'targetID');
		
		if ( exists($EDGE_ATTRIBUTES{$attrib}) ) {
			utf8::upgrade($edgeHref->{$attrib}) if !looks_like_number($attrib);
			$self->{edges}{$sourceID}{$targetID}{$attrib} = $edgeHref->{$attrib};
			$self->{edges}{$targetID}{$sourceID}{$attrib} = $edgeHref->{$attrib} if $edgeHref->{directed} eq 'undirected';
		}
		else {
			carp "edge: unrecognized attribute '$attrib' not set";
		}
	}
	
	return($self);
	
}

sub _getEdgeAttrib {
	my ($self, $sourceID, $targetID, $attrib) = @_;

	if (exists($self->{edges}{$sourceID}{$targetID}{$attrib})) {
		return $self->{edges}{$sourceID}{$targetID}{$attrib};
	}
	croak "_getEdgeAttrib: does not exist '$sourceID' '$targetID' '$attrib'";
	
}

sub _hasEdges {
	my ($self, $sourceID) = @_;
	return exists($self->{edges}{$sourceID});
}

sub removeEdge {
	my ($self, $edgeHref) = @_;
	
	croak "removeEdge: missing parameter hash reference" if !defined($edgeHref);
	croak "removeEdge: parameter hash missing sourceID" if !exists($edgeHref->{sourceID});
	croak "removeEdge: parameter hash missing targetID" if !exists($edgeHref->{targetID});
	
	my $sourceID = $edgeHref->{sourceID};
	my $targetID = $edgeHref->{targetID};
		
	if (exists($self->{edges}{$sourceID}{$targetID})) {
		
		my $directed = $self->{edges}{$sourceID}{$targetID}{directed};
		
		delete($self->{edges}{$sourceID}{$targetID});
		
		if ($directed eq 'undirected') {  #remove $targetID $sourceID for undirected edges
			
			delete($self->{edges}{$targetID}{$sourceID});
			
		}
	}
	else {
		carp "removeEdge: no edge found for sourceID $sourceID and targetID $targetID";
	}
		
	return $self;
}

	

sub edgeExists {
	my ($self, $edgeHref) = @_;
	
	croak "edgeExists: missing parameter hash reference" if !defined($edgeHref);
	croak "edgeExists: parameter hash missing sourceID" if !exists($edgeHref->{sourceID});
	croak "edgeExists: parameter hash missing targetID" if !exists($edgeHref->{targetID});
	
	my $sourceID = $edgeHref->{sourceID};
	my $targetID = $edgeHref->{targetID};
	
	return exists($self->{edges}{$sourceID}{$targetID});
}


sub adjacent {
	my ($self, $edgeHref) = @_;
	
	croak "adjacent: missing parameter hash reference" if !defined($edgeHref);
	croak "adjacent: parameter hash missing sourceID" if !exists($edgeHref->{sourceID});
	croak "adjacent: parameter hash missing targetID" if !exists($edgeHref->{targetID});
	
	my $sourceID = $edgeHref->{sourceID};
	my $targetID = $edgeHref->{targetID};
	
	return exists($self->{edges}{$sourceID}{$targetID});
}


sub adjacentNodes {
	my ($self, $sourceID) = @_;
	
	if (!defined($sourceID)) {
		croak "adjacentNodes: missing node ID parameter";
	}
	
	my @neighbors = ();
	if (exists($self->{edges}{$sourceID})) {
		foreach my $targetID (keys %{$self->{edges}{$sourceID}}) {
			push(@neighbors, $targetID);
		}
		croak "adjacentNodes: internal logic error" if scalar(@neighbors) == 0;
	}
#	else {
#		print {$verboseOutfile} "adjacentNodes: node $sourceID has no outbound edges\n" if $VERBOSE;
#	}
	return @neighbors;
}



#############################################################################
#Dijkstra Computation Methods                                               #
#############################################################################

#Computes Jordan center by creating all pairs shortest path matrix

sub vertexCenter {
	my ($self, $solutionMatrix) = @_;
	
	%$solutionMatrix = ();
	
	my @connectedNodeList = ();
	my $nodesEdgeCount = 0;
	
	my $totalNodes = 0;
	foreach my $nodeID ( $self->nodeIDsList() ) {
		$totalNodes++;
		$nodesEdgeCount++ if $self->_hasEdges($nodeID);
		push(@connectedNodeList, $nodeID);
	}
	my $nodeCount = scalar(@connectedNodeList);
	print {$verboseOutfile} "vertexCenter: graph contains $totalNodes nodes, $nodesEdgeCount nodes have one or more outbound edges\n" if $VERBOSE;
	
	foreach my $fromNodeID (@connectedNodeList) {
		
		$solutionMatrix->{rowMax}{$fromNodeID} = $PINF;
		
		foreach my $toNodeID (@connectedNodeList) {
			$solutionMatrix->{row}{$fromNodeID}{$toNodeID} = $PINF;
		}
		$solutionMatrix->{row}{$fromNodeID}{$fromNodeID} = 0;
	}
	my $hasDirectedEdges = 0;
	foreach my $nodeID (@connectedNodeList) {
		foreach my $targetID ($self->adjacentNodes($nodeID)) {
			if ($self->_getEdgeAttrib($nodeID, $targetID, 'directed') eq 'directed') {
				$hasDirectedEdges = 1;
				last;
			}
		}
		last if $hasDirectedEdges;
	}
	my $matrixComputations = ($totalNodes * $totalNodes) - $totalNodes;
	if ($nodesEdgeCount < $totalNodes) {
		my $nodesNoEdges = $totalNodes - $nodesEdgeCount;
		$matrixComputations -= $nodesNoEdges * ($totalNodes - 1);
	}
	$matrixComputations = $matrixComputations / 2 if !$hasDirectedEdges;
	print {$verboseOutfile} "vertexCenter: graph has directed edges.  Computing shortest path for A -> C and C -> A separately.\n" if $hasDirectedEdges and $VERBOSE;
	print {$verboseOutfile} "vertexCenter: graph has no directed edges.  Shortest path for A -> C and C -> A are same.\n" if !$hasDirectedEdges and $VERBOSE;
	print {$verboseOutfile} "vertexCenter: performing $matrixComputations shortest path computations.\n" if $VERBOSE;
	
	#should add code to limit computations at reasonable number
	
	my $cycle = 0;
	my $t0 = Benchmark->new;
	
	foreach my $origin (@connectedNodeList) {
		
		next if !$self->_hasEdges($origin);  #skip origin nodes that have no outbound edges, all paths are infinite
		#print '.';
		foreach my $destination (@connectedNodeList) {
			
			next if $solutionMatrix->{row}{$origin}{$destination} < $PINF or $origin eq $destination;
			#print "shortest path $origin -> $destination...";
			
			my $pq = Array::Heap::ModifiablePriorityQueue->new();	
			
			my %solution = ();
			my %unvisited = ();
			foreach my $node (@connectedNodeList) {
				next if $node ne $destination and !$self->_hasEdges($node);  #solution cannot include intermediate nodes with no outbound edges
				$solution{$node}{weight} = $PINF;
				$pq->add($node, $PINF);
			}
				
			$solution{$origin}{weight} = 0;
			$pq->add($origin,0); #modify weight of origin node
			
			
			#my $foundSolution = 0;
			while ($pq->size()) {
				$cycle++;
				
				my $visitNode = $pq->get();
				
				$solutionMatrix->{row}{$origin}{$visitNode} = $solution{$visitNode}{weight};
				$solutionMatrix->{row}{$visitNode}{$origin} = $solution{$visitNode}{weight} if !$hasDirectedEdges;
				
				last if ($visitNode eq $destination);
				
				foreach my $adjacentNode ($self->adjacentNodes($visitNode)) {
					next if !defined($pq->weight($adjacentNode));
					
					my $thisWeight = $solution{$visitNode}{weight} + $self->{edges}{$visitNode}{$adjacentNode}{weight};
					if ($thisWeight < $solution{$adjacentNode}{weight}) {
						$solution{$adjacentNode}{weight} = $thisWeight;
					#	$solution{$adjacentNode}{prevnode} = $visitNode;
						$pq->add($adjacentNode, $thisWeight);
					}
				}
			}
				
			undef($pq);
		}
	}
	#print "\n cycles=$cycle\n";
	if ($VERBOSE) {
		my $t1 = Benchmark->new;
		#if ($cycle >= 1000) {
		#	print "\n";
		#}
		my $td = timediff($t1, $t0);
	  print {$verboseOutfile} "computing shortest path matrix took: ",timestr($td),"\n";
	}
	my $graphMinMax = $PINF;
	my $centerNode = '';
	foreach my $origin (@connectedNodeList) {
		my $rowMax = 0;
		foreach my $destination (@connectedNodeList) {
			next if $origin eq $destination;
			if ($solutionMatrix->{row}{$origin}{$destination} > $rowMax) {
				$rowMax = $solutionMatrix->{row}{$origin}{$destination};
			}
		}
		$solutionMatrix->{rowMax}{$origin} = $rowMax;
		if ($rowMax < $graphMinMax) {
			$graphMinMax = $rowMax;
		}
	}
	$solutionMatrix->{centerNodeSet} = [];
	if ($graphMinMax < $PINF) {
		foreach my $origin (@connectedNodeList) {
			if ($solutionMatrix->{rowMax}{$origin} == $graphMinMax) {
				push(@{$solutionMatrix->{centerNodeSet}}, $origin);
			}
		}
	}
	else {
		carp "vertexCenter: Graph contains disconnected sub-graph / non-reachable node pairs. Center node set undefined.";
		$graphMinMax = 0;
	}
	#print "centernodeset ", join(',', @{$solutionMatrix->{centerNodeSet}}), "\n";
	return($graphMinMax);
}

sub farthestNode {  ## no critic (ProhibitExcessComplexity)
	my ($self, $solutionHref) = @_;
	
	if (!exists($solutionHref->{originID})) {
		croak "farthestNode: originID attribute not set in solution hash reference parameter";
	}
	my $originID = $solutionHref->{originID};
	
	if (!exists($self->{nodes}{$originID})) {
		carp "farthestNode: originID not found: $originID";
		return 0;
	}
	elsif (!$self->_hasEdges($originID)) {
		carp "farthestNode: origin node $originID has no edges";
		return 0;
	}
	my $pq = Array::Heap::ModifiablePriorityQueue->new();
	
	my %solution = ();		#initialize the solution hash
	my %unvisited = ();
	foreach my $node ($self->nodeIDsList()) {
		$solution{$node}{weight} = $PINF;
		$solution{$node}{prevnode} = $EMPTY_STRING;
		$pq->add($node, $PINF);
	}
		
	$solution{$originID}{weight} = 0;
	$pq->add($originID,0); #modify weight of origin node
	
	my $cycle = 0;
	my $t0 = Benchmark->new;
	
	while ($pq->size()) {
		$cycle++;
		#print '.' if $VERBOSE and ($cycle % 1000 == 0);
		
		my $visitNode = $pq->get();
		next if !$self->_hasEdges($visitNode);
		
		foreach my $adjacentNode ($self->adjacentNodes($visitNode)) {
			next if !defined($pq->weight($adjacentNode));
			
			my $thisWeight = $solution{$visitNode}{weight} + $self->_getEdgeAttrib($visitNode, $adjacentNode, 'weight' );
			if ($thisWeight < $solution{$adjacentNode}{weight}) {
				$solution{$adjacentNode}{weight} = $thisWeight;
				$solution{$adjacentNode}{prevnode} = $visitNode;
				$pq->add($adjacentNode, $thisWeight);
			}
		}
	}
	if ($VERBOSE) {
		my $t1 = Benchmark->new;
		#if ($cycle >= 1000) {
		#	print "\n";
		#}
		my $td = timediff($t1, $t0);
	  print {$verboseOutfile} "dijkstra's algorithm took: ",timestr($td),"\n";
	}
  
	my $farthestWeight = 0;
	foreach my $node (sort keys %solution) {
		
		if ($solution{$node}{weight} < $PINF and $solution{$node}{weight} > $farthestWeight) {
			$farthestWeight = $solution{$node}{weight};
			#$farthestnode = $node;
		}
	}
	
	croak "farthestNode: path weight to farthest node is 0" if $farthestWeight == 0;
	
	
	my $solutioncnt = 0;
	%{$solutionHref} = (
		desc => 'farthest',
		originID => $originID,
		weight => $farthestWeight,
	);
	
	foreach my $farthestnode (sort keys %solution) {
		if ($solution{$farthestnode}{weight} == $farthestWeight) {
			
			$solutioncnt++;
			
			print {$verboseOutfile} "\nfarthestNode: (solution $solutioncnt) farthest node from origin $originID is $farthestnode at weight (cost) $farthestWeight\n" if $VERBOSE;
			
			my $fromNode = $solution{$farthestnode}{prevnode};
			my @path = ( $farthestnode, $fromNode );
			
			my %loopCheck = ();
			while ($solution{$fromNode}{prevnode} ne $EMPTY_STRING) {
				$fromNode = $solution{$fromNode}{prevnode};
				if (exists($loopCheck{$fromNode})) {
					print STDERR "farthestNode: path loop at $fromNode\n";
					print STDERR 'farthestNode: path = ', join(',',@path), "\n";
					die 'farthestNode: internal error: destination to origin path logic error';
				}
				$loopCheck{$fromNode} = 1;
				push(@path,$fromNode);
			}
			
			@path = reverse(@path);
			
			my $nexttolast = $#path - 1;
			
			$solutionHref->{path}{$solutioncnt}{destinationID} = $farthestnode;
			$solutionHref->{path}{$solutioncnt}{edges} = [];
				
			foreach my $i (0 .. $nexttolast) {
				
				push(@{$solutionHref->{path}{$solutioncnt}{edges}}, {sourceID => $path[$i], targetID => $path[$i+1], weight => $self->edge( { sourceID=>$path[$i], targetID=>$path[$i+1] } )->{weight} } );
				
			}
		}
	}

	$solutionHref->{count} = $solutioncnt;
	
	return($farthestWeight);
}

sub shortestPath { ## no critic (ProhibitExcessComplexity)
	my ($self, $solutionHref) = @_;
	
	if (!exists($solutionHref->{originID})) {
		croak "farthestNode: originID attribute not set in solution hash reference parameter";
	}
	my $originID = $solutionHref->{originID};
	
	if (!exists($solutionHref->{destinationID})) {
		croak "farthestNode: destinationID attribute not set in solution hash reference parameter";
	}
	my $destinationID = $solutionHref->{destinationID};
	
	if (!exists($self->{nodes}{$originID})) {
		carp "shortestPath: originID not found: $originID";
		return 0;
	}
	
	if (!$self->_hasEdges($originID)) {
		carp "shortestPath: origin node $originID has no edges";
		return 0;
	}
	if (!exists($self->{nodes}{$destinationID})) {
		carp "shortestPath: destinationID not found: $destinationID";
		return 0;
	}
	
	my $pq = Array::Heap::ModifiablePriorityQueue->new();
	
	my %solution = ();		#initialize the solution hash
	my %unvisited = ();
	foreach my $node ($self->nodeIDsList()) {
		$solution{$node}{weight} = $PINF;
		$solution{$node}{prevnode} = $EMPTY_STRING;
		$pq->add($node, $PINF);
	}
		
	$solution{$originID}{weight} = 0;
	$pq->add($originID,0); #modify weight of origin node
	
	my $cycle = 0;
	my $t0 = Benchmark->new;
	
	my $foundSolution = 0;
	while ($pq->size()) {
		$cycle++;
		#print '.' if $VERBOSE and ($cycle % 1000 == 0);
		
		my $visitNode = $pq->get();
		
		if ($visitNode eq $destinationID) {
			$foundSolution = 1 if $solution{$visitNode}{weight} < $PINF;
			last;
		}
		next if !$self->_hasEdges($visitNode);
		
		foreach my $adjacentNode ($self->adjacentNodes($visitNode)) {
			next if !defined($pq->weight($adjacentNode));
			
			my $thisWeight = $solution{$visitNode}{weight} + $self->_getEdgeAttrib($visitNode, $adjacentNode, 'weight' );
			if ($thisWeight < $solution{$adjacentNode}{weight}) {
				$solution{$adjacentNode}{weight} = $thisWeight;
				$solution{$adjacentNode}{prevnode} = $visitNode;
				$pq->add($adjacentNode, $thisWeight);
			}
		}
	}
	if ($VERBOSE) {
		my $t1 = Benchmark->new;
		#if ($cycle >= 1000) {
		#	print "\n";
		#}
		my $td = timediff($t1, $t0);
	  print "dijkstra's algorithm took: ",timestr($td),"\n";
	}
  
  my $pathWeight = 0;
  if ($foundSolution) {
	  $pathWeight = $solution{$destinationID}{weight};
		print {$verboseOutfile} "shortestPath: originID $originID -> destinationID $destinationID pathWeight (cost) = $pathWeight\n" if $VERBOSE;
		
		my $solutioncnt = 0;
		%{$solutionHref} = (
			desc => 'path',
			originID => $originID,
			destinationID => $destinationID,
			weight => $pathWeight,
		);
		
		my $fromNode = $solution{$destinationID}{prevnode};
		my @path = ( $destinationID, $fromNode );
		
		my %loopCheck = ();
		while ($solution{$fromNode}{prevnode} ne $EMPTY_STRING) {
			$fromNode = $solution{$fromNode}{prevnode};
			if (exists($loopCheck{$fromNode})) {
				print "shortestPath: path loop at $fromNode\n";
				print "shortestPath: path = ", join(',',@path), "\n";
				die "shortestPath internal error: destination to origin path logic error";
			}
			$loopCheck{$fromNode} = 1;
			push(@path,$fromNode);
		}
		
		@path = reverse(@path);
		
		my $nexttolast = $#path - 1;
		foreach my $i (0 .. $nexttolast) {
			push(@{$solutionHref->{edges}}, {sourceID => $path[$i], targetID => $path[$i+1], weight => $self->edge( { sourceID=>$path[$i], targetID=>$path[$i+1] } )->{weight} } );
		}
	}
	return($pathWeight);
}

#############################################################################
#Floyd Warshall alternative method                                          #
#############################################################################

sub vertexCenterFloydWarshall {
	my ($self, $solutionMatrix) = @_;
	
	%$solutionMatrix = ();
	
	my @nodeList = ();
	my $nodesEdgeCount = 0;
	
	my $totalNodes = 0;
	foreach my $nodeID ( $self->nodeIDsList() ) {
		$totalNodes++;
		$nodesEdgeCount++ if $self->_hasEdges($nodeID);	
		push(@nodeList, $nodeID);
	}
	my $nodeCount = scalar(@nodeList);
	print {$verboseOutfile} "vertexCenterFloydWarshall: graph contains $totalNodes nodes, $nodesEdgeCount nodes have one or more outbound edges\n" if $VERBOSE;
	
	#should add code to limit computations at reasonable number
	
	my $t0 = Benchmark->new;
	
	foreach my $fromNodeID (@nodeList) {
		
		$solutionMatrix->{rowMax}{$fromNodeID} = $PINF;
		
		foreach my $toNodeID (@nodeList) {
			$solutionMatrix->{row}{$fromNodeID}{$toNodeID} = $PINF;
		}
		$solutionMatrix->{row}{$fromNodeID}{$fromNodeID} = 0;
	}
	
	foreach my $fromNodeID (@nodeList) {
		next if !$self->_hasEdges($fromNodeID);
		foreach my $toNodeID ($self->adjacentNodes($fromNodeID)) {
			$solutionMatrix->{row}{$fromNodeID}{$toNodeID} = $self->_getEdgeAttrib($fromNodeID, $toNodeID, 'weight');
			$solutionMatrix->{row}{$toNodeID}{$fromNodeID} = $solutionMatrix->{row}{$fromNodeID}{$toNodeID} if $self->_getEdgeAttrib($fromNodeID, $toNodeID, 'directed') eq 'undirected';
		}
	}
	foreach my $k (@nodeList) {
		next if !$self->_hasEdges($k);
		foreach my $i (@nodeList) {
			next if !$self->_hasEdges($i);
			foreach my $j (@nodeList) {
				next if $i eq $j;
				if ($solutionMatrix->{row}{$i}{$j} > ($solutionMatrix->{row}{$i}{$k} + $solutionMatrix->{row}{$k}{$j})) {
					$solutionMatrix->{row}{$i}{$j} = $solutionMatrix->{row}{$i}{$k} + $solutionMatrix->{row}{$k}{$j};
				}
			}
		}
	}

	if ($VERBOSE) {
		my $t1 = Benchmark->new;
		#if ($cycle >= 1000) {
		#	print "\n";
		#}
		my $td = timediff($t1, $t0);
	  print {$verboseOutfile} "vertexCenterFloydWarshall: computing shortest path matrix took: ",timestr($td),"\n";
	}
	my $graphMinMax = $PINF;
	my $centerNode = '';
	foreach my $origin (@nodeList) {
		my $rowMax = 0;
		foreach my $destination (@nodeList) {
			next if $origin eq $destination;
			if ($solutionMatrix->{row}{$origin}{$destination} > $rowMax) {
				$rowMax = $solutionMatrix->{row}{$origin}{$destination};
			}
		}
		$solutionMatrix->{rowMax}{$origin} = $rowMax;
		if ($rowMax < $graphMinMax) {
			$graphMinMax = $rowMax;
		}
	}
	$solutionMatrix->{centerNodeSet} = [];
	if ($graphMinMax < $PINF) {
		foreach my $origin (@nodeList) {
			if ($solutionMatrix->{rowMax}{$origin} == $graphMinMax) {
				push(@{$solutionMatrix->{centerNodeSet}}, $origin);
			}
		}
	}
	else {
		carp "vertexCenterFloydWarshall: Graph contains disconnected sub-graph / non-reachable node pairs. Center node set undefined.";
		$graphMinMax = 0;
	}
	return($graphMinMax);
	
}

#############################################################################
#input / output file methods                                                #
#############################################################################

{ #CSV file format methods

	use Text::CSV_XS;
	
	sub getRowHref {
		my $row = shift;
		my $attribStr = $EMPTY_STRING;
		foreach my $i (1 .. $#$row) {
			$attribStr .= ', ' if $attribStr;
			$attribStr .= $row->[$i];
		}
		return Graph::Dijkstra->hashifyAttribs( "($attribStr)" );
	}
	
	sub inputGraphfromCSV {
		my ($self, $filename) = @_;
		
		if (!ref($self)) {
			$self = Graph::Dijkstra->new();
		}
		
		my $nodecount = 0;
		my $edgecount = 0;
		
		open(my $infile, '<:encoding(UTF-8)', $filename) or croak "could not open '$filename'";
		
		print {$verboseOutfile} "inputGraphfromCSV: opened '$filename' for input\n" if $VERBOSE;
	
		my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
		while (my $row = $csv->getline ($infile)) {
			if (lc($row->[0]) eq 'graph') {
				$self->graph( getRowHref( $row ) ) if $#$row;
			}
			elsif (lc($row->[0]) eq 'node') {
				$self->node( getRowHref( $row ) );
				$nodecount++;
			}
			elsif (lc($row->[0]) eq 'edge') {
				$self->edge( getRowHref( $row ) );
				$edgecount++;
			}
		}
		close($infile);
		
		carp "inputGraphfromCSV: no nodes read from '$filename'" if !$nodecount;
		carp "inputGraphfromCSV: no edges read from '$filename'" if !$edgecount;
		
		print {$verboseOutfile} "inputGraphfromCSV: found $nodecount nodes and $edgecount edges\n" if $VERBOSE;
		return $self;
	}
	
	sub makeRow {
		my $href = shift;
		my @rowdata = ();
		foreach my $attrib (sort keys %$href) {
			next if $href->{$attrib} eq $EMPTY_STRING;
			my $printVal = (looks_like_number($href->{$attrib})) ? $href->{$attrib} : "'$href->{$attrib}'";
			push(@rowdata, "$attrib=>$printVal");
		}
		return @rowdata;
	}
	
	sub outputGraphtoCSV {
		my ($self, $filename) = @_;
		
		open(my $outfile, '>:encoding(UTF-8)', $filename) or croak "could not open '$filename'";
		
		print {$verboseOutfile} "outputGraphtoCSV: opened '$filename' for output\n" if $VERBOSE;
		
		my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
		
		my $nodecount = 0;
		my $edgecount = 0;
		my $graphHref = $self->graph();
		
		$csv->say( $outfile, ['comment', 'generated by Graph::Dijkstra on ' . localtime] );
		$csv->say( $outfile, ['graph', makeRow( $self->graph() ) ] );
		
		my $graphDirected = $self->{edgedefault};
		
		my %edges = ();
		foreach my $nodeID ($self->nodeIDsList()) {
			
			$csv->say($outfile, ['node', makeRow( $self->node($nodeID) ) ]);
			
			$nodecount++;
#			if ($self->_hasEdges($nodeID)) {
				foreach my $targetID ($self->adjacentNodes($nodeID)) {
					my $edgeDirected = $self->_getEdgeAttrib($nodeID, $targetID, 'directed');
					if ( ($edgeDirected eq 'undirected' and !exists($edges{$targetID}{$nodeID})) or $edgeDirected eq 'directed') {
						$edges{$nodeID}{$targetID}{weight} = $self->_getEdgeAttrib($nodeID, $targetID, 'weight');
					}
				}
#			}
		}
		foreach my $sourceID (keys %edges) {
			foreach my $targetID (keys %{$edges{$sourceID}}) {
				
				$csv->say($outfile, ['edge', makeRow( $self->edge( {sourceID=>$sourceID, targetID=>$targetID} ) ) ]);
			
				$edgecount++;
			}
		}
		close($outfile);
		print {$verboseOutfile} "outputGraphtoCSV: wrote $nodecount nodes and $edgecount edges to '$filename'\n" if $VERBOSE;
		
		return $self;
	}
	
	sub outputAPSPmatrixtoCSV {
		my ($either, $solutionMatrix, $filename, $labelSort) = @_;
		
		$labelSort = '' if !defined($labelSort);
		
		open(my $outfile, '>:encoding(UTF-8)', $filename) or croak "could not open '$filename'";
		
		print {$verboseOutfile} "outputAPSPmatrixtoCSV: opened '$filename' for output\n" if $VERBOSE;
		
		my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
		
		my @nodeList = (lc($labelSort) eq 'numeric') ? (sort {$a <=> $b} keys %{$solutionMatrix->{row}}) : (sort keys %{$solutionMatrix->{row}});
		
		$csv->say($outfile, ['From/To', @nodeList ]);
		my $rowcount = 1;
		
		foreach my $nodeID (@nodeList) {
			my @row = ();
			foreach my $destinationID (@nodeList) {
				push(@row, $solutionMatrix->{row}{$nodeID}{$destinationID});
			}
			$csv->say($outfile, [$nodeID, @row]);
			$rowcount++;
		}
		close($outfile);
		print  {$verboseOutfile} "outputAPSPmatrixtoCSV: wrote $rowcount rows to '$filename'\n" if $VERBOSE;
		return $either;
		
	}
	
} #CSV file format I/O methods

#############################################################################
#JSON Graph Specification file format methods                               #
#############################################################################
{ 
		
	use JSON;

	sub inputGraphfromJSON {
		my ($self, $filename, $options) = @_;
		
		if (!ref($self)) {
			$self = Graph::Dijkstra->new();
		}
		
		my $json_text = $EMPTY_STRING;
		open(my $infile, '<:encoding(UTF-8)', $filename) or croak "could not open '$filename'";
		
		print  {$verboseOutfile} "inputGraphfromJSON: opened '$filename' for input\n" if $VERBOSE;
		
		while (my $line = <$infile>) {
			$json_text .= $line;
		}
		close($infile);
	
		my $graphHref = from_json( $json_text, {utf8 => 1} ) or croak "inputGraphfromJSON: invalid json text";
		
		if (ref($graphHref) ne 'HASH') {
			croak "inputGraphfromJSON: invalid JSON text";
		}
		
		if (exists($graphHref->{graphs})) {
			croak "inputGraphfromJSON: JSON \"multi graph\" type not supported";
		}
		if (!exists($graphHref->{graph}{edges})) {
			croak "inputGraphfromJSON: not a JSON graph specification or graph has no edges";
		}
		my $edgeWeightKey = (defined($options) and ref($options) eq 'HASH' and exists($options->{edgeWeightKey})) ? $options->{edgeWeightKey} : 'value';
		
		my $graphDirected = 'undirected';
		if (exists($graphHref->{graph}{directed}) and $graphHref->{graph}{directed} ) {
			$graphDirected = 'directed';
		}
		print  {$verboseOutfile} "inputGraphfromJSON: graph edge default is '$graphDirected'.\n" if $VERBOSE;
		
		$self->graph( {label=>$graphHref->{graph}{label} } ) if exists($graphHref->{graph}{label});
		$self->graph( {creator=>$graphHref->{graph}{metadata}{creator} } ) if exists($graphHref->{graph}{metadata}{creator});
		
		my $nodecount = 0;
		my $edgecount = 0;
		my $dupedgecount = 0;
		
		foreach my $nodeHref (@{$graphHref->{graph}{nodes}}) {
			$nodecount++;
			$self->node( {id=>$nodeHref->{id}, label=>$nodeHref->{label} } );
		}
		foreach my $edgeHref (@{$graphHref->{graph}{edges}}) {
			
			my $edgeDirected = $graphDirected;
			if (exists($edgeHref->{directed})) {
				$edgeDirected = ($edgeHref->{directed}) ? 'directed' : 'undirected';
			}
			my $edgeLabel = $edgeHref->{label} || $EMPTY_STRING;
			my $edgeID = $edgeHref->{metadata}{id} || $EMPTY_STRING;
			my $weight = $edgeHref->{metadata}{$edgeWeightKey} || 1;
			
			$edgecount++;
			$dupedgecount++ if $self->edgeExists( { sourceID=>$edgeHref->{source}, targetID=>$edgeHref->{target} } );
			$self->edge( { sourceID=>$edgeHref->{source}, targetID=>$edgeHref->{target}, weight=>$weight, label=>$edgeLabel, directed=>$edgeDirected, id=>$edgeID } );
		}
		
		carp "inputGraphfromJSON: no nodes read from '$filename'" if !$nodecount;
		carp "inputGraphfromJSON: no edges read from '$filename'" if !$edgecount;
		
		print  {$verboseOutfile} "inputGraphfromJSON: found $nodecount nodes and $edgecount edges\n" if $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromJSON: found $dupedgecount duplicate edges\n" if $dupedgecount and $VERBOSE;
		
		return $self;
	}
	
	
	sub outputGraphtoJSON {
		my ($self, $filename, $options) = @_;
		
		my $nodecount = 0;
		my $edgecount = 0;
		
		my %graph = ();
		my $graphDirected = $self->{edgedefault};
		
		$graph{graph}{directed} = ($graphDirected eq 'directed') ? JSON::true : JSON::false;
		@{$graph{graph}{nodes}} = ();
		@{$graph{graph}{edges}} = ();
		
		$graph{graph}{metadata}{comment} = 'generated by Graph::Dijkstra on ' . localtime;
		$graph{graph}{label} = $self->{label} if $self->{label};
		$graph{graph}{metadata}{creator} = $self->{creator} if $self->{creator};

		my $edgeWeightKey = (defined($options) and ref($options) eq 'HASH' and exists($options->{edgeWeightKey})) ? $options->{edgeWeightKey} : 'value';
		
		my %edges = ();
		foreach my $nodeID ($self->nodeIDsList()) {
			
			push(@{$graph{graph}{nodes}}, { id => $nodeID, label => $self->{nodes}{$nodeID}{label} } );
			
			$nodecount++;
#			if ($self->_hasEdges($nodeID)) {
				foreach my $targetID ($self->adjacentNodes($nodeID)) {
					
					my $edgeDirected = $self->_getEdgeAttrib($nodeID, $targetID, 'directed');
					if ( ($edgeDirected eq 'undirected' and !exists($edges{$targetID}{$nodeID})) or $edgeDirected eq 'directed') {
					
						$edges{$nodeID}{$targetID} = 1;
						my %edgeData = ( source => $nodeID, target => $targetID, metadata => {$edgeWeightKey => $self->_getEdgeAttrib($nodeID, $targetID, 'weight') } );
						
						$edgeData{label} = $self->{edges}{$nodeID}{$targetID}{label} if $self->{edges}{$nodeID}{$targetID}{label};
						
						if ($edgeDirected ne $graphDirected) {
							$edgeData{directed} = ($edgeDirected eq 'directed') ? JSON::true : JSON::false;
						}
						
						push( @{$graph{graph}{edges}}, \%edgeData );
						$edgecount++;
					}
				}
#			}
		}
		
		my $json_text = to_json(\%graph, {utf8 => 1, pretty => 1});
		
		open(my $outfile, '>:encoding(UTF-8)', $filename) or croak "could not open '$filename'";
		
		print  {$verboseOutfile} "outputGraphtoJSON: opened '$filename' for output\n" if $VERBOSE;
		print {$outfile} $json_text;
		close($outfile);
		print  {$verboseOutfile} "outputGraphtoJSON: wrote $nodecount nodes and $edgecount edges to '$filename'\n" if $VERBOSE;
		
		return $self;
	}
	
} #JSON Graph Specification file format methods

#############################################################################
#GML file format methods                                                    #
#############################################################################
{  
	
	use Regexp::Common;

	sub inputGraphfromGML { ## no critic (ProhibitExcessComplexity)
		my ($self, $filename) = @_;
		
		if (!ref($self)) {
			$self = Graph::Dijkstra->new();
		}
		my $buffer = $EMPTY_STRING;
		my $linecount = 0;
		open(my $infile, '<:encoding(UTF-8)', $filename) or croak "could not open '$filename'";
		
		print  {$verboseOutfile} "inputGraphfromGML: opened '$filename' for input\n" if $VERBOSE;
		
		while (my $line = <$infile>) {
			next if substr($line,0,1) eq '#';
			$buffer .= $line;
			$linecount++;
		}
		close($infile);
		print  {$verboseOutfile} "inputGraphfromGML: read $linecount lines\n" if $VERBOSE;
		
		if ($buffer !~ /graph\s+\[.+?(?:node|edge)\s+\[/ixs) {
			croak "file does not appear to be GML format";
		}
		
		my $graphDirected = 'undirected';
		
		if ($buffer =~ /graph\s+\[\s+directed\s+(\d)/ixs) {
			$graphDirected = ($1) ? 'directed' : 'undirected';
		}
		
		print  {$verboseOutfile} "inputGraphfromGML: graph edge default = '$graphDirected'\n" if $VERBOSE;
		$self->graph( { edgedefault=>$graphDirected } );
		
		if ($buffer =~ /^\s*creator\s+\"([^\"]+)\"/i) {
			my $creator = $1;
			$self->graph( {creator=>$creator} );
			print  {$verboseOutfile} "inputGraphfromGML: graph attribute creator set: $creator\n" if $VERBOSE;
			
		}
		
		my $has_graphics_elements = ($buffer =~ /graphics\s+\[/) ? 1 : 0;
		print  {$verboseOutfile} "GML file contain graphics elements\n" if ($VERBOSE and $has_graphics_elements);
		
		my $balancedRE = $RE{balanced}{-parens=>'[]'};
		
		
		my $nodecount = 0;
		my $edgecount = 0;
		my $dupedgecount = 0;
		
		while ($buffer =~ /(node|edge)\s+$balancedRE/gixso) {
			my $type = lc($1);
			my $attribs = $2;
			#my $bufferPos = $-[0];
			
			$attribs = substr($attribs, 1, -1);
		
			$attribs =~ s/graphics\s+$balancedRE//xio if $has_graphics_elements and $type eq 'node';
			
			my %keyvals = ();	
			while ($attribs =~/(id|label|source|target|value)\s+(?|([0-9\.]+)|\"([^\"]+)\")/gixs) {
				my $attrib = lc($1);
				my $attribValue = $2;
				if ($type eq 'edge' and $attrib eq 'value' and !looks_like_number($attribValue)) {
					carp "non-numeric edge value '$attribValue'.  Skipped.";
					next;
				}
				$keyvals{$attrib} = $attribValue;
			}
	
			if ($type eq 'node') {
				$nodecount++;
				if (exists($keyvals{id})) {
					$self->{nodes}{$keyvals{id}}{label} = $keyvals{label} || $EMPTY_STRING;
				}
				else {
					croak "inputGraphfromGML: node: missing id problem -- matched attribs: '$attribs'";
				}
			}
			else {
				$edgecount++;
				my $edgeLabel = $keyvals{label} || $EMPTY_STRING;
				if (exists($keyvals{source}) and exists($keyvals{target}) and exists($keyvals{value}) and $keyvals{value} > 0) {
					$dupedgecount++ if $self->edgeExists( { sourceID=>$keyvals{source}, targetID=>$keyvals{target} } );
					$self->edge( { sourceID=>$keyvals{source}, targetID=>$keyvals{target}, weight=>$keyvals{value}, label=>$edgeLabel, directed=>$graphDirected } );
				}
				else {
					croak "inputGraphfromGML: edge: missing source, target, value, or value <= 0 problem -- matched attribs '$attribs'";
				}
			}
		}
	
		carp "inputGraphfromGML: no nodes read from '$filename'" if !$nodecount;
		carp "inputGraphfromGML: no edges read from '$filename'" if !$edgecount;
		
		print  {$verboseOutfile} "inputGraphfromGML: found $nodecount nodes and $edgecount edges\n" if $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromGML: found $dupedgecount duplicate edges\n" if $dupedgecount and $VERBOSE;
		
		return $self;
	}


	sub outputGraphtoGML {
		my ($self, $filename) = @_;
		
		open(my $outfile, '>:encoding(UTF-8)', $filename) or croak "could not open '$filename' for output";
		
		print  {$verboseOutfile} "outputGraphtoGML: opened '$filename' for output\n" if $VERBOSE;
		
		print {$outfile} "Creator \"$self->{creator}\"\n" if $self->{creator};
		my $graphDirected = ($self->{edgedefault} eq 'directed') ? 1 : 0;
		my $comment = '"Generated by Graph::Dijkstra on ' . localtime . '"';
		print {$outfile} "Graph [\nComment $comment\n\tDirected ", (($self->{edgedefault} eq 'directed') ? 1 : 0), "\n";
		$graphDirected = $self->{edgedefault};
		
		my $nodecount = 0;
		my $edgecount = 0;
		
		my %edges = ();
		foreach my $nodeID ($self->nodeIDsList()) {
			my $nodeIDprint = (looks_like_number($nodeID)) ? $nodeID : '"' . encode_entities($nodeID) . '"';
			my $nodeLabel = encode_entities($self->{nodes}{$nodeID}{label});
			print {$outfile} "\tnode [\n\t\tid $nodeIDprint\n\t\tlabel \"$nodeLabel\"\n\t]\n";
			$nodecount++;
#			if ($self->_hasEdges($nodeID)) {
				foreach my $targetID ($self->adjacentNodes($nodeID)) {
					croak "outputGraphtoGML: internal graph includes both directed and undirected edges. Not supported by GML format." if $self->_getEdgeAttrib($nodeID, $targetID, 'directed') ne $graphDirected;
					if ( ($graphDirected eq 'undirected' and !exists($edges{$targetID}{$nodeID})) or $graphDirected eq 'directed') {
						$edges{$nodeID}{$targetID}{weight} = $self->_getEdgeAttrib($nodeID, $targetID, 'weight');
						$edges{$nodeID}{$targetID}{label} = $self->_getEdgeAttrib($nodeID, $targetID, 'label');
					}
				}
#			}
		}
		foreach my $sourceID (keys %edges) {
			foreach my $targetID (keys %{$edges{$sourceID}}) {
				my $sourceIDprint = (looks_like_number($sourceID)) ? $sourceID : '"' . encode_entities($sourceID) . '"';
				my $targetIDprint = (looks_like_number($targetID)) ? $targetID : '"' . encode_entities($targetID) . '"';
				my $edgeLabelprint = ($edges{$sourceID}{$targetID}{label}) ? "\t\tlabel \"" . encode_entities($edges{$sourceID}{$targetID}{label}) . "\"\n" : $EMPTY_STRING;
				print {$outfile} "\tedge [\n\t\tsource $sourceIDprint\n\t\ttarget $targetIDprint\n$edgeLabelprint\t\tvalue $edges{$sourceID}{$targetID}{weight}\n\t]\n";
				$edgecount++;
			}
		}
		print {$outfile} "]\n";
		close($outfile);
		print  {$verboseOutfile} "outputGraphtoGML: wrote $nodecount nodes and $edgecount edges to '$filename'\n" if $VERBOSE;
		
		return $self;
	}

} #GML file format methods

#############################################################################
#XML file format methods: GraphML and GEXF                                  #
#############################################################################
{  
	
	use XML::LibXML;
		
	
	sub inputGraphfromGraphML { ## no critic (ProhibitExcessComplexity)
		my ($self, $filename, $options) = @_;
		
		if (!ref($self)) {
			$self = Graph::Dijkstra->new();
		}
		
		my $dom = XML::LibXML->load_xml(location => $filename);
		
		print  {$verboseOutfile} "inputGraphfromGraphML: input '$filename'\n" if $VERBOSE;
		
		my $topNode = $dom->nonBlankChildNodes()->[0];
		
		croak "inputGraphfromGraphML: not a GraphML format XML file" if lc($topNode->nodeName()) ne 'graphml';
		
		my $nsURI = $topNode->getAttribute('xmlns') || '';
		
		croak "inputGraphfromGraphML: not a GraphML format XML file" if (lc($nsURI) ne 'http://graphml.graphdrawing.org/xmlns');
		
		my $xpc = XML::LibXML::XPathContext->new($dom);
		$xpc->registerNs('gml', $nsURI);
		
		my $labelKey = $options->{nodeKeyLabelID} || $EMPTY_STRING;
		my $weightKey = $options->{edgeKeyValueID} || $EMPTY_STRING;
		my $edgeLabelKey = 'label';
		
		my $defaultWeight = 1;
		
		my $nodecount = 0;
		my $dupnodecount = 0;
		my $edgecount = 0;
		my $badedgecount = 0;
		my $dupedgecount = 0;
		my $graphDirected = $EMPTY_STRING;
		
		if (my $graphNode = $xpc->findnodes('/gml:graphml/gml:graph')->[0] ) {
			$graphDirected = lc($graphNode->getAttribute('edgedefault'));
			print  {$verboseOutfile} "inputGraphfromGraphML: graph edge default is '$graphDirected'.\n" if $VERBOSE;
		}
		else {
			croak "inputGraphfromGraphML: GraphML file has no <graph> element";
		}
		
		if (my $graphNode = $xpc->findnodes('/gml:graphml/gml:graph[2]')->[0] ) {
			croak "inputGraphfromGraphML: file contains more than one graph.  Not supported.";
		}
		
		if (my $graphNode = $xpc->findnodes('/gml:graphml/gml:graph/gml:node/gml:graph')->[0] ) {
			croak "inputGraphfromGraphML: file contains one or more embedded graphs.  Not supported.";
		}
		
		if ($weightKey) {
			if (my $keyWeightNode = $xpc->findnodes("/gml:graphml/gml:key[\@for=\"edge\" and \@id=\"$weightKey\"]")->[0]) {
				print  {$verboseOutfile} "inputGraphfromGraphML: found edgeKeyValueID '$weightKey' in GraphML key elements list\n" if $VERBOSE;
				if (my $defaultNode = $xpc->findnodes('.//gml:default[1]',$keyWeightNode)->[0]) {
					$defaultWeight = $defaultNode->textContent();
				}
			}
			else {
				carp "inputGraphfromGraphML: edgeKeyValueID '$weightKey' not found in GraphML key elements list";
				$weightKey = $EMPTY_STRING;
			}
		}
		
		if (!$weightKey) {
			foreach my $keyEdge ($xpc->findnodes('/gml:graphml/gml:key[@for="edge"]') ) {
				my $attrName = $keyEdge->getAttribute('attr.name');
				if ($IS_GRAPHML_WEIGHT_ATTR{ lc($attrName) } ) {
					$weightKey = $keyEdge->getAttribute('id');
					print  {$verboseOutfile} "inputGraphfromGraphML: found key attribute for edge attr.name='$attrName' id='$weightKey'\n" if $VERBOSE;
					if (my $defaultNode = $xpc->findnodes('.//gml:default[1]',$keyEdge)->[0]) {
						$defaultWeight = $defaultNode->textContent();
					}
					last;
				}
			}
			
			if (!$weightKey) {
				croak "inputGraphfromGraphML: graph does not contain key attribute for edge weight/value/cost/distance '<key id=\"somevalue\" for=\"edge\" attr.name=\"weight|value|cost|distance\" />'.  Not supported.";
			}
		}
		
		if ($edgeLabelKey) {
			if (my $keyEdgeLabelNode = $xpc->findnodes("/gml:graphml/gml:key[\@for=\"edge\" and \@id=\"$edgeLabelKey\"]")->[0]) {
				print  {$verboseOutfile} "inputGraphfromGraphML: found edgeKeyLabelID '$edgeLabelKey' in GraphML key elements list\n" if $VERBOSE;
			}
			else {
#				carp "inputGraphfromGraphML: edgeKeyLabelID '$edgeLabelKey' not found in GraphML key elements list";
				$edgeLabelKey = $EMPTY_STRING;
			}
		}
		my $edgeLabelXPATH = ($edgeLabelKey) ? ".//gml:data[\@key=\"$edgeLabelKey\"]" : $EMPTY_STRING;
		
		my $labelXPATH = $EMPTY_STRING;
		
		if ($labelKey) {
			if (my $keyNodeLabelNode = $xpc->findnodes("/gml:graphml/gml:key[\@for=\"node\" and \@id=\"$labelKey\"]")->[0]) {
				print  {$verboseOutfile} "inputGraphfromGraphML: found nodeKeyLabelID '$labelKey' in GraphML key elements list\n" if $VERBOSE;
			}
			else {
				carp "inputGraphfromGraphML: nodeLabelValueID '$labelKey' not found in GraphML key elements list";
				$labelKey = $EMPTY_STRING;
			}
		}
		
		if (!$labelKey) {
			foreach my $keyNode ($xpc->findnodes('/gml:graphml/gml:key[@for="node" and @attr.type="string"]')) {
				my $attrName = $keyNode->getAttribute('attr.name') || $EMPTY_STRING;
				if ($IS_GRAPHML_LABEL_ATTR{lc($attrName)}) {
					$labelKey = $keyNode->getAttribute('id');
					print  {$verboseOutfile} "inputGraphfromGraphML: found key attribute for node 'label' attr.name='$attrName' id='$labelKey'\n" if $VERBOSE;
					last;
				}
			}
		}
		
		if (!$labelKey) {
			carp "inputGraphfromGraphML: key node name / label / description attribute not found in graphml";
		}
		else {
			$labelXPATH = ".//gml:data[\@key=\"$labelKey\"]";
		}
		
		if (my $keyGraphCreator = $xpc->findnodes("/gml:graphml/gml:key[\@for=\"graph\" and \@id=\"creator\"]")->[0]) {
			if (my $dataGraphCreator = $xpc->findnodes("/gml:graphml/gml:graph/gml:data[\@key=\"creator\"]")->[0]) {
				if (my $creator = $dataGraphCreator->textContent()) {
					$self->graph( {creator=>$creator} );
				}
			}
		}
		if (my $keyGraphLabel = $xpc->findnodes("/gml:graphml/gml:key[\@for=\"graph\" and \@id=\"graphlabel\"]")->[0]) {
			if (my $dataGraphLabel = $xpc->findnodes("/gml:graphml/gml:graph/gml:data[\@key=\"graphlabel\"]")->[0]) {
				if (my $label = $dataGraphLabel->textContent()) {
					$self->graph( {label=>$label} );
				}
			}
		}
			
		foreach my $nodeElement ($xpc->findnodes('/gml:graphml/gml:graph/gml:node')) {
			
			my $node = $nodeElement->nodeName();
			my $id = $nodeElement->getAttribute('id');
			my $label = $EMPTY_STRING;
			if ($labelXPATH and my $dataNameNode = $xpc->findnodes($labelXPATH,$nodeElement)->[0]) {
				$label = $dataNameNode->textContent();
			}
			$dupnodecount++ if $self->nodeExists($id);
			$self->node( {id=>$id,label=>$label } );
			$nodecount++;
		}
		
		my $weightXPATH = ".//gml:data[\@key=\"$weightKey\"]";
		
		foreach my $edgeElement ($xpc->findnodes('/gml:graphml/gml:graph/gml:edge')) {
			
			my $edge = $edgeElement->nodeName();
			my $source = $edgeElement->getAttribute('source');
			my $target = $edgeElement->getAttribute('target');
			my $edgeID = ($edgeElement->hasAttribute('id')) ? $edgeElement->getAttribute('id') : $EMPTY_STRING;
			my $edgeDirected = ($edgeElement->hasAttribute('directed')) ? $edgeElement->getAttribute('directed') : $graphDirected;
			my $edgeLabel = '';
			if ($edgeLabelXPATH and my $dataEdgeLabelNode = $xpc->findnodes($edgeLabelXPATH,$edgeElement)->[0]) {
				$edgeLabel = $dataEdgeLabelNode->textContent();
			}
			my $weight = $defaultWeight;
			if (my $dataWeightNode = $xpc->findnodes($weightXPATH,$edgeElement)->[0]) {
				$weight = $dataWeightNode->textContent();
			}
			if ($weight) {
				$dupedgecount++ if $self->edgeExists( { sourceID=>$source, targetID=>$target } );
				my %edgeAttribs = (sourceID=>$source, targetID=>$target, weight=>$weight, directed=>$edgeDirected);
				$edgeAttribs{id} = $edgeID if $edgeID;
				$edgeAttribs{label} = $edgeLabel if $edgeLabel;
				
				if (defined($self->edge( \%edgeAttribs ) )) {
					$edgecount++;
				}
				else {
					$badedgecount++;
				}
			}
			else {
				carp "inputGraphfromGraphML: edge $source $target has no weight. Not created."
			}
		
		}
		
		carp "inputGraphfromGraphML: no nodes read from '$filename'" if !$nodecount;
		carp "inputGraphfromGraphML: no edges read from '$filename'" if !$edgecount;
		
		print  {$verboseOutfile} "inputGraphfromGraphML: found $nodecount nodes and $edgecount edges\n" if $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromGraphML: found $dupnodecount duplicate nodes\n" if $dupnodecount and $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromGraphML: found $dupedgecount duplicate edges\n" if $dupedgecount and $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromGraphML: $badedgecount edges rejected (bad)\n" if $badedgecount and $VERBOSE;
		
		return $self;
	}
	
	
	sub outputGraphtoGraphML {
		my ($self, $filename, $options) = @_;
		
		my $nsURI = "http://graphml.graphdrawing.org/xmlns";
		
		my $doc = XML::LibXML::Document->new('1.0','UTF-8');
		my $graphML = $doc->createElementNS( $EMPTY_STRING, 'graphml' );
		$doc->setDocumentElement( $graphML );
	 
		$graphML->setNamespace( $nsURI , $EMPTY_STRING, 1 );
		
		{
			my $now_string = localtime;
			$graphML->appendChild($doc->createComment("Generated by Graph::Dijkstra on $now_string"));
		}
		
		$graphML->setAttribute('xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
		$graphML->setAttribute('xsi:schemaLocation','http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd');
		
		
		
		my $keyEdgeWeightID = $options->{keyEdgeWeightID} || 'weight';
		my $keyEdgeWeightAttrName = $options->{keyEdgeWeightAttrName} || 'weight';
		my $keyNodeLabelID = $options->{keyNodeLabelID} || 'name';
		my $keyNodeLabelAttrName = $options->{keyNodeLabelAttrName} || 'name';
		my $keyEdgeLabelID = $options->{keyEdgeLabelID} || 'label';
		my $keyEdgeLabelAttrName = $options->{keyEdgeLabelAttrName} || 'label';
		
		my $keyNode = $graphML->addNewChild( $nsURI, 'key' );
		
		$keyNode->setAttribute('for','node');
		$keyNode->setAttribute('id', $keyNodeLabelID );
		$keyNode->setAttribute('attr.name', $keyNodeLabelAttrName );
		$keyNode->setAttribute('attr.type', 'string' );
		
		my $keyEdge = $graphML->addNewChild( $nsURI, 'key' );
		$keyEdge->setAttribute('for','edge');
		$keyEdge->setAttribute('id', $keyEdgeWeightID );
		$keyEdge->setAttribute('attr.name', $keyEdgeWeightAttrName );
		$keyEdge->setAttribute('attr.type', 'double' );
		
		$keyEdge = $graphML->addNewChild( $nsURI, 'key' );
		$keyEdge->setAttribute('for','edge');
		$keyEdge->setAttribute('id', $keyEdgeLabelID );
		$keyEdge->setAttribute('attr.name', $keyEdgeLabelAttrName );
		$keyEdge->setAttribute('attr.type', 'string' );
		
		if ($self->{creator}) {
			my $keyGraph = $graphML->addNewChild( $nsURI, 'key' );
			$keyGraph->setAttribute('for','graph');
			$keyGraph->setAttribute('id','creator');
			$keyGraph->setAttribute('attr.name','creator');
			$keyGraph->setAttribute('attr.type','string');
		}
		if ($self->{label}) {
			my $keyGraph = $graphML->addNewChild( $nsURI, 'key' );
			$keyGraph->setAttribute('for','graph');
			$keyGraph->setAttribute('id','graphlabel');
			$keyGraph->setAttribute('attr.name','label');
			$keyGraph->setAttribute('attr.type','string');
		}
		
		my $graph = $graphML->addNewChild( $nsURI, 'graph' );
		$graph->setAttribute('id','G');
		$graph->setAttribute('edgedefault', $self->{edgedefault} );
		if ($self->{creator}) {
			my $dataNode = $graph->addNewChild( $nsURI, 'data');
			$dataNode->setAttribute('key', 'creator');
			$dataNode->appendTextNode( $self->{creator} );
		}
		if ($self->{label}) {
			my $dataNode = $graph->addNewChild( $nsURI, 'data');
			$dataNode->setAttribute('key', 'label');
			$dataNode->appendTextNode( $self->{label} );
		}
		
		my $nodecount = 0;
		my $edgecount = 0;
		
		my %edges = ();
		foreach my $nodeID ($self->nodeIDsList()) {
			
			my $nodeNode = $graph->addNewChild( $nsURI, 'node' );
			$nodeNode->setAttribute('id', $nodeID);
			my $dataNode = $nodeNode->addNewChild( $nsURI, 'data');
			$dataNode->setAttribute('key', $keyNodeLabelID);
			$dataNode->appendTextNode( $self->{nodes}{$nodeID}{label} );
			
			$nodecount++;
#			if ($self->_hasEdges($nodeID)) {
				foreach my $targetID ($self->adjacentNodes($nodeID)) {
					my $directed = $self->_getEdgeAttrib($nodeID, $targetID, 'directed');
					if ( ($directed eq 'undirected' and !exists($edges{$targetID}{$nodeID})) or $directed eq 'directed') {
						$edges{$nodeID}{$targetID}{weight} = $self->_getEdgeAttrib($nodeID, $targetID, 'weight');
						$edges{$nodeID}{$targetID}{id} = $self->_getEdgeAttrib($nodeID, $targetID, 'id');
						$edges{$nodeID}{$targetID}{directed} = $directed;
						$edges{$nodeID}{$targetID}{label} = $self->_getEdgeAttrib($nodeID, $targetID, 'label');
					}
				}
#			}
		}
		foreach my $sourceID (keys %edges) {
			foreach my $targetID (keys %{$edges{$sourceID}}) {
				
				$edgecount++;
				my $edgeNode = $graph->addNewChild( $nsURI, 'edge');
				$edgeNode->setAttribute('id', ($edges{$sourceID}{$targetID}{id} ne $EMPTY_STRING) ? $edges{$sourceID}{$targetID}{id} : $edgecount);
				$edgeNode->setAttribute('source', $sourceID );
				$edgeNode->setAttribute('target', $targetID );
				$edgeNode->setAttribute('directed', $edges{$sourceID}{$targetID}{directed} ) if $edges{$sourceID}{$targetID}{directed} ne $self->{edgedefault};
				my $dataNode = $edgeNode->addNewChild( $nsURI, 'data');
				$dataNode->setAttribute('key', $keyEdgeWeightID );
				$dataNode->appendTextNode( $edges{$sourceID}{$targetID}{weight} );
				
				if ( $edges{$sourceID}{$targetID}{label} ) {
					$dataNode = $edgeNode->addNewChild( $nsURI, 'data');
					$dataNode->setAttribute('key', $keyEdgeLabelID );
					$dataNode->appendTextNode( $edges{$sourceID}{$targetID}{label} );
				}
			}
		}
		
		my $state = $doc->toFile($filename,2);
		croak "could not output internal grap to '$filename'" if !$state;
		
		print  {$verboseOutfile} "outputGraphtoGraphML: wrote $nodecount nodes and $edgecount edges to '$filename'\n" if $VERBOSE;
		return $self;
	}
	
	
	sub inputGraphfromGEXF { ## no critic (ProhibitExcessComplexity)
		my ($self, $filename) = @_;
		
		if (!ref($self)) {
			$self = Graph::Dijkstra->new();
		}
		
		my $dom = XML::LibXML->load_xml(location => $filename);
		
		print  {$verboseOutfile} "inputGraphfromGEXF: input '$filename'\n" if $VERBOSE;
		
		my $topNode = $dom->nonBlankChildNodes()->[0];
		
		croak "inputGraphfromGEXF: not a GEXF format XML file" if lc($topNode->nodeName()) ne 'gexf';
		
		my $nsURI = $topNode->getAttribute('xmlns') || '';
		
		croak "inputGraphfromGEXF: not a GEXF draft specification 1.1 or 1.2 format XML file" if ( $nsURI !~ /^http:\/\/www.gexf.net\/1\.[1-2]draft$/i );
		
		my $gexfVersion = $topNode->getAttribute('version') || '';  #don't do anything with the GEXF version string
		
		my $xpc = XML::LibXML::XPathContext->new($dom);
		$xpc->registerNs('gexf', $nsURI);
						
		my $nodecount = 0;
		my $edgecount = 0;
		my $dupedgecount = 0;
		my $defaultWeight = 1;
		my $graphDirected = 'undirected';
		my $attvalueWeightCount = 0;
		my $weightXPATH = ".//gexf:attvalues/gexf:attvalue[\@for=\"weight\"]";
		
		if (my $graphNode = $xpc->findnodes('/gexf:gexf/gexf:graph')->[0] ) {
			$graphDirected = ($graphNode->hasAttribute('defaultedgetype')) ? lc($graphNode->getAttribute('defaultedgetype')) : 'undirected';
			croak "inputGraphfromGEXF: graph defaultedgetype is 'mutual'. Not supported." if $graphDirected eq 'mutual';
			$self->graph( {edgedefault=>$graphDirected} );
			print  {$verboseOutfile} "inputGraphfromGEXF: graph edgedefault is '$graphDirected'.\n" if $VERBOSE;
			my $mode = $graphNode->getAttribute('mode') || $EMPTY_STRING;
			carp "inputGraphfromGEXF: graph mode is 'dynamic'.  Ignored." if lc($mode) eq 'dynamic';
		}
		else {
			croak "inputGraphfromGEXF: GEXF file has no <graph> element";
		}
		
		if (my $graphNode = $xpc->findnodes('/gexf:gexf/gexf:graph[2]')->[0] ) {
			croak "inputGraphfromGEXF: file contains more than one graph.  Not supported.";
		}
		
		if (my $heirarchyNode = $xpc->findnodes('/gexf:gexf/gexf:graph/gexf:nodes/gexf:node/gexf:nodes')->[0] ) {
			croak "inputGraphfromGEXF: file contains heirarchical nodes.  Not supported.";
		}
		if (my $parentsNode = $xpc->findnodes('/gexf:gexf/gexf:graph/gexf:nodes/gexf:node/gexf:parents')->[0] ) {
			croak "inputGraphfromGEXF: file contains parent nodes.  Not supported.";
		}
		
		if (my $metaNode = $xpc->findnodes('/gexf:gexf/gexf:meta/gexf:creator')->[0] ) {
			if (my $creator = $metaNode->textContent()) {
				$self->graph( { creator=>$creator } );
				print  {$verboseOutfile} "inputGraphfromGEXF: set graph attribute creator: $creator\n" if $VERBOSE;
			}
		}
		
		if (my $metaNode = $xpc->findnodes('/gexf:gexf/gexf:meta/gexf:description')->[0] ) {
			if (my $label = $metaNode->textContent()) {
				$self->graph( { label=>$label } );
				print  {$verboseOutfile} "inputGraphfromGEXF: set graph attribute label (from meta attribute description): $label\n" if $VERBOSE;
			}
		}
		
		
		foreach my $nodeElement ($xpc->findnodes('/gexf:gexf/gexf:graph/gexf:nodes/gexf:node')) {
			
			#my $node = $nodeElement->nodeName();
			my $id = $nodeElement->getAttribute('id');
			my $label = $nodeElement->getAttribute('label') || $EMPTY_STRING;
			$self->node( {id=>$id, label=>$label} );
			$nodecount++;
		}
		
		foreach my $edgeElement ($xpc->findnodes('/gexf:gexf/gexf:graph/gexf:edges/gexf:edge')) {
			
			#my $edge = $edgeElement->nodeName();
			my $source = $edgeElement->getAttribute('source');  #source, target, and id are required attributes
			my $target = $edgeElement->getAttribute('target');
			my $edgeID = $edgeElement->getAttribute('id');
			my $weight = $defaultWeight;
			if ($edgeElement->hasAttribute('weight')) {
				$weight = $edgeElement->getAttribute('weight');
			}
			elsif ($edgeElement->hasChildNodes() and my $dataWeightNode = $xpc->findnodes($weightXPATH,$edgeElement)->[0]) {
				$weight = $dataWeightNode->getAttribute('value');
				$attvalueWeightCount++;
			}
			my $label = ($edgeElement->hasAttribute('label')) ? $edgeElement->getAttribute('label') :  $EMPTY_STRING;
			my $edgeDirected = ($edgeElement->hasAttribute('type')) ? $edgeElement->getAttribute('type') :  $graphDirected;
			if ($weight) {
				$dupedgecount++ if $self->edgeExists( { sourceID=>$source, targetID=>$target } );
				$self->edge( { sourceID=>$source, targetID=>$target, weight=>$weight, directed=>$edgeDirected, label=>$label, id=>$edgeID } );
				$edgecount++;
			}
			else {
				carp "inputGraphfromGEXF: edge $source $target has no weight. Not created."
			}
		
		}
		
		carp "inputGraphfromGEXF: no nodes read from '$filename'" if !$nodecount;
		carp "inputGraphfromGEXF: no edges read from '$filename'" if !$edgecount;
		
		print  {$verboseOutfile} "inputGraphfromGEXF: found $nodecount nodes and $edgecount edges\n" if $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromGEXF: found $dupedgecount duplicate edges\n" if $dupedgecount and $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromGEXF: input edge weight from attvalue element for $attvalueWeightCount edges\n" if $attvalueWeightCount and $VERBOSE;
		
		return $self;
	}
	
	
	sub outputGraphtoGEXF {
		my ($self, $filename) = @_;
		
		my $nsURI = 'http://www.gexf.net/1.2draft';
		
		my $doc = XML::LibXML::Document->new('1.0','UTF-8');
		my $GEXF = $doc->createElementNS( $EMPTY_STRING, 'gexf' );
		$doc->setDocumentElement( $GEXF );
	 
		$GEXF->setNamespace( $nsURI , $EMPTY_STRING, 1 );
		
		$GEXF->setAttribute('xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
		$GEXF->setAttribute('xsi:schemaLocation','http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd');
		$GEXF->setAttribute('version','1.2');
		
		{
			my $now_string = localtime;
			$GEXF->appendChild($doc->createComment("Generated by Graph::Dijkstra on $now_string"));
		}
		{
			my (undef, undef, undef, $mday, $month, $year, undef, undef, undef) = localtime;
			my $ISODATE = sprintf "%4d-%02d-%02d", $year+1900, $month+1, $mday;
			my $meta = $GEXF->addNewChild( $nsURI, 'meta');
			$meta->setAttribute('lastmodifieddate', $ISODATE);
			if ($self->{creator}) {
				my $creatorNode = $meta->addNewChild( $nsURI, 'creator');
				$creatorNode->appendTextNode( $self->{creator} );
			}
			if ($self->{label}) {
				my $descriptionNode = $meta->addNewChild( $nsURI, 'description');
				$descriptionNode->appendTextNode( $self->{label} );
			}
		}
		
		my $graph = $GEXF->addNewChild( $nsURI, 'graph' );
		$graph->setAttribute('mode','static');
		$graph->setAttribute('defaultedgetype', $self->{edgedefault} );
		my $nodesElement = $graph->addNewChild( $nsURI, 'nodes' );
		
		my $nodecount = 0;
		my $edgecount = 0;
		
		my %edges = ();
		foreach my $nodeID ($self->nodeIDsList()) {
			
			my $nodeNode = $nodesElement->addNewChild( $nsURI, 'node' );
			$nodeNode->setAttribute('id', $nodeID);
			$nodeNode->setAttribute('label', $self->{nodes}{$nodeID}{label} );
			
			$nodecount++;
#			if ($self->_hasEdges($nodeID)) {
				foreach my $targetID ($self->adjacentNodes($nodeID)) {
					my $directed = $self->_getEdgeAttrib($nodeID, $targetID, 'directed');
					if ( ($directed eq 'undirected' and !exists($edges{$targetID}{$nodeID})) or $directed eq 'directed') {
						$edges{$nodeID}{$targetID}{weight} = $self->_getEdgeAttrib($nodeID, $targetID, 'weight');
						$edges{$nodeID}{$targetID}{id} = $self->_getEdgeAttrib($nodeID, $targetID, 'id');
						$edges{$nodeID}{$targetID}{directed} = $directed;
						$edges{$nodeID}{$targetID}{label} = $self->_getEdgeAttrib($nodeID, $targetID, 'label');
					}
				}
#			}
		}
		
		my $edgesElement = $graph->addNewChild( $nsURI, 'edges' );
		
		foreach my $sourceID (keys %edges) {
			foreach my $targetID (keys %{$edges{$sourceID}}) {
				
				$edgecount++;
				my $edgeNode = $edgesElement->addNewChild( $nsURI, 'edge');
				$edgeNode->setAttribute('id', ($edges{$sourceID}{$targetID}{id} ne '') ? $edges{$sourceID}{$targetID}{id} : $edgecount);
				$edgeNode->setAttribute('source', $sourceID );
				$edgeNode->setAttribute('target', $targetID );
				$edgeNode->setAttribute('weight', $edges{$sourceID}{$targetID}{weight} );
				$edgeNode->setAttribute('directed', $edges{$sourceID}{$targetID}{directed} ) if $edges{$sourceID}{$targetID}{directed} ne $self->{edgedefault};
				$edgeNode->setAttribute('label', $edges{$sourceID}{$targetID}{label} ) if $edges{$sourceID}{$targetID}{label};
				
			}
		}
		my $state = $doc->toFile($filename,2);
		croak "could not output internal grap to '$filename'" if !$state;
	
		print  {$verboseOutfile} "outputGraphtoGEXF: wrote $nodecount nodes and $edgecount edges to '$filename'\n" if $VERBOSE;
		return $self;
	}
	
	sub validateGraphMLxml {
		my ($either, $filename) = @_;
		
		Readonly my $GraphML_URL => 'http://graphml.graphdrawing.org/xmlns/1.1/graphml.xsd';
		
		my $GraphMLschema;
		
		eval {
			$GraphMLschema = XML::LibXML::Schema->new( location => $GraphML_URL );
			print  {$verboseOutfile} "validateGraphMLxml: loaded GraphML schema\n" if $VERBOSE;
		};
		if ($@) {
			print  {$verboseOutfile} "\n$@\n" if $VERBOSE;
			carp "validateGraphMLxml: GraphML xml schema URL not accessible: $GraphML_URL";
			return(0,'GraphML xml schema URL not accessible');
		}
			
		my $dom = XML::LibXML->load_xml(location => $filename);
		print  {$verboseOutfile} "validateGraphMLxml: loaded '$filename'\n" if $VERBOSE;
		
		eval { $GraphMLschema->validate( $dom ); };
		
		if ($@) {
			print  {$verboseOutfile} "validateGraphMLxml: validate failed\n$@\n" if $VERBOSE;
			return(0,$@);
		}
		else {
			print  {$verboseOutfile} "validateGraphMLxml: validated\n" if $VERBOSE;
			return(1,$EMPTY_STRING);
		}
		
	}
	
	sub validateGEXFxml {
		my ($either, $filename) = @_;
		
		Readonly my $GEXF_URL => 'http://www.gexf.net/1.2draft/gexf.xsd';
		my $GEXFschema;
		
		eval {
			$GEXFschema = XML::LibXML::Schema->new( location => $GEXF_URL );
			print  {$verboseOutfile} "validateGEXFxml: loaded GEXF schema\n" if $VERBOSE;
		};
		if ($@) {
			print  {$verboseOutfile} "\n$@\n" if $VERBOSE;
			carp "validateGEXFxml: GEXF xml schema URL not accessible: $GEXF_URL";
			return(0,'GEXF xml schema URL not accessible');
		}
		
		my $dom = XML::LibXML->load_xml(location => $filename);
		print  {$verboseOutfile} "validateGEXFxml: loaded '$filename'\n" if $VERBOSE;
		
		eval { $GEXFschema->validate( $dom ); };
		
		if ($@) {
			print  {$verboseOutfile} "validateGEXFxml: validate failed\n$@\n" if $VERBOSE;
			return(0,$@);
		}
		else {
			print  {$verboseOutfile} "validateGEXFxml: validated\n" if $VERBOSE;
			return(1,$EMPTY_STRING);
		}
		
	}
	
	
} #XML file format methods

#############################################################################
#NET (Pajek) file format methods                                            #
#############################################################################
{
	sub inputGraphfromNET {
		my ($self, $filename) = @_;
		
		use Regexp::Common qw /delimited/;
		
		if (!ref($self)) {
			$self = Graph::Dijkstra->new();
		}
		
		open(my $infile, '<:encoding(UTF-8)', $filename) or croak "inputGraphfromNET: could not open '$filename' for input";
		
		print  {$verboseOutfile} "inputGraphfromNET: opened '$filename' for input\n" if $VERBOSE;
		
		my $nodes = 0;
		while (my $line = <$infile>) {
			if ($line =~ /^\*vertices\s+(\d+)/ix) {
				$nodes = $1;
				last;
			}
		}
		croak "inputGraphfromNET: vertices element not found" if !$nodes;
		print  {$verboseOutfile} "inputGraphfromNET: vertices = $nodes\n" if $VERBOSE;
		
		my $nodecount = 0;
		my $edgecount = 0;
		my $dupedgecount = 0;
		
		my $quotedRE = $RE{delimited}{-delim=>'"'};
		#print "quotedRE = '$quotedRE'\n";
		
		my $nextSection = '';
		foreach my $i (1 .. $nodes) {
			my $line = '';
			while(1) {
				$line = <$infile>;
				croak "inputGraphfromNET: unexpected EOF in vertices section" if !defined($line);
				chomp $line;
				last if substr($line,0,1) ne '%';
			}
			
			if (substr($line,0,1) eq '*') {
				$nextSection = lc($line);
				last;
			}

			if ($line =~ /^\s*(\d+)\s+($quotedRE)/ix) {
				my $id = $1;
				my $label = $2;
				$label = substr($label,1,-1);  #strip quotes
				$self->node( {id=>$id, label=>$label} );
				$nodecount++;
			}
		}
		if ($nextSection and $nodecount == 0) {
			print  {$verboseOutfile} "inputGraphfromNET: empty vertices section (no node labels).  Generating node ID values 1 .. $nodes\n" if $VERBOSE;
			foreach my $i (1 .. $nodes) {
				$self->node( {id=>$i, label=>$EMPTY_STRING} );
				$nodecount++;
			}
		}
		elsif ($nodes != $nodecount) {
			die "inputGraphfromNET: internal logic error: # vertices ($nodes) != # read nodes ($nodecount)";
		}
		
		if ($nextSection =~ /^(\*\w+)/) {
			$nextSection = $1;
		}
		elsif ($nextSection) {
			die "inputGraphfromNET: internal logic error.  Did not recognize next section '$nextSection' in NET (pajek) file.";
		}
		
		croak "inputGraphfromNET: input file contains *arclist section.  Not supported." if $nextSection eq '*arclist';
		croak "inputGraphfromNET: input file contains *edgelist section.  Not supported." if $nextSection eq '*edgelist';
		
		print  {$verboseOutfile} "inputGraphfromNET: next section is '$nextSection'\n" if $nextSection and $VERBOSE;
		
		while (1) {
			
			if ($nextSection ne '*arcs' and $nextSection ne '*edges') {
				$nextSection = '';
				while (my $line = <$infile>) {
					if ($line =~ /^(\*(?:edges|arcs))/i) {
						$nextSection = lc($1);
						last;
					}
				}
				last if !$nextSection;
			}
			
			my $edgeDirected = ($nextSection eq '*edges') ? 'undirected' : 'directed';
			$nextSection = '';
			
			while (my $line = <$infile>) {
				chomp $line;
				next if !$line;
				next if substr($line,0,1) eq '%';
				if ($line =~ /^(\*\w+)/) {
					$nextSection = lc($1);
					last;
				}
				if ($line =~ /^\s+(\d+)\s+(\d+)\s+([0-9\.]+)/s) {
					my $sourceID = $1;
					my $targetID = $2;
					my $weight = $3;
					$dupedgecount++ if $self->edgeExists( { sourceID=>$sourceID, targetID=>$targetID } );
					$self->edge( { sourceID=>$sourceID, targetID=>$targetID, weight=>$weight, directed=>$edgeDirected } );
					$edgecount++;
				}
				else {
					chomp $line;
					carp "inputGraphfromNET: unrecognized input line (maybe edge with no weight?) =>$line<=";
					last;
				}
			}
			last if !$nextSection;
		}
		close($infile);
		
		carp "inputGraphfromNET: no nodes read from '$filename'" if !$nodecount;
		carp "inputGraphfromNET: no edges read from '$filename'" if !$edgecount;
		
		print  {$verboseOutfile} "inputGraphfromNET: found $nodecount nodes and $edgecount edges\n" if $VERBOSE;
		print  {$verboseOutfile} "inputGraphfromNET: found $dupedgecount duplicate edges\n" if $dupedgecount and $VERBOSE;
		
		return $self;
	}
		
	sub outputGraphtoNET {
		my ($self, $filename) = @_;
		
		open(my $outfile, '>:encoding(UTF-8)', $filename) or croak "outputGraphtoNET: could not open '$filename' for output";
		
		print  {$verboseOutfile} "outputGraphtoNET: opened '$filename' for output\n" if $VERBOSE;
		
		my %edges = ();
		my $nodecount = 0;
		my $edgecount = 0;
		my $useConsecutiveNumericIDs = 1;
		my $hasNonBlankLabels = 0;
		my $highestNumericID = 0;
		my $lowestNumericID = $PINF;
		
		my @nodeList = $self->nodeList();
		
		foreach my $nodeHref (@nodeList) {
			$nodecount++;
			my $nodeID = $nodeHref->{id};
			my $label = $nodeHref->{label};
			if ($useConsecutiveNumericIDs) {
				if ($nodeID =~ /^\d+$/) {
					$highestNumericID = $nodeID if $nodeID > $highestNumericID;
					$lowestNumericID = $nodeID if $nodeID < $lowestNumericID;
				}
				else {
					$useConsecutiveNumericIDs = 0;
				}
			}
			
			$hasNonBlankLabels = 1 if (!$hasNonBlankLabels and $label ne $EMPTY_STRING);
		}
		print  {$verboseOutfile} "outputGraphtoNET: internal graph has non-blank labels.\n" if $VERBOSE and $hasNonBlankLabels;
		
		if ($useConsecutiveNumericIDs) {
			if ($highestNumericID != $nodecount or $lowestNumericID != 1) {
				$useConsecutiveNumericIDs = 0;
			}
		}
		
		
		{
			my $now_string = localtime;
			print {$outfile} "% Generated by Graph::Dijkstra on $now_string\n";
		}
		
		print {$outfile} "*Vertices $nodecount\n";
		
		my $hasArcs = 0;
		my $hasEdges = 0;
		
		if ($useConsecutiveNumericIDs) {

			print  {$verboseOutfile} "outputGraphtoNET: internal graph has consecutive numeric IDs.\n" if $VERBOSE;
			$nodecount = 0;
			foreach my $nodeHref (sort { $a->{id} <=> $b->{id} } @nodeList) {
				
				$nodecount++;
				
				my $nodeID = $nodeHref->{id};
				my $label = $nodeHref->{label};
				croak "outputGraphtoNET: node IDs are not consecutive numeric integers starting at 1" if ($nodeID != $nodecount);
				
				if ($hasNonBlankLabels) {
					printf {$outfile} "%7d \"%s\"\n", $nodeID, $label;
				}
				
#				if ($self->_hasEdges($nodeID)) {
					foreach my $targetID ($self->adjacentNodes($nodeID)) {
						my $edgeDirected = $self->_getEdgeAttrib($nodeID, $targetID, 'directed');
						if ( ($edgeDirected eq 'undirected' and !exists($edges{$targetID}{$nodeID}) ) or $edgeDirected eq 'directed') {
							$edges{$nodeID}{$targetID}{weight} = $self->_getEdgeAttrib($nodeID, $targetID, 'weight');
							$edges{$nodeID}{$targetID}{directed} = $edgeDirected;
							if ($edgeDirected eq 'directed') {
								$hasArcs++;
							}
							else {
								$hasEdges++;
							}
						}
					}
#				}
			}
		}
		else {
			if ($VERBOSE) {
				print  {$verboseOutfile} "outputGraphtoNET: internal graph node ID values are not consecutive integer values starting at 1.\n";
				print  {$verboseOutfile} "outputGraphtoNET: internal graph node ID values not perserved in output\n";
				print  {$verboseOutfile} "outputGraphtoNET: generating consecutive integer ID values in output\n";
			}
			
			my %nodeIDtoNumericID = ();
			foreach my $i (0 .. $#nodeList) {
				$nodeIDtoNumericID{ $nodeList[$i]->{id} } = $i+1;
			}
			
			foreach my $nodeID (sort {$nodeIDtoNumericID{$a} <=> $nodeIDtoNumericID{$b}} keys %nodeIDtoNumericID) {
				if ($hasNonBlankLabels) {
					printf {$outfile} "%7d \"%s\"\n", $nodeIDtoNumericID{$nodeID}, $self->{nodes}{$nodeID}{label};
				}
				
#				if ($self->_hasEdges($nodeID)) {
					my $numericNodeID = $nodeIDtoNumericID{$nodeID};
					foreach my $targetID ($self->adjacentNodes($nodeID)) {
						my $edgeDirected = $self->_getEdgeAttrib($nodeID, $targetID, 'directed');
						my $numericTargetID = $nodeIDtoNumericID{$targetID};
						if ( ($edgeDirected eq 'undirected' and !exists($edges{$numericTargetID}{$numericNodeID})) or $edgeDirected eq 'directed') {
							$edges{$numericNodeID}{$numericTargetID}{weight} = $self->_getEdgeAttrib($nodeID, $targetID, 'weight');
							$edges{$numericNodeID}{$numericTargetID}{directed} = $edgeDirected;
							if ($edgeDirected eq 'directed') {
								$hasArcs++;
							}
							else {
								$hasEdges++;
							}
						}
					}
#				}
			}
		}
		
		if ($hasEdges) {
			print {$outfile} "*Edges\n";
			foreach my $sourceID (sort {$a <=> $b} keys %edges) {
				foreach my $targetID (sort {$a <=> $b} keys %{$edges{$sourceID}} ) {
					next if $edges{$sourceID}{$targetID}{directed} eq 'directed';
					printf {$outfile} "%7d %7d %10s\n", $sourceID, $targetID, "$edges{$sourceID}{$targetID}{weight}";
					$edgecount++;
				}
			}
		}
		if ($hasArcs) {
			print {$outfile} "*Arcs\n";
			foreach my $sourceID (sort {$a <=> $b} keys %edges) {
				foreach my $targetID (sort {$a <=> $b} keys %{$edges{$sourceID}} ) {
					next if $edges{$sourceID}{$targetID}{directed} eq 'undirected';
					printf {$outfile} "%7d %7d %10s\n", $sourceID, $targetID, "$edges{$sourceID}{$targetID}{weight}";
					$edgecount++;
				}
			}
		}
		close($outfile);
		
		print  {$verboseOutfile} "outputGraphtoNET: wrote $nodecount nodes and $edgecount edges to '$filename'\n" if $VERBOSE;
		return $self;
	}
	
	
}  #NET (Pagek) file format methods

1;

__END__


=head1 NAME
 
Graph::Dijkstra - Dijkstra computations with methods to input/output graph datasets from/to supported file formats
 
=head1 SYNOPSIS
 
  use Graph::Dijkstra;
  
  # create the object
  my $graph = Graph::Dijkstra->new();  #create the graph object with default attribute values
  my $graph = Graph::Dijkstra->new( {label=>'my graph label', creator=>'my name', edgedefault=>'undirected'} );  #create the graph object setting the label, creator, and/or edgedefault attibutes
  my $graph = Graph::Dijkstra->inputGraphfromCSV($filename);  #load graph from supported file format creating the graph object.
  
  #SET method to update graph attributes
  $graph->graph( {label=>'my graph label', creator=>'my name', edgedefault='directed'} );
  
  #GET method to return graph attributes in hash (reference)(eg., $graphAttribs->{label}, $graphAttribs->{creator})
  my $graphAttribs = $graph->graph();
  my $graphLabel = $graph->graph()->{label}; #references label attribute of graph
  
  #SET methods to create, update, and delete (remove) nodes and edges
  $graph->node( {id=>0, label=>'nodeA'} );   #create or update existing node.  id must be a simple scalar.
  $graph->node( {id=>1, label=>'nodeB'} );   #label is optional and should be string
  $graph->node( {id=>2, label=>'nodeC'} );
  $graph->edge( {sourceID=>0, targetID=>1, weight=>3, id=>'A', label=>'edge 0 to 1', directed='directed'} );  #create or update edge between sourceID and targetID;  weight (cost) must be > 0
  $graph->edge( {sourceID=>1, targetID=>2, weight=>2} );
  $graph->removeNode( 0 );
  $graph->removeEdge( {sourceID=>0, targetID=1} );
  
  #GET methods for nodes and edges
  my $nodeAttribs = $graph->node( 0 );  #returns hash reference (eg., $nodeAttribs->{id}, $nodeAttribs->{label}) or undef if node id 0 not found
  my $nodeLabel = $graph->node( 0 )->{label}; #references label attribute of node with ID value of 0
  my $bool = $graph->nodeExists( 0 );
  my $edgeAttribs = $graph->edge( { sourceID=>0, targetID=>1} );
  my $edgeWeight = $graph->edge( { sourceID=>0, targetID=>1} )->{weight};  #references weight attribute of edge that connects sourceID to targetID
  my $bool = $graph->edgeExists( { sourceID=>0, targetID=>1 } );
  my @nodes = $graph->nodeList();  #returns array (list) of all nodes in the internal graph, each array element is a hash (reference) containing the node ID and label attributes
  my @nodes = $graph->nodeIDsList();  #returns array (list) of all node ID values in the internal graph, each element is a nodeID value.
  my $bool = $graph->adjacent( { sourceID=>0, targetID=>1 } );
  my @nodes = $graph->adjacentNodes( 0 ); #returns list of node IDs connected by an edge with node ID 0
  
  #methods to input graph from a supported file format
  #inputGraphfrom[Format] methods can also be invoked as class methods which return the graph object on success
  $graph->inputGraphfromGML('mygraphfile.gml');
  $graph->inputGraphfromCSV('mygraphfile.csv');
  my $graph = Graph::Dijkstra->inputGraphfromCSV('mygraphfile.csv');
  $graph->inputGraphfromJSON('mygraphfile.json');   #JSON Graph Specification
  $graph->inputGraphfromGraphML('mygraphfile.graphml.xml', {keyEdgeValueID => 'weight', keyNodeLabelID => 'name'} );
  $graph->inputGraphfromGEXF('mygraphfile.gexf.xml' );
  $graph->inputGraphfromNET('mygraphfile.pajek.net' );   #NET (Pajek) format
  
  #methods to output internal graph to a supported file format
  $graph->outputGraphtoGML('mygraphfile.gml', 'creator name');
  $graph->outputGraphtoCSV('mygraphfile.csv');
  $graph->outputGraphtoJSON('mygraphfile.json');
  $graph->outputGraphtoGraphML('mygraphfile.graphml.xml', {keyEdgeWeightID => 'weight',keyEdgeWeightAttrName => 'weight', keyNodeLabelID => 'name', keyNodeLabelID => 'name'});
  $graph->outputGraphtoGEXF('mygraphfile.gexf.xml');
  $graph->outputGraphtoNET('mygraphfile.pajek.net');
  
  #class methods that validate the contents of XML files against the GraphML and GEXF schemas
  my ($bool, $errmsg) = Graph::Dijkstra->validateGraphMLxml('mygraphfile.graphml.xml');
  my ($bool, $errmsg) = Graph::Dijkstra->validateGEXFxml('mygraphfile.gexf.xml');
  
  #Dijkstra shortest path computation methods
  
  use Data::Dumper;
  my %Solution = ();
  
  #shortest path to farthest node from origin node
  %Solution = (originID => 0);
  if (my $solutionWeight = $graph->farthestNode( \%Solution )) {
  	print Dumper(\%Solution);
  }
  
  #shortest path between two nodes (from origin to destination)
  %Solution = (originID => 0, destinationID => 2);
  if (my $pathCost = $graph->shortestPath( \%Solution ) ) {
  	print Dumper(\%Solution);
  }
  
  #Jordan or vertex center with all points shortest path (APSP) matrix
  my %solutionMatrix = ();
  if (my $graphMinMax = $graph->vertexCenter(\%solutionMatrix) ) {
  	print  {$verboseOutfile} "Center Node Set 'eccentricity', minimal greatest distance to all other nodes $graphMinMax\n";
  	print  {$verboseOutfile} "Center Node Set = ", join(',', @{$solutionMatrix{centerNodeSet}} ), "\n";
  	
  	my @nodeList = (sort keys %{$solutionMatrix{row}});
  	print  {$verboseOutfile} 'From/To,', join(',',@nodeList), "\n";
  	foreach my $fromNode (@nodeList) {
  		print  {$verboseOutfile} "$fromNode";
  		foreach my $toNode (@nodeList) {
  			print  {$verboseOutfile} ",$solutionMatrix{row}{$fromNode}{$toNode}";
  		}
  		print  {$verboseOutfile} "\n";
  	}
  	$graph->outputAPSPmatrixtoCSV(\%solutionMatrix, 'APSP.csv');
  }
  
  #Alternative implementation of Jordan (vertex center) with APSP matrix method using Floyd Warhsall algorithm
  %solutionMatrix = ();
  my $graphMinMax = $graph->vertexCenterFloydWarshall(\%solutionMatrix);
  
  
  #Misc class methods
  
  #turn on / off verbose output to STDOUT or optional $filehandle
  Dijkstra::Graph->VERBOSE($bool, $filehandle);   
 
  #attribute hashRef to string
  my $attribStr = $graph->stringifyAttribs( $graph->graph() );  #( creator=>'', edgedefault=>'undirected', label=>'' )
  
  #string to attribute hashRef
  my $attribHref = Dijkstra::Graph->hashifyAttribs( $attribStr );   #{'creator' => '', 'edgedefault' => 'undirected', 'label' => '' }
  
  
=head1 DESCRIPTION
 
Efficient implementation of Dijkstras shortest path algorithm in Perl using a Minimum Priority Queue (L<Array::Heap::ModifiablePriorityQueue>**).

Computation methods.

	farthestNode() Shortest path to farthest node from an origin node
	shortestPath() Shortest path between two nodes
	vertexCenter() Jordan center node set (vertex center) with all points shortest path (APSP) matrix*

*Version 0.60 added a second implementation of the vertex center method using the Floyd Warshall algorithm.

File input output methods support the following graph file formats.

	GML (Graph Modelling Language, not to be confused with Geospatial Markup Language or Geography Markup Language), 
	JSON Graph Specification (latest draft specification), 
	GraphML (XML based), 
	GEXF (Graph Exchange XML Format), 
	NET (Pajek), and
	CSV (a simple text based format, "native" to this module ).

Graph::Dijkstra supports undirected and directed graphs including mixed graphs with both types of edges.  Does not support loops (edge where sourceID == targetID) or negitive edge weights. 
Support for directed graphs/edges is new in version 0.50 (pre-production).

In this pre-production release, the internal graph data model is fixed. 
	
	Graph has three attributes: 'label', 'creator', and 'edgedefault'.  'edgedefault' must be either 'directed' or 'undirected' and defaults to 'undirected'.
	
	Nodes (vertices) have three attributes: 'id' (simple scalar, required, unique), 'label' (optional string), and 'edges', a list (hash) of the node id values of connected nodes.
	
	Edges have four required and two optional attributes.  Required edge attributes: 'targetID' and 'sourceID' (node 'id' values that must exist), 'weight'(cost/value/distance/amount), and 'directed'.
	'directed' must be 'directed' or 'undirected' and defaults to the graph 'edgedefault' value. 'weight' must be a positive number (integer or real) greater than 0.
	Optional edge attributes: edge 'id' and edge 'label'.  Note that there is no uniqueness checked for edge 'id' values.  Could be added in later version.

The outputGraphto[file format] methods output data elements from the internal graph.  If converting between two supported formats (eg., GML and GraphML), unsupported
attributes from the input file (which are not saved in the internal graph) are *not* be written to the output file.  Later releases will extend the internal graph data model.

This pre-production release has not been sufficiently tested with real-world graph data sets. It has been tested with rather large datasets (tens of thousands of nodes, hundreds of thousands of edges).

If you encounter a problem or have suggested improvements, please email the author and include a sample dataset.
If providing a sample data set, please scrub it of any sensitive or confidential data.

**Array::Heap::ModifiablePriorityQueue, written in Perl, uses Array::Heap, an xs module.

=head1 METHODS
 
=head2 Class Methods
 
=over 4

=item Graph::Dijkstra->VERBOSE( $bool, $filehandle );

Class method that turns on or off informational output to STDOUT or optional $filehandle.  Called with no parameters, returns current VERBOSE setting.
If $filehandle is included, caller is responsible to open and close.

=item my $graph = Graph::Dijsktra->new();
 
Create a new, empty graph object. Returns the object on success.

=item my $graph = Graph::Dijsktra->new( {label=>'my graph label', creator=>'my name', edgedefault=>'undirected'} );
 
Create a new, empty graph object setting the graph level attributes label, creator, and edgedefault. Returns the object on success.

=item my $graph = Graph::Dijsktra->inputGraphfromCSV($filename);
 
Input a graph from a supported file format and return a graph object with graph attributes set from the file values.  Works with all supported file formats.

=item my $attribStr = $graph->stringifyAttribs( $graph->graph() );  
  
Returns a string representation of the attribute hashRef.  Sample: ( creator=>'', edgedefault=>'undirected', label=>'' )

=item  my $attribHref = Dijkstra::Graph->hashifyAttribs( $attribStr );

Returns a hash reference from a string representation of an attribute hash.  Sample: {'creator' => '', 'edgedefault' => 'undirected', 'label' => '' }


=back

=head2 Graph methods

=over 4

=item $graph->graph( {label=>'my graph label', creator=>'my name', edgedefault=>'directed'} );

SET method that updates the graph level attributes label and creator.

=item my $graphAttribs = $graph->graph();

GET method that returns the graph level attributes label and creator in a hash reference (eg., C<< $graphAttribs->{label} >> C<< $graphAttribs->{creator} >> C<< $graphAttribs->{edgedefault} >> );

=back

=head2 Node methods

=over 4

=item $graph->node( {id=>$id, label=>$label} );

SET method: creates or updates existing node and returns self.  Node id values must be simple scalars.

=item my $nodeAttribs = $graph->node( $id );
 
GET method: returns the hash (reference) with the id and label values for that node or undef if the node ID does not exist.  
Note: nodes may have blank ('') labels.  Use nodeExists method to test for existance.
 
=item my $bool = $graph->nodeExists( $id );
 
GET method: returns true if a node with that ID values exists or false if not.

=item my @list = $graph->nodeList();

Returns unsorted array (list) of the nodes in the graph.  Each list element is a hash (reference) that contains an "id" and "label" attribute.
$list[0]->{id} is the id value of the first node and $list[0]->{label} is the label value of the first node.

=item my @list = $graph->nodeIDsList();

Returns unsorted array (list) of the node ID values in the graph.

=item $graph->removeNode( $id );
 
Removes node identified by $id and all connecting edges and returns self.  Returns undef if $id does not exist.
 			
=back

=head2 Edge methods

=over 4

=item $graph->edge( {sourceID=>$sourceID, targetID=>$targetID, weight=>$weight, id=>'A', label=>'father', directed=>'undirected'} );
 
SET method: creates or updates existing edge between $sourceID and $targetID and returns $self. $weight must be > 0. If "directed" not set, edge direction defaults to the graphs "edgedefault" value.

Returns undef if $weight <= 0 or if $sourceID or $targetID do not exist.

Carp's and returns undef if update would change the "directed" value of the edge.  To change an edge's directed value, delete (removeEdge) first.
									 
=item my $graphAtrribs = $graph->edge( {sourceID=>$sourceID, targetID=>$targetID} );

GET method: returns hash reference with edge attributes: sourceID, targetID, weight, edge ID, edge label, and edge "directed".
"weight" is 0 if there is no edge between sourceID and targetID (and sourceID and targetID both exist).
Returns undef if sourceID or targetID do not exist. 											 
 
=item my $bool = $graph->edgeExists( { sourceID=>$sourceID, targetID=>$targetID } );
 
GET method: returns true if an edge connects the source and target IDs or false if an edge has not been defined.
 
=item my $bool = $graph->adjacent( { sourceID=>$sourceID, targetID=>$targetID } );
 
GET method: returns true if an edge connects $sourceID and $targetID or false if not.  Returns undef if $sourceID or $targetID do not exist.

=item my @list = $graph->adjacentNodes( $id );
 
Returns unsorted list of node IDs connected to node $id by an edge.  Returns undef if $id does not exist.
 
=item $graph->removeEdge( { sourceID=>$sourceID, targetID=>$targetID } );
 
Removes edge between $sourceID and $targetID (and $targetID and $sourceID) and returns self.  Returns undef if $sourceID or $targetID do not exist.
	
=back

=head2 Dijkstra computation methods

=over 4

=item my $solutionWeight = $graph->farthestNode( $solutionHref );
 
Returns the cost of the shortest path to the farthest node from the origin.  Attribute originID must be set in the parameter (hash reference) $solutionHref.
Carps and returns 0 if originID attribute not set or if node ID value not found in internal graph.
Populates $solutionHref (hash reference) with total weight (cost) of the farthest node(s) from the originID and the edge list from the originID
to the farthest node(s).  When there is more than one solution (two or more farthest nodes from the origin with the same total weight/cost), the solution hash
includes multiple "path" elements, one for each farthest node.

Sample code

	my %Solution = (originID=>'I');
	if ( my $solutionWeight = $graph->farthestNode(\%Solution) ) {
		print Dumper(\%Solution);
		foreach my $i (1 .. $Solution{count}) {
			print "From originID $Solution{originID}, solution path ($i) to farthest node $Solution{path}{$i}{destinationID} at weight (cost) $Solution{weight}\n";
			foreach my $edgeHref (@{$Solution{path}{$i}{edges}}) {
				print "\tsourceID='$edgeHref->{sourceID}' targetID='$edgeHref->{targetID}' weight='$edgeHref->{weight}'\n";
			}
		}
	}

Produces the following output

	$VAR1 = {
          'weight' => 18,
          'originID' => 'I',
          'desc' => 'farthest',
          'count' => 2,
          'path' => {
                      '1' => {
                               'destinationID' => 'A',
                               'edges' => [
                                            {
                                              'sourceID' => 'I',
                                              'targetID' => 'L',
                                              'weight' => 4
                                            },
                                            {
                                              'weight' => 6,
                                              'targetID' => 'H',
                                              'sourceID' => 'L'
                                            },
                                            {
                                              'sourceID' => 'H',
                                              'targetID' => 'D',
                                              'weight' => 5
                                            },
                                            {
                                              'weight' => 3,
                                              'targetID' => 'A',
                                              'sourceID' => 'D'
                                            }
                                          ]
                             },
                      '2' => {
                               'destinationID' => 'C',
                               'edges' => [
                                            {
                                              'sourceID' => 'I',
                                              'targetID' => 'J',
                                              'weight' => 2
                                            },
                                            {
                                              'weight' => 9,
                                              'targetID' => 'K',
                                              'sourceID' => 'J'
                                            },
                                            {
                                              'targetID' => 'G',
                                              'sourceID' => 'K',
                                              'weight' => 2
                                            },
                                            {
                                              'weight' => 5,
                                              'sourceID' => 'G',
                                              'targetID' => 'C'
                                            }
                                          ]
                             }
                    }
        };

	From originID I, solution path (1) to farthest node A at weight (cost) 18
		sourceID='I' targetID='L' weight='4'
		sourceID='L' targetID='H' weight='6'
		sourceID='H' targetID='D' weight='5'
		sourceID='D' targetID='A' weight='3'
	From originID I, solution path (2) to farthest node C at weight (cost) 18
		sourceID='I' targetID='J' weight='2'
		sourceID='J' targetID='K' weight='9'
		sourceID='K' targetID='G' weight='2'
		sourceID='G' targetID='C' weight='5'


=item my $solutionWeight = $graph->shortestPath( $solutionHref );
 
Returns weight (cost) of shortest path between originID and destinationID (set in $solutionHref hash reference) or 0 if there is no path between originID and destinationID.
Carps if originID or destinationID not set or node ID values not found in internal graph.
Populates $solutionHref (hash reference) with total path weight (cost) and shortest path edge list.

Sample code

	my %Solution = ( originID=>'I', destinationID=>'A' );
	if ( my $pathCost = $graph->shortestPath(\%Solution) ) {
		print Dumper(\%Solution);
		print "Solution path from originID $Solution{originID} to destinationID $Solution{destinationID} at weight (cost) $Solution{weight}\n";
		foreach my $edgeHref (@{$Solution{edges}}) {
			print "\tsourceID='$edgeHref->{sourceID}' targetID='$edgeHref->{targetID}' weight='$edgeHref->{weight}'\n";
		}
	}
	
Produces the following output

	$VAR1 = {
          'destinationID' => 'A',
          'weight' => 18,
          'desc' => 'path',
          'originID' => 'I',
          'edges' => [
                       {
                         'weight' => 4,
                         'sourceID' => 'I',
                         'targetID' => 'L'
                       },
                       {
                         'targetID' => 'H',
                         'sourceID' => 'L',
                         'weight' => 6
                       },
                       {
                         'targetID' => 'D',
                         'weight' => 5,
                         'sourceID' => 'H'
                       },
                       {
                         'weight' => 3,
                         'sourceID' => 'D',
                         'targetID' => 'A'
                       }
                     ]
        };
        
	Solution path from originID I to destinationID A at weight (cost) 18
		sourceID='I' targetID='L' weight='4'
		sourceID='L' targetID='H' weight='6'
		sourceID='H' targetID='D' weight='5'
		sourceID='D' targetID='A' weight='3'

=item my $graphMinMax = $graph->vertexCenter($solutionMatrixHref);

Returns the graph "eccentricity", the minimal greatest distance to all other nodes from the "center node" set or Jordan center.
Carps if graph contains disconnected nodes (nodes with no edges) which are excluded.  If graph contains a disconnected sub-graph (a set of connected
nodes isoluated / disconnected from all other nodes), the return value is 0 -- as the center nodes are undefined.

The $solutionMatrix hash (reference) is updated to include the center node set (the list of nodes with the minimal greatest distance
to all other nodes) and the all points shortest path matrix.  In the all points shortest path matrix, an infinite value (1.#INF) indicates that there
is no path from the origin to the destination node.  In this case, the center node set is empty and the return value is 0.

Includes a class "helper" method that outputs the All Points Shortest Path matrix to a CSV file.

NOTE: The size of the All Points Shortest Path matrix is nodes^2 (expontial).  A graph with a thousand nodes results in a million entry matrix that
will take a long time to compute.  Have not evaluated the practical limit on the number of nodes.

Sample code

	my %solutionMatrix = ();
	
	my $graphMinMax = $graph->vertexCenter(\%solutionMatrix);
	print "Center Node Set = ", join(',', @{$solutionMatrix{centerNodeSet}} ), "\n";
	print "Center Node Set 'eccentricity', minimal greatest distance to all other nodes $graphMinMax\n";
	
	my @nodeList = (sort keys %{$solutionMatrix{row}});
	#  or (sort {$a <=> $b} keys %{$solutionMatrix{row}}) if the $nodeID values are numeric
	
	print 'From/To,', join(',',@nodeList), "\n";
	foreach my $fromNode (@nodeList) {
		print "$fromNode";
		foreach my $toNode (@nodeList) {
			print ",$solutionMatrix{row}{$fromNode}{$toNode}";
		}
		print "\n";
	}
	
	# Output All Points Shortest Path matrix to a .CSV file.  
	# If the nodeID values are numeric, include a third parameter, 'numeric' to sort the nodeID values numerically.
	
	$graph->outputAPSPmatrixtoCSV(\%solutionMatrix, 'APSP.csv');

=item my $graphMinMax = $graph->vertexCenterFloydWarshall($solutionMatrixHref);

Same as inputs and outputs as vertexCenter method.  

Implementation of the Floyd Warshall alogithm with an author included performance tweak: skips nodes with no outbound edges (node outdegree = 0) as
the distance from these nodes to all other nodes is infinite.

=back

=head2 Input graph methods

Note: all C<< inputGraphfrom[format] >> methods can be called as class methods (eg., C<< my $graph = Graph::Dijkstra->inputGraphfromJSON($filename); >> )

=over 4

=item $graph->inputGraphfromJSON($filename, {edgeWeightKey=>'value'});

Inputs nodes and edges from a JSON format file following the draft JSON Graph Specification. Optional hash reference following filename may contain a single attribute, edgeWeightKey, 
used to identify the edge weight attribute in the metadata section.  Default value is "value".

Supports single graph files only. JSON Graph Specification files using the "Graphs" (multi-graph) attribute are not supported.

If the Graph metadata section includes the "creator" attribute, sets the internal graph attribute "creator".  If the edge metadata section includes an id value, sets the edge id value.

Edge values/weights/costs are input using the edge metadata edgeWeightKey ("value") attribute and edge ids using the id value.
Example edge that includes metadata value attribute per JSON Graph Specification.
	{
    "source" : "1",
    "target" : "2",
    "metadata" : {
     "id" : "A",
     "value" : "0.5"
    }
  },

See JSON Graph Specification L<https://github.com/jsongraph/json-graph-specification>

=item $graph->inputGraphfromGML($filename);

Inputs nodes and edges from a Graphics Modelling Language format file (not to be confused with the Geospatial Markup Language XML format).  
Implemented using pattern matching (regexp's) on "node" and "edge" constructs.
An unmatched closing bracket (']') inside a quoted string attribute value will break the pattern matching.  
Quoted string attribute values (e.g., a label value) should not normally include an unmatched closing bracket.
Report as a bug and I'll work on re-implementing using a parser.

See Graph Modelling Language L<https://en.wikipedia.org/wiki/Graph_Modelling_Language>

=item $graph->inputGraphfromCSV($filename);

Inputs nodes and edges from a CSV format file developed by the author.  
The first column in each "row" is "graph", "node" or "edge".  Subsequent columns are attribute value pairs (eg., attrib=>'value').  Only non-blank attributes are included.

Example

	graph,edgedefault=>'undirected'
	node,id=>'A',label=>'one'
	node,id=>'C',label=>'three'
	node,id=>'B',"label=>'node B label'"
	node,id=>'D',"label=>'node D label'"
	edge,directed=>'directed',id=>4,sourceID=>'A',targetID=>'D',weight=>3
	edge,directed=>'undirected',id=>5,sourceID=>'A',targetID=>'B',weight=>4
	edge,directed=>'undirected',id=>3,sourceID=>'C',targetID=>'B',weight=>7
	edge,directed=>'undirected',id=>2,"label=>'Test Test'",sourceID=>'C',targetID=>'D',weight=>3
	edge,directed=>'undirected',id=>1,sourceID=>'B',targetID=>'D',weight=>5
	

=item $graph->inputGraphfromGraphML($filename, {keyEdgeValueID => 'weight', keyNodeLabelID => 'name'} );

Inputs nodes and edges from an XML format file following the GraphML specification.

Input files must contain only a single graph and cannot contain embedded graphs.  Hyperedges are not supported.

The options hash reference (second parameter following the filename) is used to provide the key element ID values for edge weight/value/cost/distance and node label/name/description.

If either is not provided, the method will search the key elements for (1) edge attributes (for="edge") with an attr.name value of weight, value, cost, or distance; 
and (2) node attributes (for="node") with an attr.name value of label, name, description, or nlabel.

Graphs must contain a "key" attribute for edges that identifies the edge weight/value/cost/distance such as C<< for="edge" attrib.name="weight" >>.  
If this key element includes a child element that specifies a default value, that default value will be used to populate the weight (cost/value/distance) for each edge node
that does not include a weight/value/cost/distance data element.  Seems odd to specify a default edge weight but it will be accepted.

 
  <key id="d1" for="edge" attr.name="weight" attr.type="double">
    <default>2.2</default>
  </key>

	<edge id="7" source="1" target="2">
		<data key="weight">0.5</data>
	</edge>

Graphs should contain a "key" attribute for nodes that identifies the node label / name / description such as C<< for="node" attrib.name="name" >> or C<< for="node" attrib.name="label" >>.
These are used to populate the internal graph "label" value for each node.  If not included, the internal node labels will be empty strings.

	<key id="name" for="node" attr.name="name" attr.type="string"/>
	
	<node id="4">
		<data key="name">josh</data>
	</node>

See GraphML Primer L<http://graphml.graphdrawing.org/primer/graphml-primer.html> and
GraphML example L<http://gephi.org/users/supported-graph-formats/graphml-format/>


=item $graph->inputGraphfromGEXF( $filename );

Inputs nodes and edges from an XML format file following the GEXF draft 1.2 specification.  Will also accept draft 1.1 specification files.

Files with multiple graphs are not supported.  Hierarchial nodes are not supported.  Croaks if either are detected.

Carps on files with a graph element attribute C<< mode="dynamic" >>.

Node elements are expected to contain a label element.  

Edge elements should contain a weight attribute but will default to 1.  Edge weights are input from either the edge element "weight" attribute or from an attvalues/attvalue element as follows.

	<attvalues>
		<attvalue for="weight" value="1.0"></attvalue>
	</attvalues>


=item $graph->inputGraphfromNET( $filename );

Input nodes and edges from NET (Pajek) format files.   Inputs nodes from C<< *Vertices >> section and edges from C<< *Edges >> and C<< *Arcs >> sections.
All other sections are ignored including: C<< *Arcslist >> and C<< *Edgeslist >>.  Edges are undirected and arcs are directed.

NET (Pajek) files with multiple (time based) Vertices and Edges sections are not supported.


=back

=head2 Output graph methods

=over 4

=item $graph->outputGraphtoGML($filename, $creator);

Using the internal graph, outputs a file in GML format.  Includes a "creator" entry on the first line of the file with a date and timestamp.
Note that non-numeric node IDs and label values are HTML encoded.

=item $graph->outputGraphtoJSON( $filename, {edgeWeightKey='value'} );

Using the internal graph, outputs a file following the JSON graph specification.  In the Graph metadata section, includes a comment attribute referencing this
module and the local time that the JSON document was created.  Uses the edgeWeightKey value (which defaults to "value") to output edge weights in the edge metadata section. See the inputGraphfromJSON method for format details.


=item $graph->outputGraphtoCSV( $filename );

Using the internal graph, outputs a file in CSV format.  See the inputGraphfromCSV method for format details.

=item $graph->outputGraphtoGraphML($filename, {keyEdgeWeightID => '',keyEdgeWeightAttrName => '', keyNodeLabelID => '', keyNodeLabelID => ''} );

Using the internal graph, outputs a file in XML format following the GraphML specification (schema).
The option attributes keyEdgeWeightID and keyEdgeWeightAttrName both default to 'weight'.  keyNodeLabelID and keyNodeLabelID both default to 'name'.  Set these 
attributes values only if you need to output different values for these key attributes.

=item $graph->outputGraphtoGEXF( $filename );

Using the internal graph, outputs a file in XML format following the GEXF draft 1.2 specification (schema).

=item $graph->outputGraphtoNET( $filename );

Using the internal graph, outputs a file in NET (Pajek) format. For node IDs, the NET format uses consecutive (sequential) numeric (integer) values (1 .. # of nodes).  
If the internal graph uses sequential numeric IDs, these will be preserved in the output file.  Otherwise, the existing node IDs are mapped to
sequentially numbered IDs that are output.  This preserves the graph node and edge structure but necessarily looses the existing node ID values.

Undirected edges are output in the C<< *Edges >> section and directed edges in the C<< *Arcs >> section.

=back

=head2 Input/Output class methods

=over 4

=item my ($bool, $errmsg) = Graph::Dijkstra->validateGraphMLxml( $filename );

Validates contents of $filename against GraphML XML schema L<http://graphml.graphdrawing.org/xmlns/1.1/graphml.xsd>
$bool is true (1) and $errmsg is empty if file contents are validated against schema.  Otherwise, $bool is false (0) and $errmsg is set.


=item my ($bool, $errmsg) = Graph::Dijkstra->validateGEXFxml( $filename );

Validates contents of $filename against GEXF XML schema L<http://www.gexf.net/1.2draft/gexf.xsd>
$bool is true (1) and $errmsg is empty if file contents are validated against schema.  Otherwise, $bool is false (0) and $errmsg is set.

=back


=head1 CHANGE HISTORY

=head2 Version 0.3		

	o Initial development release (first release that indexed correctly on CPAN)

=head2 Version 0.4

	o Added input/output methods for Pajek (NET) format files
	o Lots of incompatible changes.
	o Changed references to edge attribute labels to consistently use: sourceID, targetID, and weight.  
	o In the farthestNode and shortestPath methods, changed origin and destination to originID and destinationID as the starting and endpoint node ID values.
	o Changed the node, edge, removeEdge, adjacent, and edgeExists methods to use hash references as parameters.  Get version of node method returns hash reference.
		> Thought is that using hash references as parameters will better support future addition of graph, node, and edge attributes.
	o Changed the farthestNode and shortestPath methods to input the node ID value(s) in the solution hash reference parameter as "originID" and "destinationID".
	o Changed the solution hash reference returned by the farthestNode, shortestPath methods to use sourceID, targetID, and weight as hash attributes replacing source, target, and cost
	o Added two graph level attributes: label and creator.  Attributes are input / output from / to files as supported by that format.
	o Updated new method to accept an optional parameter hash (reference) with graph attributes
	o Added graph method to update (set) or return (get) graph attributes.
	o In files produced by the outputGraphto[file format] methods (exlcuding CSV files), added a comment "Generated by Graph::Dijkstra on [localtime string]".  In JSON, comment is a "metadata" attribute of the Graph object.
	o Validated that JSON text created by outputGraphtoJSON conforms to the JSON Graph Specification schema. 
	o Always bug fixes.
	o Updated test scripts.
	
=head2 Version 0.41

	o Updated edge (GET) method to return a hash reference with three attributes: sourceID, targetID, and weight.

=head2 Version 0.50

	o Added initial support for directed edges throughout (in addition to undirected). Not extensively tested.
	o Added three attributes to edge: 'id', 'label', and 'directed' (directed/undirected).
	o Added graph attribute 'edgedefault' (directed/undirected).
	o Added three readonly attribute hashes with default values for graph, node, and edge elements.  Expectation is that new attributes can be supported by updating the default hashes.
	o Updated format for CSV files (incompatible change) and rewrote associated input/output methods.
	o Added two "helper" class methods: stringifyAttribs and hashifyAttribs.
	o Added utf8::upgrade calls for all graph, node, and edge attribute values.
	o Added tests for directed and undirected edges.
	
=head2 Version 0.55

	o Modified inputGraphfrom[format] methods to also work as class methods that create and populate an internal graph instance.
	o Updated (bug fix) outputGraphtoGEXF to include version attribute in gexf element as required by schema.
	o Updated (bug fix) outputGraphtoGraphML and inputGraphfromGraphML to output and input graph element label values using the key element id / data key value "graphlabel" to avoid conflict with the edge label id value ("label")
	o Added two class methods, validateGraphMLxml and validateGEXFxml, that validate the contents of XML files against the GraphML and GEXF schemas.
	o Used the two new class validate[format]xml methods to validate the contents of xml files produced by outputGraphtoGraphML and outputGraphtoGEXF
	
=head2 Version 0.56

	o Modified VERBOSE method to accept an optional filehandle to redirect informational output.
	o Modified inputGraphfromGEXF method to input weight from either edge attribute weight (weight="9.9") or edge attvalues/attvalue element C<< <attvalue for="weight" value="9.9" /> >>.
	o Fixed bug in computation methods related to nodes with inbound but no outbound edges (directed))
	o Corrected / updated documentation (POD).

=head2 Version 0.60

	o Added Floyd Warshall variant of vertexCenter method and added tests.
	o Refactored (substantially rewrote) edge method and added tests.
	o Updated validateGraphMLxml and validateGEXFxml class methods to check for schema parse errors indicating that schema URL is not available; updated tests.
	o Documentation (POD) updates.
	
=head2 Version 0.70

	o Refactored internal representation of graph edges and nodes: separate hash structures within the graph object
	o Fixed subtle bug in removeNode method
	o Added nodeIDsList method and integrated into outputGraphto* methods replacing direct access to internal graph object data
	o Added two private methods, _getEdgeAttrib and _edgeExists, and integrated into computation and outputGraphto* methods replacing direct access to internal graph object data
	
=head1 PLATFORM DEPENDENCIES

Critical module depencies are XML::LibXML and Array::Heap::ModifiablePriorityQueue which itself uses Array::Heap.  XML::LibXML and Array::Head are XS modules.
XML::LibXML requires the c library libxml2.

For use with very large XML based graph files (GEXF or GraphML), recommend 64bit versions of Perl and the libxml2 (c) library.  See the "Performance" section.


=head1 PERFORMANCE

Performance measurements were recorded on an unremarkable laptop (Intel Core i5) running Microsoft Windows 10 (64bit) and ActiveState Perl 5.20.2 (x86). 
Reported times are Perl "use benchmark" measurements of the runtime of the core algorithm within the referenced methods.  Timings exclude data loading.
Measurements are indicative at best.

With a test graph of 16+K nodes and 121+K edges, both farthest and shortestPath completed in under 1 second (~0.45seconds).

The vertexCenter method is implemented using Dijkstra's shortest path algorithm which provides reasonable performance on connected graphs (where every node is reachable).
On sparsely (weakly) connected graphs (not every node pair is connected), the runtime substantially increases as the algorithm repeatedly attempts to compute shortest paths between nodes not connected by edges.
The Floyd Warshall implementation (vertexCenterFloydWarshall) includes a tweak that improves performance (reduces runtime) on sparsely connected graphs for nodes with no outbound edges (outdegree = 0).
On connected graphs, Dijkstra should run faster than Floyd Warshall.  In all other cases, Floyd Warshall should run faster.

For both implementations of vertexCenter, runtime is exponential (O3) based on the number of nodes.  Comptemplating adding a limit on the number of nodes, 
probably 1,000.

With a GraphML (XML) dataset containing over 700K nodes and 1M edges (>6M lines of text, ~175MB file size), the perl process ran out of memory 
(exceeded the 2GB per process limit for 32bit applications under 64bit MS Windows).  The memory allocation limit was reached in the libxml2 (c) library 
before control was returned to Perl.  Using the 64bit version of Perl should eliminate this problem.   The GraphML file is available at
L<http://sonetlab.fbk.eu/data/social_networks_of_wikipedia/> under the heading "Large Wikipedias (2 networks extracted automatically with the 2 algorithms)". 
Filename is eswiki-20110203-pages-meta-current.graphml.

 
=head1 LIMITATIONS / KNOWN ISSUES
 
Node ID values must be simple scalars.

Some inputGraphfrom[format] methods default edge weights to 1.

For speed and simplicity, input of GML format files (method inputGraphfromGML) implemented using pattern matching (regexp's).  An unmatched closing bracket (']') inside a quoted string (value) will break it. 
For testing, implemented an alternative using Parse::Recdescent (recursive descent) that eliminated the "unmatched closing bracket insided a quoted string" problem.
Unfortunately, performance was unacceptably slow (very bad) on large graph files (10K+ nodes, 100K+ thousand edges).  Will continue to evaluate alternatives.

At the time v0.60 was released to CPAN, the GraphML site L<http://graphml.graphdrawing.org/> had been down for 12+ hours.  This prevents the validateGraphMLxml from functioning (as the schema URL is not available).

=head1 TODOs

Add data attributes including:

	node graph coordinates (xy coordinates and/or lat/long),
	node and edge style (eg., line style, color)

Review and update inputGraphfrom[format] methods to consistently set default edge weight to 1 or allow caller to provide default edge weight.

Test very large graph datasets using a 64bit version of perl (without the 2GB process limit).

Add validateJSONgraph class method that validates contents of JSON file against JSON graph specification (dependent upon JSV::Validator package installing correctly)

Evaluate and refactor code to move the input/output graph functions to one or more separate packages to reduce the code size of the Graph::Dijkstra package.  For
example, put the input graph from file methods in a separate package and refactor to return a graph object.  For example:

	use Graph::Dijkstra;
	use Graph::Dijkstra::Input;
	
	my $graph = Graph::Dijkstra::Input::inputGraphfromGraphML($filename);
	
	#or maybe as functional call
	
	my $graph = inputGraphfromGraphML($filename);

Evaluate support for user defined graph, node, and edge attributes (metadata).

Continue to evaluate performance of vertexCenter methods.   Add a progress indicator triggered by the verbose setting.

Input welcome. Please email author with suggestions.  Graph data sets for testing (purged of sensitive/confidential data) are welcome and appreciated.

 
=head1 SEE ALSO
 
L<Array::Heap::ModifiablePriorityQueue>

Graph Modelling Language L<https://en.wikipedia.org/wiki/Graph_Modelling_Language>

JSON Graph Specification L<https://github.com/jsongraph/json-graph-specification>

GraphML Primer L<http://graphml.graphdrawing.org/primer/graphml-primer.html>

GraphML example L<http://gephi.org/users/supported-graph-formats/graphml-format/>

GEXF file format L<http://www.gexf.net/format/index.html>

NET (Pajek) File format L<https://gephi.org/users/supported-graph-formats/pajek-net-format/>
 
=head1 AUTHOR
 
D. Dewey Allen C<< <ddallen16@gmail.com> >>

 
=head1 COPYRIGHT/LICENSE

Copyright (C) 2015, D. Dewey Allen

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut



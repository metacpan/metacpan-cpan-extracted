package Graph::GML;

use 5.012003;
use strict;
use warnings;

use Graph;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Graph::GML ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};

	bless $self, $class;

	if (defined $args{'file'}) {
		return _handle_file($args{'file'});
	}
	
	return undef;
}

sub _handle_file {

	my $file = shift;

	my $string = _read_file($file);

	if ($string =~ /^Creator/) {
		my $creator;
		($creator,$string) = _get_string($string,"Creator");
		print $creator,"\n";
	}
	
	my $wd;
	($wd,$string) = _get_next($string);
	$wd =~ s/\s+//g;
	my $graph;
	my $nodes;
	my $populated;
	while (length($wd)) {
	#	print $wd,"\n";
		if ($string =~ /directed/) {
			#according to the spec, directed isn't really a tag
			#but's used, so we deal
			my $val;
			($val,$string) = _get_word($string);
			($val,$string) = _get_word($string);
	#		print "Directed:  ",$val,"\n";
			if ($val) {
				print "Made directed graph\n";
				$graph = Graph->new(directed=>1);
			}
			($wd,$string) = _get_next($string);
			next;
		}
		if ($wd eq "graph") {
			($wd,$string) = _get_next($string);
			next;
		}
		elsif ($wd eq "node") {
			if (!defined $graph) {
				#if not already created, assume undirected
				$graph = Graph::Undirected->new;
			}
			($nodes,$string) = _handle_node($nodes,$string);
		}
		elsif ($wd eq "edge") {
			if (!$populated) {
				$graph = _populate_graph($graph,$nodes);
				$populated = 1;
			}
			($graph,$string) = _handle_edge($graph,$nodes,$string);
		} 
		($wd,$string) = _get_next($string);
		$wd =~ s/\s+//g;
	}

	return $graph;
}

sub _populate_graph {

	my $graph = shift;
	my $nodes = shift;

	my $vert;
	foreach my $el (keys %{$nodes}) {

		if (ref($nodes->{$el}) eq "HASH" && defined $nodes->{$el}->{label}) {
			$vert = $nodes->{$el}->{label};
		}
		else {
			$vert = $el;
		}
		$graph->add_vertex($vert);
		if (ref($nodes->{$el}) eq "HASH" && defined $nodes->{$el}->{value}) {
			$graph->set_vertex_weight($vert,$nodes->{$el}->{value});
		}
	}

	return $graph;
}

sub _handle_node {
	my $nodehash = shift;
	my $string = shift;
	
	my $node;
	($node,$string) = _get_next($string);
	$node =~ s/^\s+//;
	my $tmphash;
	my ($key,$id,$val);
	while (length($node)) {
		($key,$node) = _get_word($node);
		if ($key eq "id") {
			($id,$node) = _get_word($node);
#			$tmphash->{id} = $id;
		}
		elsif ($key eq "name") {
			($tmphash->{name},$node) = _get_word($node);
		}
		elsif ($key eq "label") {
			($tmphash->{label},$node) = _get_string($node);
		}
		elsif ($key eq "comment") {
			($tmphash->{comment},$node) = _get_string($node);
		}
		elsif ($key eq "value") {
			($tmphash->{value},$node) = _get_string($node);
		}
	}
	
#	print $id,"\n";
	if (!defined $id) { return ($nodehash,$string); }
	if (!defined $tmphash) {
		$nodehash->{$id} = 1;
	
	}
	else {
		$nodehash->{$id} = $tmphash;
	}
	return ($nodehash,$string);
}

sub _handle_edge {
	my $graph = shift;
	my $nodes = shift;
	my $string = shift;
	
	my $edge;
	($edge,$string) = _get_next($string);
	$edge =~ s/^\s+//;
	my ($key,$source,$target,$label,$comment,$value);
	while (length($edge)) {
		($key,$edge) = _get_word($edge);
		if ($key eq "source") {
			($source,$edge) = _get_word($edge);
		}
		elsif ($key eq "target") {
			($target,$edge) = _get_word($edge);
		}
		elsif ($key eq "label") {
			($label,$edge) = _get_string($edge);
		}
		elsif ($key eq "comment") {
			($comment,$edge) = _get_string($edge);
		}
		elsif ($key eq "value") {
			($value,$edge) = _get_string($edge);
		}
	}

	if (ref($nodes->{$source}) eq "HASH" && defined $nodes->{$source}->{label}) {
		$source = $nodes->{$source}->{label};
	}
	if (ref($nodes->{$target}) eq "HASH" && defined $nodes->{$target}->{label}) {
		$target = $nodes->{$target}->{label};
	}
	if (defined $value) {
		$graph->add_weighted_edge($source,$target,$value);
	}
	else {
		$graph->add_edge($source,$target);
	}
#	print "Edge -- Source: ",$source," Target: ",$target," Label",$label,"\n";
	return ($graph,$string); 
}

sub _get_next {
	my $string = shift;
	my $split= '[';
	my $split2 = ']';
	my $wd;
	($wd,$string) = split(/[\Q$split$split2\E]/,$string,2);    
	return ($wd,$string);
}

sub _read_file {
	my $file = shift;
	
	my $data;
	open(IF,$file) || die $file," ",$!;
	while (<IF>) {
		chop;
		$data .= $_;
	}
	close(IF);
	$data =~ s/^\s+//;  # remove any strings at the beginning
	return $data;
}

sub _get_string {
	my $string = shift;
	my $id = shift;

	if (defined $id) {
		$string =~ s/$id\s+//;  #remove that pesky id string
	}
	my $split= '"';
	my ($bar,$creator,$str) = split(/\"/,$string,3); 
	return ($creator,$str);
}

sub _get_word {
	my $string = shift;

	$string =~ s/^\s+//;
	my ($wd,$str) = split(/\s+/,$string,2);

	return ($wd,$str);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Graph::GML - Perl extension for reading GML files and creating a Graph object

=head1 SYNOPSIS

  use Graph::GML;
  my $Obj = new Graph::GML(file=>"file.gml");

=head1 DESCRIPTION

The Graph Modelling Language (see http://en.wikipedia.org/wiki/Graph_Modelling_Language> ) is an ASCII file format for describing graphs.  It is quite extensive, not only defining the graph itself but including tags for graphics.  This perl module is concerned with reading in a GML file and then creating a Graph module for use in operations on the graph.  It does not handle the graphics section as defined in the standard. 

An example GML file is:

	
	Creator "Leigh Metcalf December 30, 2011"
	graph [
		directed 0
		comment "Hi there!"
		node [
			id 1
			label "Chocolate"
			value 3
		]
		node [
			id 2
			label "Chip"
			value 0
		]
		node [
			id 3
			label "Peanut butter"
			value 2
		]
		node [
			id 4
			label "Nutella"
			value 2
		]
		edge [
			source 1
			target 2
			value 3
		]
		edge [
			source 3
			target 4
			value 0
		]
		edge [
			source 2
			target 3
			value 1
		]
	]

Note that in creating the Graph perl module, the vertices are labeled not with the id given in the node section, but with the label.  If a label is not given, it defaults to the id.  The value given in the node section is used as the vertex weight and the value given in the edge section is the edge weight.  I have not found the directed keyword in the GML specification, however, since it seems to be used I support it and created the graph accordingly.

One caveat.  This perl module works by reading in the entire GML file and operating on the given text at this time.  If the GML file is 'large', this could cause a problem.


=head2 EXPORT

None by default.


=head1 SEE ALSO

All of the GML files found at http://www-personal.umich.edu/~mejn/netdata/ were used to test this perl module.  It is a very good source of network data.

=head1 AUTHOR

Leigh Metcalf, E<lt>leigh@fprime.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Leigh Metcalf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

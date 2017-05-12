package GOBO::Util::GraphFunctions;
use strict;

use Moose;
use Carp;

use GOBO::Graph;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
#use GOBO::Parsers::QuikOBOParser;
#use GOBO::Parsers::QuikGAFParser;
use GOBO::Writers::OBOWriter;
use GOBO::InferenceEngine;

use Data::Dumper;

# parse the options from the command line
sub parse_options {
	my $args = shift;

	if (!$args)
	{	die "Error: please ensure you have specified an input file, a subset, and an output file.\nThe help documentation can be accessed with the command 'go-slimdown.pl --help'\n";
	}

	my $opt;
	while (@$args && $args->[0] =~ /^\-/) {
		my $o = shift @$args;
		if ($o eq '-i' || $o eq '--ontology') {
			if (@$args && $args->[0] !~ /^\-/)
			{	$opt->{input} = shift @$args;
			}
		}
		elsif ($o eq '-s' || $o eq '--subset') {
			while (@$args && $args->[0] !~ /^\-/)
			{	my $s = shift @$args;
				$opt->{subset}{$s}++;
			}
		}
		elsif ($o eq '-o' || $o eq '--output') {
			$opt->{output} = shift @$args if @$args && $args->[0] !~ /^\-/;
		}
		elsif ($o eq '-b' || $o eq '--basename') {
			$opt->{basename} = shift @$args if @$args && $args->[0] !~ /^\-/;
		}
		elsif ($o eq '-c' || $o eq '--combined') {
			## use a combination of more than one subset nodes
			$opt->{combined} = 1;
		}
		elsif ($o eq '-a' || $o eq '--get_all_subsets') {
			$opt->{get_all_subsets} = 1;
		}
		elsif ($o eq '-r' || $o eq '--regexp') {
			# this option is "hidden" at the moment - enter a text string to be
			# qr//'d and use as a regexp
			$opt->{subset_regexp} = shift @$args if @$args && $args->[0] !~ /^\-/;
		}
		elsif ($o eq '-h' || $o eq '--help') {
			system("perldoc", $0);
			exit(0);
		}
		elsif ($o eq '-v' || $o eq '--verbose') {
			$opt->{verbose} = 1;
		}
		else {
			die "Error: no such option: $o\nThe help documentation can be accessed with the command 'go-slimdown.pl --help'\n";
		}
	}
	return $opt;
}


## process the input params
sub check_options {
	my $opt = shift;

	if (!$opt)
	{	die "Error: please ensure you have specified an input file, a subset, and an output file.\nThe help documentation can be accessed with the command 'go-slimdown.pl --help'\n";
	}

	my $errs;
	if (!$opt->{input})
	{	push @$errs, "specify an input file using -i /path/to/<file_name>";
	}
	elsif (! -e $opt->{input})
	{	push @$errs, "the file " . $opt->{input} . " could not be found.\n";
	}

	if (!$opt->{get_all_subsets} && ! $opt->{subset_regexp} && !$opt->{subset})
	{	push @$errs, "specify a subset using -s <subset_name>";
	}

	if (!$opt->{output} && !$opt->{basename})
	{	push @$errs, "specify an output file using -o /path/to/<file_name>";
	}

	if ($opt->{basename} && $opt->{basename} !~ /SLIM_NAME/)
	{	push @$errs, "specify a valid basename (containing SLIM_NAME) for the output files";
	}

	if (($opt->{subset} && scalar values %{$opt->{subset}} > 1)
		|| $opt->{get_all_subsets}
		|| $opt->{subset_regexp})
	{	## if we have more than one subset, make sure that we have specified a base name for the file
		if (!$opt->{combined} && !$opt->{basename})
		{	push @$errs, "specify a base file name (containing SLIM_NAME) for the output files using -b /path/to/<file_name>";
		}
		elsif ($opt->{combined})
		{	# only one output file if we're combining subsets
			if (! $opt->{output})
			{	push @$errs, "there should only be a single output file specified if subsets are to be combined";
			}
		}
	}

	my $cnt;
	if ($opt->{subset_regexp})
	{	eval { "" =~ /$opt->{subset_regexp}/; 1 };
		if ($@)
		{	push @$errs, "the regular expression specified was invalid: $@";
		}
		else
		{	$opt->{subset_regexp} = qr/$opt->{subset_regexp}/;
		}
		$cnt++;
	}
	$cnt++ if $opt->{get_all_subsets};
	$cnt++ if values %{$opt->{subset}};

	# make sure we only have one subset-related criterion specified
	if ($cnt && $cnt > 1)
	{	push @$errs, "specify *either* named subset(s) ( '-s <subset_name>' )\n*or* to get all subsets ( '-a' )";
	}

	if ($opt->{output} && $opt->{basename})
	{	## if we have any of the options which allow more than one subset
		## and the combined flag is off, use 'basename'
		if ((($opt->{subset} && scalar values %{$opt->{subset}} > 1)
			|| $opt->{get_all_subsets} || $opt->{subset_regexp})
			&& !$opt->{combined})
		{	warn "Using file path specified by the '-b' / '--basename' option\n";
		}
		else
		{	warn "Using file path specified by the '-o' / '--output' option\n";
			delete $opt->{basename};
		}
	}

	if ($errs && @$errs)
	{	die "Error: please correct the following parameters to run the script:\n" . ( join("\n", map { " - " . $_ } @$errs ) ) . "\nThe help documentation can be accessed with the command\n\tgo-slimdown.pl --help\n";
	}

#	$options = $opt;
#	return $opt;
}


sub get_graph {
	my $args = shift;
	my $options = $args->{options};

	my $parser;
	if ($options->{quick_parse})
	{	# parse the input file and check we get a graph
		$parser = new GOBO::Parsers::QuikOBOParser(file => $options->{input}, options => $options->{parser_options});
	}
	else
	{	# parse the input file and check we get a graph
		$parser = new GOBO::Parsers::OBOParser(file => $options->{input});
	}
	$parser->parse;
	die "Error: parser could not find a graph in " . $options->{input} . "!\n" unless $parser->graph;
	print STDERR "Finished parsing file " . $options->{input} . "\n" if $options->{verbose};

	return $parser->graph;

}


=head2 get_subset_nodes

get the subset nodes we want by whatever means, fair or foul
roots will be added to the subset after determining that there are other terms
in the subset

input:  graph   => Graph object
        options => option_h
          options may be:
          get_all_subsets => 1
          subset => { subset_name => 1, subset_2_name => 1 }
          
          # subset_regexp => regular expression

output: data hash or death with an appropriate error
        data hash will be of the form
        data->{subset}{subset_name}{id of node in subset} = 1
        data->{roots}{node id} = 1

=cut

sub get_subset_nodes {
	my $args = shift;
	my $graph = $args->{graph};
	my $options = $args->{options};

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless defined $graph && $options;

#	print STDERR "options: " . Dumper($options) . "\n";

	my $data_h;

	## create the subroutine to filter out the desired subset nodes
	my $sub_test;
	if ($options->{get_all_subsets})
	{	$sub_test = sub {
			my $node = shift;
			if ($node->subsets)
			{	map { $data_h->{subset}{$_->id}{$node->id}++ } @{$node->subsets};
			}
		};
	}
	elsif ($options->{subset_regexp})
	{	$sub_test = sub {
			my $node = shift;
			if ($node->subsets)
			{	foreach (map { $_->id } @{$node->subsets})
				{	$data_h->{subset}{$_}{$node->id}++ if /$options->{subset_regexp}/;
				}
			}
		};
	}
	else
	{	$sub_test = sub {
			my $node = shift;
			if ($node->subsets)
			{	foreach my $s (map { $_->id } @{$node->subsets})
				{	$data_h->{subset}{$s}{$node->id}++ if defined $options->{subset}{$s};
				}
			}
		};
	}
	
	foreach ( @{$graph->terms} )
	{	next if $_->obsolete;
		my $n = $_;
		# make sure that we have all the root nodes
		if (!@{$graph->get_outgoing_links($n)}) {
			$data_h->{roots}{$n->id}++;
		}
		## if it's in a subset, save the mofo.
		else
		{	&$sub_test($n);
		}
	}
	
	#	check that we have nodes in our subsets
	if ($options->{subset})
	{	my $no_nodes;
		foreach (keys %{$options->{subset}})
		{	if (! $data_h->{subset}{$_})
			{	push @$no_nodes, $_;
			}
		}
		if ($no_nodes)
		{	if (scalar @$no_nodes == scalar keys %{$options->{subset}})
			{	die "Error: no nodes were found in any of the subsets specified. Dying";
			}
			else
			{	warn "Error: no nodes were found for the following subset(s): " . join(", ", @$no_nodes) . "\nDying";
			}
		}
	}
	else
	{	if (! $data_h->{subset} || ! values %{$data_h->{subset}})
		{	if ($options->{get_all_subsets})
			{	die "Error: no subsets were found! Dying";
			}
			else
			{	die "Error: no subsets were found matching the regular expression specified! Dying";
			}
		}
	}
	
	
	# merge the subsets into one if we want combined results
	if ($options->{combined})
	{	my @subs = keys %{$data_h->{subset}};
		map { 
			map { 
				$data_h->{subset}{combined}{$_}++;
			} keys %{$data_h->{subset}{$_}};
			delete $data_h->{subset}{$_};
		} @subs;
	}


	## add the roots to the subsets (??)
	foreach my $r (keys %{$data_h->{roots}})
	{	foreach my $s (keys %{$data_h->{subset}})
		{	$data_h->{subset}{$s}{$r}++;
		}
	}

	return $data_h;
}


=head2 get_graph_relations

Get the relations and their inter-relation from a graph

input:  graph   => Graph object
        options => option_h

output: rel_h containing the relations from graph in the form
             { rel_node_id }{ rel_relation_id }{ rel_target_id }
        and rel_h->{got_graph} = 1

=cut

sub get_graph_relations {
	my $args = shift;
	my $graph = $args->{graph};
	my $options = $args->{options};

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $graph && $options;
	my $rel_h;

	# get the relations specified in the graph and see how they relate to each other...
	foreach (@{$graph->relations})
	{	if ($graph->get_outgoing_links($_))
		{	foreach (@{$graph->get_outgoing_links($_)})
			{	$rel_h->{graph}{$_->node->id}{$_->relation->id}{$_->target->id}++;
			}
		}
	}
	print STDERR "Finished getting relationships\n" if $options->{verbose};
	
	$rel_h->{got_graph} = 1;
	return $rel_h;
}


=head2 get_graph_links

input:  input   => hash of input nodes in the form node_id => 1; optional; uses
                   all graph nodes if not specified
        subset  => subset nodes in the form node_id => 1; optional; uses
                   all graph nodes if not specified
#        roots   => root nodes in the form node_id => 1
        graph   => Graph object
        inf_eng => inference engine (a new one will be created if not)
        
output: node data in the form
             {graph}{ node_id }{ relation_id }{ target_id }

=cut

sub get_graph_links {
	my $args = shift;
#	my $roots = $args->{roots};
	my $graph = $args->{graph};
	my $subset = $args->{subset};
	my $input = $args->{input};
	my $ie = $args->{inf_eng};

	confess( (caller(0))[3] . ": missing required arguments" ) unless $graph;

	# no input: use all the terms in the graph as input
	if (! $input )
	{	$input->{$_->id} = 1 foreach (@{$graph->terms});
	}

	$ie = new GOBO::InferenceEngine(graph => $graph) if ! $ie;

	confess( (caller(0))[3] . ": missing required arguments" ) unless $graph && $ie && $input;

	# get rid of any existing data
	my $node_data;

	if ($subset)
	{	# get all the links between the input nodes and those in the subset
		foreach my $t (keys %$input)
		{	## asserted links
			foreach (@{ $graph->get_outgoing_links($t) })
			{	# skip it unless the target is a root or in the subset
				next unless $subset->{$_->target->id}; # || $roots->{$_->target->id} ;
				$node_data->{graph}{$t}{$_->relation->id}{$_->target->id} = 1;
			}
	
			foreach (@{ $ie->get_inferred_target_links($t) })
			{	# skip it unless the target is a root or in the subset
				next unless $subset->{$_->target->id}; # || $roots->{$_->target->id} ;
				# skip it if we already have this link
				next if defined $node_data->{graph}{$t}{$_->relation->id}{$_->target->id};
				## add to a list of inferred entries
				$node_data->{graph}{$t}{$_->relation->id}{$_->target->id} = 2;
			}
		}
	}
	else
	{	# get all the links involving the input nodes
		foreach my $t (keys %$input)
		{	## asserted links
			foreach (@{ $graph->get_outgoing_links($t) })
			{	$node_data->{graph}{$t}{$_->relation->id}{$_->target->id} = 1;
			}
	
			foreach (@{ $ie->get_inferred_target_links($t) })
			{	# skip it if we already have this link
				next if defined $node_data->{graph}{$t}{$_->relation->id}{$_->target->id};
				## add to a list of inferred entries
				$node_data->{graph}{$t}{$_->relation->id}{$_->target->id} = 2;
			}
		}
	}

	return $node_data;
}


=head2 remove_redundant_relationships

input:  node_data => hash of node data in the form 
                     {graph}{ node_id }{ relation_id }{ target_id }
        rel_data  => relationship data hash (structure same as node_data)
        graph     => Graph object
        options   => option_h
        

output: node_data with redundant rels carefully removed

if we have relationships between relations -- e.g. positively_regulates is_a
regulates -- and two (or more) related relations are found between the same
two nodes, the less specific relationships are removed.

e.g.

A positively_regulates B
A regulates B

==> A regulates B will be removed

=cut

sub remove_redundant_relationships {
	my $args = shift;
	my $node_data = $args->{node_data};
	my $rel_data = $args->{rel_data};
	my $graph = $args->{graph};
	my $options = $args->{options};

	# make sure we have the relation relationships
	if (! $rel_data->{got_graph} )
	{	$rel_data = get_graph_relations({ graph => $graph, options => $options });
	}

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $node_data && $rel_data && $graph;

	if (defined $rel_data->{graph})
	{	populate_lookup_hashes({ graph_data => $rel_data });

		my $slimmed = trim_graph({ graph_data => $rel_data, options => $options });

		populate_lookup_hashes({ graph_data => $slimmed, options => $options  });

		## slim down the relationships
		## get rid of redundant relations
		# these are the closest to the root
		
		## this could probably be done more effectively / efficiently
		
		foreach my $r (keys %{$slimmed->{target_node_rel}})
		{	foreach my $r2 (keys %{$slimmed->{target_node_rel}{$r}})
			{	# if both exist...
				if ($node_data->{rel_node_target}{$r} && $node_data->{rel_node_target}{$r2})
				{
					# delete anything where we have the same node pairs with both relations
					foreach my $n (keys %{$node_data->{rel_node_target}{$r2}})
					{	if (defined $node_data->{graph}{$n}{$r})
					#	if ($data->{nodes}{rel_node_target}{$r}{$n})
						{
							foreach my $t (keys %{$node_data->{rel_node_target}{$r2}{$n}})
							{	if (defined $node_data->{graph}{$n}{$r}{$t})
								{
									delete $node_data->{graph}{$n}{$r}{$t};
									if (! values %{$node_data->{graph}{$n}{$r}})
									{	delete $node_data->{graph}{$n}{$r};
										if (! values %{$node_data->{graph}{$n}})
										{	delete $node_data->{graph}{$n};
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
#	return $node_data;
}


=head2 trim_graph

input:  graph_data => data hash with nodes and relations specified as
               {graph}{ node_id }{ relation_id }{ target_id }
          plus various rearrangements, with a hash key specifying the ordering
          e.g. {node_target_rel}
               {target_node_rel}
        options => option_h  # no options specified as yet

output: new data hash, slimmed down, with relations specified as
               {graph}{ node_id }{ relation_id }{ target_id }

For each term, finds the closest node for each relation and stores them in a hash

=cut

sub trim_graph {
	my $args = shift;
	my $d = $args->{graph_data};
	my $new_d;      # new data hash - woohoo!
	my $options = $args->{options};

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless values %{$d->{graph}};

	if (! $d->{node_rel_target} || ! $d->{target_node_rel} )
	{	populate_lookup_hashes({ graph_data => $d });
	}

	# for each node with a link to a 'target' (closer to root) node
	foreach my $id (keys %{$d->{node_target_rel}})
	{	# only connected to one node: must be the closest!
		if (scalar keys %{$d->{node_target_rel}{$id}} == 1)
		{	$new_d->{graph}{$id} = $d->{graph}{$id};
			next;
		}
		foreach my $rel (keys %{$d->{node_rel_target}{$id}})
		{	# only one node connected by $rel
			if (scalar keys %{$d->{node_rel_target}{$id}{$rel}} == 1)
			{	$new_d->{graph}{$id}{$rel} = $d->{node_rel_target}{$id}{$rel};
				next;
			}

			#	list_by_rel contains all the nodes between it and the root(s) of $id
			my @list_by_rel = keys %{$d->{node_rel_target}{$id}{$rel}};

			REL_SLIMDOWN_LOOP:
			while (@list_by_rel)
			{	my $a = pop @list_by_rel;
				my @list2_by_rel = ();
				while (@list_by_rel)
				{	my $b = pop @list_by_rel;
					if ($d->{target_node_rel}{$a}{$b})
					{	#	b is node, a is target
						#	forget about a, go on to the next list item
						push @list_by_rel, $b;
						push @list_by_rel, @list2_by_rel if @list2_by_rel;
						next REL_SLIMDOWN_LOOP;
					}
					elsif ($d->{node_target_rel}{$a}{$b})
					{	#	a is node, b is target
						#	forget about b, look at the next in the list
						next;
					}
					else
					{	#a and b aren't related
						#	keep b
						push @list2_by_rel, $b;
						next;
					}
				}
				#	if a is still around, it must be a descendent of
				#	all the nodes we've looked at, so it can go on our
				#	descendent list
				$new_d->{graph}{$id}{$rel}{$a} = $d->{node_rel_target}{$id}{$rel}{$a};

				#	if we have a list2_by_rel, transfer it back to @list_by_rel
				push @list_by_rel, @list2_by_rel if @list2_by_rel;
			}
		}
	}
	return $new_d;
}



=head2 populate_lookup_hashes

input:  data hash with nodes and relations specified as
             {graph}{ node_id }{ relation_id }{ target_id }
output: rearrangements of the data with first key specifying the order:
             {node_target_rel}
             {target_node_rel}
             {node_rel_target}
             {target_rel_node}
             {rel_node_target}
             {rel_target_node}

=cut

sub populate_lookup_hashes {
	my $args = shift;
	my $hash = $args->{graph_data};
	
	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless values %{$hash->{graph}};

	foreach my $k qw(node_target_rel target_node_rel node_rel_target target_rel_node rel_node_target rel_target_node)
	{	delete $hash->{$k};
	}

	foreach my $n (keys %{$hash->{graph}})
	{	foreach my $r (keys %{$hash->{graph}{$n}})
		{	foreach my $t (keys %{$hash->{graph}{$n}{$r}})
			{	$hash->{node_target_rel}{$n}{$t}{$r} = #1;
				$hash->{target_node_rel}{$t}{$n}{$r} = #1;
				$hash->{node_rel_target}{$n}{$r}{$t} = #1;
				$hash->{target_rel_node}{$t}{$r}{$n} = #1;
				$hash->{rel_node_target}{$r}{$n}{$t} = #1;
				$hash->{rel_target_node}{$r}{$t}{$n} = #1;
				$hash->{graph}{$n}{$r}{$t};
			}
		}
	}
}


=head2 write_graph_to_file

input:  graph => Graph object
        subset => subset name
        options => option_h

writes out the file

=cut

sub write_graph_to_file {
	my $args = shift;
	my $graph = $args->{graph};
	my $subset = $args->{subset};
	my $options = $args->{options};

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $graph && $subset && $options;

	if ($options->{basename})
	{	($options->{output} = $options->{basename}) =~ s/SLIM_NAME/$subset/;
	}
	print STDERR "Ready to print " . $options->{output} . "\n" if $options->{verbose};

	my $writer = GOBO::Writers::OBOWriter->create(file=>$options->{output}, format=>'obo');
	$writer->graph($graph);
	$writer->write();
}


=head2 get_closest_ancestral_nodes

input:  graph_data => data hash with nodes and relations specified as
               {graph}{ node_id }{ relation_id }{ target_id }
               nb: must already have had all that reasoning stuff done
          plus various rearrangements, with a hash key specifying the ordering
          e.g. {node_target_rel}
               {target_node_rel}
        id        => id of node to find the closest ancestral node of
        relation  => relation id, if wanted
        options => option_h

output: new data hash, slimmed down, with relations specified as
               {graph}{ node_id }{ relation_id }{ target_id }

For a given term, finds the closest node[s]

=cut

sub get_closest_ancestral_nodes {
	my $args = shift;
	my $d = $args->{graph_data};
	my $id = $args->{id};
	my $rel_wanted = $args->{relation} || undef;
	my $options = $args->{options};


	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $id && values %{$d->{graph}};

	# if there are no links whatsoever involving this term, report and return undef
	if (! $d->{graph}{$id} )
	{	print STDERR "No links from $id\n" if $options->{verbose};
		return undef;
	}

	if ( $rel_wanted )
	{	# if a relation is specified, but there are no relations involving this term
		# that match, return undef
		if ( ! values %{$d->{graph}{$id}{$rel_wanted}} )
		{	print STDERR "No $rel_wanted links from $id\n" if $options->{verbose};
			return undef;
		}
		# if it is only connected to one node by the relation, it must be the closest!
		elsif (scalar keys %{$d->{graph}{$id}{$rel_wanted}} == 1)
		{	return [ map { { node => $id, rel => $rel_wanted, target => $_ } } keys %{$d->{graph}{$id}{$rel_wanted}} ];
		}
	}

	# make sure the look up hashes are populated
	if (! $d->{node_rel_target} || ! $d->{target_node_rel} )
	{	populate_lookup_hashes({ graph_data => $d });
	}
	
	# only connected to one node: must be the closest!
	if (scalar keys %{$d->{node_target_rel}{$id}} == 1)
	{	# we specified a relation
		if ($rel_wanted)
		{	return [ map { { node => $id, rel => $rel_wanted, target => $_ } } keys %{$d->{node_target_rel}{$id}} ];
		}
		else
		{	my $target = (keys %{$d->{node_target_rel}{$id}})[0];
			return [ map { { node => $id, rel => $_, target => $target } } keys %{$d->{node_target_rel}{$id}{$target}} ];
		}
	}

	my $new_d;
	foreach my $rel (keys %{$d->{node_rel_target}{$id}})
	{	next if $rel_wanted && $rel ne $rel_wanted;

		#	list_by_rel contains all the nodes between it and the root(s) of $id
		my @list_by_rel = keys %{$d->{node_rel_target}{$id}{$rel}};

		REL_SLIMDOWN_LOOP:
		while (@list_by_rel)
		{	my $a = pop @list_by_rel;
			my @list2_by_rel = ();
			while (@list_by_rel)
			{	my $b = pop @list_by_rel;
				if ($d->{target_node_rel}{$a}{$b})
				{	#	b is node, a is target
					#	forget about a, go on to the next list item
					push @list_by_rel, $b;
					push @list_by_rel, @list2_by_rel if @list2_by_rel;
					next REL_SLIMDOWN_LOOP;
				}
				elsif ($d->{node_target_rel}{$a}{$b})
				{	#	a is node, b is target
					#	forget about b, look at the next in the list
					next;
				}
				else
				{	#a and b aren't related
					#	keep b
					push @list2_by_rel, $b;
					next;
				}
			}
			#	if a is still around, it must be a descendent of
			#	all the nodes we've looked at, so it can go on our
			#	descendent list
			push @$new_d, { node => $id, rel => $rel, target => $a };
#			$new_d->{graph}{$id}{$rel}{$a} = $d->{node_rel_target}{$id}{$rel}{$a};

			#	if we have a list2_by_rel, transfer it back to @list_by_rel
			push @list_by_rel, @list2_by_rel if @list2_by_rel;
		}
	}

	return $new_d;
}



=head2 get_furthest_ancestral_nodes

input:  graph_data => data hash with nodes and relations specified as
               {graph}{ node_id }{ relation_id }{ target_id }
               nb: must already have had all that reasoning stuff done
          plus various rearrangements, with a hash key specifying the ordering
          e.g. {node_target_rel}
               {target_node_rel}
        id        => id of node to find the closest ancestral node of
        relation  => relation id, if wanted
        options   => option_h

output: new data hash, slimmed down, with relations specified as
               {graph}{ node_id }{ relation_id }{ target_id }

For a given term, finds the furthest node[s]

=cut

sub get_furthest_ancestral_nodes {
	my $args = shift;
	my $d = $args->{graph_data};
	my $id = $args->{id};
	my $rel_wanted = $args->{relation} || undef;
	my $options = $args->{options};


	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $id && values %{$d->{graph}};

	# if there are no links whatsoever involving this term, report and return undef
	if (! $d->{graph}{$id} )
	{	print STDERR "No links from $id\n" if $options->{verbose};
		return undef;
	}

	if ( $rel_wanted )
	{	# if a relation is specified, but there are no relations involving this term
		# that match, return undef
		if ( ! values %{$d->{graph}{$id}{$rel_wanted}} )
		{	print STDERR "No $rel_wanted links from $id\n" if $options->{verbose};
			return undef;
		}
		# if it is only connected to one node by the relation, it must be the closest!
		elsif (scalar keys %{$d->{graph}{$id}{$rel_wanted}} == 1)
		{	return [ map { { node => $id, rel => $rel_wanted, target => $_ } } keys %{$d->{graph}{$id}{$rel_wanted}} ];
		}
	}

	# make sure the look up hashes are populated
	if (! $d->{node_rel_target} || ! $d->{target_node_rel} )
	{	populate_lookup_hashes({ graph_data => $d });
	}
	
	# only connected to one node: must be the closest!
	if (scalar keys %{$d->{node_target_rel}{$id}} == 1)
	{	# we specified a relation
		if ($rel_wanted)
		{	return [ map { { node => $id, rel => $rel_wanted, target => $_ } } keys %{$d->{node_target_rel}{$id}} ];
		}
		else
		{	my $target = (keys %{$d->{node_target_rel}{$id}})[0];
			return [ map { { node => $id, rel => $_, target => $target } } keys %{$d->{node_target_rel}{$id}{$target}} ];
		}
	}

	#TODO: add in a check for the root nodes
	


	my $new_d;
	foreach my $rel (keys %{$d->{node_rel_target}{$id}})
	{	next if $rel_wanted && $rel ne $rel_wanted;

		#	list_by_rel contains all the nodes between it and the root(s) of $id
		my @list_by_rel = keys %{$d->{node_rel_target}{$id}{$rel}};

		REL_SLIMDOWN_LOOP:
		while (@list_by_rel)
		{	my $a = pop @list_by_rel;
			my @list2_by_rel = ();
			while (@list_by_rel)
			{	my $b = pop @list_by_rel;
				if ($d->{target_node_rel}{$a}{$b})
				{	#	b is node, a is target
					#	forget about b, look at the next in the list
					next;
				}
				elsif ($d->{node_target_rel}{$a}{$b})
				{	#	a is node, b is target
					#	forget about a, go on to the next list item
					push @list_by_rel, $b;
					push @list_by_rel, @list2_by_rel if @list2_by_rel;
					next REL_SLIMDOWN_LOOP;
				}
				else
				{	#a and b aren't related
					#	keep b
					push @list2_by_rel, $b;
					next;
				}
			}
			#	if a is still around, it must be a descendent of
			#	all the nodes we've looked at, so it can go on our
			#	descendent list
			push @$new_d, { node => $id, rel => $rel, target => $a };
#			$new_d->{graph}{$id}{$rel}{$a} = $d->{node_rel_target}{$id}{$rel}{$a};

			#	if we have a list2_by_rel, transfer it back to @list_by_rel
			push @list_by_rel, @list2_by_rel if @list2_by_rel;
		}
	}

	return $new_d;
}


=head2 topological_sort

input:  graph_data => data hash with nodes and relations specified as
               {graph}{ node_id }{ relation_id }{ target_id }
               nb: must already have had all that reasoning stuff done
          plus various rearrangements, with a hash key specifying the ordering
          e.g. {node_target_rel}
               {target_node_rel}
        id        => id of node to do the topological sort on
        relation  => relation id, if wanted
        options   => option_h

output: topo sorted list

For a given term, finds the furthest node[s]

=cut

sub topological_sort {
	my $args = shift;
	my $d = $args->{graph_data};
	my $id = $args->{id};
#	my $rel_wanted = $args->{relation} || undef;
	my $options = $args->{options};

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $id && values %{$d->{graph}};

	if (! $d->{graph}{$id})
	{	print STDERR "$id is a root node... sob!\n";
		return;
	}
	
	my @sorted;   # Empty list that will contain the sorted nodes
	my @leafy;    # Set of all nodes with no incoming edges
=algorithm:
while leafy is non-empty do
	remove a node n from leafy
	insert n into sorted
	for each node m with an edge e from n to m do
		remove edge e from the graph
		if m has no other incoming edges then
			insert m into leafy
if graph has edges then
	output error message (graph has at least one cycle)
else 
	output message (proposed topologically sorted order: sorted)
=cut

#	print STDERR "input data: " . Dumper($d);

	@leafy = ( $id );
	my $graph;  # this will be all the nodes related to $id

	foreach my $r (keys %{$d->{graph}{$id}})
	{	foreach (keys %{$d->{graph}{$id}{$r}})
		{	$graph->{node_target}{$id}{$_} = 1;
			$graph->{target_node}{$_}{$id} = 1;
		}
	}

	## get all relations involving terms listed as keys in $graph->{target_node}
	foreach my $t (keys %{$graph->{target_node}})
	{	if ($d->{graph}{$t})
		{	foreach my $r (keys %{$d->{graph}{$t}})
			{	foreach (keys %{$d->{graph}{$t}{$r}})
				{	if ($graph->{target_node}{$_})
					{	$graph->{node_target}{$t}{$_} = 1;
						$graph->{target_node}{$_}{$t} = 1;
					}
				}
			}
		}
	}

	while (@leafy)
	{	my $n = pop @leafy;
		push @sorted, $n;
		if (defined $graph->{node_target}{$n} && defined values %{$graph->{node_target}{$n}})
		{	foreach my $m (keys %{$graph->{node_target}{$n}})
			{	undef $graph->{node_target}{$n}{$m};
				undef $graph->{target_node}{$m}{$n};

				my $none;
				if (defined $graph->{target_node}{$m} && defined values %{$graph->{target_node}{$m}})
				{	foreach (keys %{$graph->{target_node}{$m}})
					{	if (defined $graph->{target_node}{$m}{$_})
						{	$none++;
							last;
						}
					}
					if (! $none )
					{	push @leafy, $m;
					}
				}
			}
		}
	}

	return [ @sorted ];

}


## Graph cloning stuff ##


=head2 add_all_relations_to_graph

input:  old_g => old Graph object
        new_g => new Graph object (created if does not exist)
        no_rel_links => 1  if links should be NOT added (default is to add them)

output: new graph with relations from the old graph added

=cut

sub add_all_relations_to_graph {
	my $args = shift;
	my $old_g = $args->{old_g};
	my $new_g = $args->{new_g} || new GOBO::Graph; # if ! $new_g;
	my $no_rel_links = $args->{no_rel_links} || undef;

	confess( (caller(0))[3] . ": missing required argument old_g. Dying" ) unless $old_g && defined $new_g;

	sub check_for_relation {
		my ($graph, $r) = @_;
		return 1 if $r->id ne 'is_a' && ! $graph->get_relation($r);
		return;
	}

	if ($no_rel_links)
	{	$new_g->add_relation($old_g->noderef($_)) foreach @{$old_g->relations};
	}
	else
	{	# add all the relations from the other graph
		foreach (@{$old_g->relations})
		{	$new_g->add_relation($old_g->noderef($_)) if check_for_relation($new_g, $_);
	
			if ($old_g->get_outgoing_links($_))
			{	foreach (@{$old_g->get_outgoing_links($_)})
				{	
					$new_g->add_relation( $old_g->noderef( $_->relation ) ) if check_for_relation($new_g, $_->relation);
					$new_g->add_relation( $old_g->noderef( $_->target ) ) if check_for_relation($new_g, $_->target);
					
					$new_g->add_link( new GOBO::LinkStatement(
						node => $new_g->noderef($_->node),
						relation => $new_g->noderef($_->relation),
						target => $new_g->noderef($_->target)
					) );
				}
			}
		}
	}

	return $new_g;
}


=head2 add_all_terms_to_graph

input:  old_g => old Graph object
        new_g => new Graph object (created if does not exist)
        no_term_links => 1  if links between terms should NOT be added 
                            (default is to add them)
        no_rel_links  => 1  if links between relations should NOT be added
                            (default is to add them; only matters if no_term_links
                             has been specified)

output: new graph with terms from the old graph added

=cut

sub add_all_terms_to_graph {
	my $args = shift;
	my $old_g = $args->{old_g};
	my $new_g = $args->{new_g} || new GOBO::Graph; # if ! $new_g;
	my $no_term_links = $args->{no_term_links} || undef;

	confess( (caller(0))[3] . ": missing required argument old_g. Dying" ) unless $old_g && defined $new_g;

	if ($no_term_links)
	{	$new_g->add_term($old_g->noderef($_)) foreach @{$old_g->terms};
	}
	else
	{	# add all the relations from the other graph
		$new_g = add_all_relations_to_graph($args);

		foreach (@{$old_g->terms})
		{	$new_g->add_term($old_g->noderef($_));
			if ($old_g->get_outgoing_links($_))
			{	foreach (@{$old_g->get_outgoing_links($_)})
				{	# add the target term if it isn't there
					$new_g->add_term($old_g->noderef($_->target)) if ! $new_g->get_term($_->target);
					$new_g->add_link( new GOBO::LinkStatement(
						node => $new_g->noderef($_->node),
						relation => $new_g->noderef($_->relation),
						target => $new_g->noderef($_->target)
					) );
				}
			}
		}
	}
	
	return $new_g;
}


=head2 add_extra_stuff_to_graph

input:  old_g => old Graph object
        new_g => new Graph object (created if does not exist)

output: new graph with various attributes from the old graph added 

=cut

sub add_extra_stuff_to_graph {
	my $args = shift;
	my $old_g = $args->{old_g};
	my $new_g = $args->{new_g};

	$new_g = new GOBO::Graph if ! $new_g;

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $old_g && defined $new_g;

	foreach my $attrib qw( version source date comment declared_subsets property_value_map )
	{	$new_g->$attrib( $old_g->$attrib ) if $old_g->$attrib;
	}
	return $new_g;
}


=head2 add_nodes_and_links_to_graph

input:  graph_data => data hash with nodes and relations specified as
             { node_id }{ relation_id }{ target_id }
        old_g      => old graph, containing nodes and relations specified in the data hash
        new_g      => preferably the new graph, containing relations
                      (created if does not exist)

output: new graph, containing all the nodes and relations specified in 

=cut

sub add_nodes_and_links_to_graph {
	my $args = shift;
	my $graph_data = $args->{graph_data};
	my $old_g = $args->{old_g};
	my $new_g = $args->{new_g};

	$new_g = new GOBO::Graph if ! $new_g;

	confess( (caller(0))[3] . ": missing required arguments. Dying" ) unless $old_g && defined $new_g && $graph_data;

	## add the relations to the graph if absent
	if (! @{$new_g->relations} )
	{	$new_g = add_all_relations_to_graph($args);
	}

	# add the nodes to the graph
	foreach my $n ( keys %$graph_data )
	{	# add the nodes to the graph
		$new_g->add_term( $old_g->noderef( $n ) ) if ! $new_g->get_term($n);

		foreach my $r ( keys %{$graph_data->{$n}} )
		{	foreach my $t ( keys %{$graph_data->{$n}{$r}} )
			{	$new_g->add_term( $old_g->noderef( $t ) ) if ! $new_g->get_term($t);
				$new_g->add_link( new GOBO::LinkStatement(
					node => $new_g->noderef($n),
					relation => $new_g->noderef($r),
					target => $new_g->noderef($t)
				) );
			}
		}
	}
	return $new_g;
}


1;

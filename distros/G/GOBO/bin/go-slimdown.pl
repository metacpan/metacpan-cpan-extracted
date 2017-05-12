#!/usr/bin/perl -w
# find GO slim nodes and generate a graph based on them, removing any nodes not
# in the slim

use strict;
use FileHandle;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::InferenceEngine;
use GOBO::Writers::OBOWriter;

use GOBO::Util::GraphFunctions;

my $options = parse_options(\@ARGV);

if (! $options->{verbose})
{	$options->{verbose} = $ENV{GO_VERBOSE} || 0;
}

my $graph = GOBO::Util::GraphFunctions::get_graph({ options => $options });

# get the nodes matching our subset criteria
my $data = GOBO::Util::GraphFunctions::get_subset_nodes({ graph => $graph, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::get_subset_nodes!\n" if $options->{verbose};

# get the relations from the graph
$data->{relations} = GOBO::Util::GraphFunctions::get_graph_relations({ graph => $graph, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::get_graph_relations!\n" if $options->{verbose};

my $ie = new GOBO::InferenceEngine(graph => $graph);

foreach my $s (keys %{$data->{subset}})
{	# in these cases, the input set is the same as the mapping set. Copy 'em remorselessly!

	# get the links between the nodes
	$data->{nodes} = GOBO::Util::GraphFunctions::get_graph_links({ inf_eng => $ie, input => $data->{subset}{$s}, subset => $data->{subset}{$s}, graph => $graph, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::get_graph_links!\n" if $options->{verbose};

	# populate the node look up hashes
	GOBO::Util::GraphFunctions::populate_lookup_hashes({ graph_data => $data->{nodes} });
	print STDERR "Done GOBO::Util::GraphFunctions::populate_lookup_hashes!\n" if $options->{verbose};

	# remove redundant relationships between nodes
	GOBO::Util::GraphFunctions::remove_redundant_relationships({ node_data => $data->{nodes}, rel_data => $data->{relations}, graph => $graph, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::remove_redundant_relationships!\n" if $options->{verbose};

	# repopulate the node look up hashes
	GOBO::Util::GraphFunctions::populate_lookup_hashes({ graph_data => $data->{nodes} });
	print STDERR "Done GOBO::Util::GraphFunctions::populate_lookup_hashes!\n" if $options->{verbose};

	# slim down dem nodes
	my $slimmed = GOBO::Util::GraphFunctions::trim_graph({ graph_data => $data->{nodes}, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::trim_graph!\n" if $options->{verbose};

	my $new_graph = new GOBO::Graph;

	$new_graph = GOBO::Util::GraphFunctions::add_nodes_and_links_to_graph({ old_g => $graph, new_g => $new_graph, graph_data => $slimmed->{graph}, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::add_nodes_and_links_to_graph!\n" if $options->{verbose};

	$new_graph = GOBO::Util::GraphFunctions::add_extra_stuff_to_graph({ old_g => $graph, new_g => $new_graph, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::add_extra_stuff_to_graph!\n" if $options->{verbose};

	GOBO::Util::GraphFunctions::write_graph_to_file({ graph => $new_graph, subset => $s, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::write_graph_to_file!\n" if $options->{verbose};

}

print STDERR "Job complete!\n" if $options->{verbose};

exit(0);

# parse the options from the command line
sub parse_options {
	my $args = shift;
	
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
			$options->{verbose} = 1;
		}
		else {
			die "Error: no such option: $o\nThe help documentation can be accessed with the command 'go-slimdown.pl --help'\n";
		}
	}
	return check_options($opt);
}


## process the input params
sub check_options {
	my $opt = shift;
	my $errs;

	if (!$opt)
	{	die "Error: please ensure you have specified an input file, a subset, and an output file.\nThe help documentation can be accessed with the command 'go-slimdown.pl --help'\n";
	}

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

	return $opt;
}


=head1 NAME

go-slimdown.pl

=head1 SYNOPSIS

 go-slimdown.pl -i go/ontology/gene_ontology.obo -s goslim_generic -o slimmed.obo

=head1 DESCRIPTION

# must supply these arguments... or else!
# INPUT
 -i || --ontology /path/to/<file_name>   input file (ontology file) with path

# OUTPUT
 -o || --output /path/to/<file_name>     output file with path
  or
 -b || --basename /path/to/<file_name_containing_SLIM_NAME>

      specify a file name containing the text "SLIM_NAME", which will be
      substituted with the name of the subset
      e.g. -s goslim_goa -s goslim_yeast -b /temp/gene_ontology.SLIM_NAME.obo
      would produce two files,
      /temp/gene_ontology.goslim_goa.obo and /temp/gene_ontology.goslim_yeast.obo


# SUBSET
 -s || --subset <subset_name>            name of the subset to extract; multiple
                                         subsets can be specified
 or
 -a || --get_all_subsets                 extract all the subsets in the graph

# optional args
 -c || --combined                        if more than one subset is specified,
                                         create a slim using terms from all
                                         of the subsets specified

 -v || --verbose                         prints various messages

	Given a file where certain terms are specified as being in subset S, this
	script will 'slim down' the file by removing terms not in the subset.

	Relationships between remaining terms are calculated by the inference engine.

	If the root nodes are not already in the subset, they are added to the graph.

	The slimming algorithm is 'relationship-aware', and finds the closest node
	for each relation (rather than just the closest term). For example, if we
	had the following relationships:

	A -i- B -i- C -p- D

	the slimmer would say that B was the closest node via the 'i' relation, and
	D was the closest via the 'p' relation.

	Note that there may be several different relationships between the same two
	terms in the slimmed file.

=cut

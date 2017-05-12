#!/usr/bin/perl -w
# remap terms to their nearest and dearest GO slim terms

use strict;
use FileHandle;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use GOBO::Graph;
#use GOBO::Parsers::CustomParser;
use GOBO::Parsers::OBOParserDispatchHash;
use GOBO::InferenceEngine;
use GOBO::Writers::OBOWriter;
use GOBO::Util::GraphFunctions;

my $verbose = $ENV{GO_VERBOSE} || 0;

my $options = parse_options(\@ARGV);

=head1 NAME

mapmaker.pl

=head1 SYNOPSIS

 mapmaker.pl -i go/ontology/gene_ontology.obo -s goslim_generic -o my_stuff/mapping-file.txt

=head1 DESCRIPTION

# must supply these arguments... or else!
# INPUT
 -i || --ontology /path/to/<file_name>   input file (ontology file) with path


# SPECIFYING A SUBSET
 -s || --subset <subset_name>            name of the subset to extract
    or
 -t || --termfile /path/to/<file_name>   an input file containing a list of terms
 ## termfile option not yet implemented

# OUTPUT
 -o || --output /path/to/<file_name>     output file with path



#

# MISC SWITCHES
 -n || --show_names                      show term names in the mapping file

 -v || --verbose                         prints various messages


	Given a file where certain terms are specified as being in subset S, this
	script will produce a mapping of each term to its ancestors in subset S; the
	mapping indicates which ancestral terms are closest to the term.

	Relationships between terms are calculated by the inference engine.

	If the root nodes are not already in the subset, they are added to the graph.

	The slimming algorithm is 'relationship-aware', and finds the closest node
	for each relation (rather than just the closest term). For example, if we
	had the following relationships:

	A -i- B -i- C -p- D

	the slimmer would say that B was the closest node via the 'i' relation, and
	D was the closest via the 'p' relation.

	Note that there may be several different relationships between the same two
	terms in the slimmed file.

=item show_names

Show the names of the term in the slim mapping file

=head2 Output format

term ID(, term name [optional]) [tab] closest ancestral subset terms for each relationship [tab] all other ancestral terms

some sample lines:

GO:0000942, outer kinetochore of condensed nuclear chromosome	is_a GO:0005575; part_of GO:0005634, part_of GO:0005694	part_of GO:0005575
GO:0000943, retrotransposon nucleocapsid	is_a GO:0005575; part_of GO:0005634	part_of GO:0005575
GO:0001400, mating projection base	is_a GO:0005575; part_of GO:0005575	
GO:0001401, mitochondrial sorting and assembly machinery complex	is_a GO:0005575; part_of GO:0005740, part_of GO:0016020	part_of GO:0005575, part_of GO:0005737, part_of GO:0005739
GO:0001405, presequence translocase-associated import motor	is_a GO:0005575; part_of GO:0005740, part_of GO:0016020	part_of GO:0005575, part_of GO:0005737, part_of GO:0005739
GO:0001411, hyphal tip	is_a GO:0030427; part_of GO:0005575	is_a GO:0005575
GO:0001518, voltage-gated sodium channel complex	is_a GO:0005575; part_of GO:0005886	part_of GO:0005575, part_of GO:0016020
GO:0001520, outer dense fiber	is_a GO:0005575; part_of GO:0005575	
GO:0001527, microfibril	is_a GO:0005575; part_of GO:0005576	part_of GO:0005575
GO:0001529, elastin	obsolete

=cut

#=item -b B<bucket slim file>
#
#This argument adds B<bucket terms> to the slim ontology; see the
#documentation below for an explanation. The new slim ontology file,
#including bucket terms will be written to B<bucket slim file>
#

my $output = new FileHandle($options->{output}, "w") or die "Could not create output file " . $options->{output} . ": $!";

# parse the input file and check we get a graph
my $parser = new GOBO::Parsers::OBOParserDispatchHash(file=>$options->{input}, 
options => { 
	body => { 
		term => { name => 1, namespace => 1, relation => 1, is_a => 1, subset => 1, is_obsolete => 1, }, 
		typedef => { '*' => 1 },
	}, 
});
$parser->parse;

die "Error: parser could not find a graph in " . $options->{input} . "!\n" unless $parser->graph;
print STDERR "Finished parsing file " . $options->{input} . "\n" if $verbose;

my $graph = GOBO::Util::GraphFunctions::get_graph({ options => $options });

# get the nodes matching our subset criteria
my $data;
my $subset;

if ($options->{subset})
{	$data = GOBO::Util::GraphFunctions::get_subset_nodes({ graph => $graph, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::get_subset_nodes!\n" if $options->{verbose};

	# move the subset to 
	foreach my $s (keys %{$data->{subset}})
	{	$subset = $data->{subset}{$s};
	}
}

# get the relations from the graph
$data->{relations} = GOBO::Util::GraphFunctions::get_graph_relations({ graph => $graph, options => $options });
	print STDERR "Done GOBO::Util::GraphFunctions::get_graph_relations!\n" if $options->{verbose};

my $ie = new GOBO::InferenceEngine(graph => $graph);

# get the links between the nodes
$data->{nodes} = GOBO::Util::GraphFunctions::get_graph_links({ inf_eng => $ie, subset => $subset, graph => $graph, options => $options });
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

foreach my $n (keys %{$slimmed->{graph}})
{	foreach my $r (keys %{$slimmed->{graph}{$n}})
	{	map { $slimmed->{termlist}{$_} = 1 } keys %{$slimmed->{graph}{$n}{$r}};
		$slimmed->{rel_list}{$r} = 1;
	}
	$slimmed->{termlist}{$n} = 1;
}


## we are ready to output the data now! woohoo.
## print out the file header material

if ($options->{subset})
{	print $output "! Mapping file of terms to subset " . join(", ", keys %{$options->{subset}}) . "\n"
}
else
{	print $output "! Mapping file of terms to user subset\n";
}

# file name, data, etc..
my $fname = $options->{input};
my @f_data;

my $slash = rindex $options->{input}, "/";
if ($slash > -1)
{	push @f_data, substr $options->{input}, ++$slash;
}
else
{	push @f_data, $options->{input};
}

if ($graph->version)
{	push @f_data, "data version: " . $graph->version;
}
if ($graph->date)
{	push @f_data, "date: " . $graph->date;
}
if ($graph->comment)
{	if ($graph->comment =~ /cvs version: \$Revision:\s*(\S+)/)
	{	push @f_data, "CVS revision: " . $1;
	}
}

print $output "! Generated from " . join("; ", @f_data) . "\n";

my $print_term = sub {
	return shift;
};

if ($options->{show_names})
{	$print_term = sub {
		my ($id, $g) = @_;
		my $t = $g->get_term($id);
		return $t->id . ", " . $t->label;
	};
}

## OK, let's print dem terms.

foreach my $id (sort map { $_->id } @{$parser->graph->terms})
{	if (! $slimmed->{termlist}{$id})
	{	my $term = $parser->graph->get_term($id);
		if ($term->obsolete)
		{	print $output $print_term->($id, $parser->graph) . "\tobsolete\n";
		}
		else
		{	warn $print_term->($id, $parser->graph) . ": term lost!\n";
		}
		next;
	}

	print $output $print_term->($id, $parser->graph)
	. "\t" .
	join("; ", 
		map { 
			my $r1 = $_;
			join(", ",  map { "$r1 $_" } sort keys %{$slimmed->{graph}{$id}{$r1}})
		} sort keys %{$slimmed->{graph}{$id}}
		)
	. "\t" .
	join("; ", 
		grep { /\S/ }
		map { 
			my $r2 = $_;
			join(", ",
				map { "$r2 $_" } 
				grep { ! $slimmed->{graph}{$id}{$r2}{$_} } 
				sort keys %{$data->{nodes}{graph}{$id}{$r2}}
			)
		} sort keys %{$data->{nodes}{graph}{$id}})
	. "\n";

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
#		elsif ($o eq '-t' || $o eq '--termlist') {
#			## this should be the name of a file with a list of terms
#			$opt->{termlist} = shift @$args if @$args && $args->[0] !~ /^\-/;
#		}
		elsif ($o eq '-o' || $o eq '--output') {
			$opt->{output} = shift @$args if @$args && $args->[0] !~ /^\-/;
		}
#		elsif ($o eq '-b' || $o eq '--buckets') {
#			$opt->{buckets} = 1;
#		}
		elsif ($o eq '-n' || $o eq '--show_names') {
			$opt->{show_names} = 1;
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

	if (!$opt->{subset} && !$opt->{termlist}) # && !$opt->{subset_regexp})
	{	push @$errs, "specify a subset using -s <subset_name> or a file containing a list of terms using -t /path/to/<file_name>";
	}
	else
	{	if ($opt->{subset} && $opt->{termlist})
		{	push @$errs, "specify *either* named subset(s) ( '-s <subset_name>' )\n*or* a file containing a list of terms ( '-t' )";
		}
		
		if ($opt->{termlist})
		{	# check the term list exists
			if (! -e $opt->{termlist})
			{	push @$errs, "the file " . $opt->{termlist} . " could not be found.";
			}
		}

		if (scalar keys %{$opt->{subset}} > 1)
		{	# only one subset can be used. sorry!
			my $ss;
			foreach my $k (sort keys %{$opt->{subset}})
			{	$ss = $k;
				last;
			}
			warn "More than one subset was specified; using $ss";
			$opt->{subset} = { $ss => 1 };

		}
	}

	if (!$opt->{output})
	{	push @$errs, "specify an output file using -o /path/to/<file_name>";
	}


	if ($errs && @$errs)
	{	die "Error: please correct the following parameters to run the script:\n" . ( join("\n", map { " - " . $_ } @$errs ) ) . "\nThe help documentation can be accessed with the command\n\tgo-slimdown.pl --help\n";
	}

	return $opt;
}


sub get_subset_terms {
	my $sub_h;  # we'll store the data in here
	my $options = shift;

	# either an existing subset or a subset matching a regexp
	if ( $options->{subset} || $options->{subset_regexp} )
	{	## read in the OBO file and quickly pull out the slim terms
		open(IN, '<'.$options->{input}) or die "The file ".$options->{input}." could not be opened: $!\nDying";
		print "Loading " . $options->{input} . "...\n" if $options->{verbose};
		local $/ = "\n\n";
		my $sub_test;
	
#		if ($options->{subset_regexp})
#		{	$sub_test = sub {
#				my $block = shift;
#				if (/^\[Term\].*?^id: (.+?)$/sm)
#				{	my $id = $1;
#					foreach ( split("\n", $block) )
#					{	next unless /^subset: (.+)/;
#						$sub_h->{$id}++ if $1 =~ /$options->{subset_regexp}/;
#					}
#				}
#			};
#		}
#		else
#		{	
			$sub_test = sub {
				my $block = shift;
				if (/^\[Term\].*?^id: (.+?)$/sm)
				{	my $id = $1;
					foreach ( split("\n", $block) )
					{	next unless /^subset: (.+)/;
						$sub_h->{$id}++ if $options->{subset}{$1};
					}
				}
			};
#		}
		
		while (<IN>)
		{	&$sub_test($_) if /^subset: /sm;
		}
		print "Finished loading ontology.\n";
		close(IN);
		return { subset => $sub_h };
	}
	else
	{	# see if we have an OBO file...
		if ($options->{termlist} =~ /\.obo$/)
		{	# looks like it! read in the file and get the term nodes
			## read in the OBO file and quickly pull out the slim terms
			open(IN, '<'.$options->{termlist}) or die "The file ".$options->{termlist}." could not be opened: $!\nDying";
			print "Loading " . $options->{termlist} . "...\n" if $options->{verbose};
			local $/ = "\n\n";
			while (<IN>)
			{	if (/^[Term].*?^id: (.+)$/sm) {
					$sub_h->{$1}++;
				}
			}
			print "Finished loading ontology.\n" if $options->{verbose};
			close(IN);
			return { subset => $sub_h };
		}
		else
		{	# this is a file of unknown origin
			open(IN, '<'.$options->{termlist}) or die "The file ".$options->{termlist}." could not be opened: $!\nDying";
			print "Loading " . $options->{termlist} . "...\n" if $options->{verbose};
			my $regexp = $options->{term_regexp} || qr/^\s*\S+[\s$]/;
			while (<IN>)
			{	if (/($regexp)/)
				{	my $x = $1;
					$x =~ s/^\s*//;
					$x =~ s/\s*$//;
					$sub_h->{$x}++;
				}
			}
			print "Finished loading ontology.\n" if $options->{verbose};
			close(IN);
			return { subset => $sub_h };
		}
	}
}


## print out header material for file
sub print_file_header {
	my $options = shift;
	




}

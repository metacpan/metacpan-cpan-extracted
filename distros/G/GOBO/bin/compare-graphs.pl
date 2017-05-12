#!/usr/bin/perl -w
# find GO slim nodes and generate a graph based on them, removing any nodes not
# in the slim

=head1 NAME

compare-graphs.pl

=head1 SYNOPSIS

 compare-graphs.pl --file_1 go/ontology/old_gene_ontology.obo --file_2 go/ontology/gene_ontology.obo -s goslim_generic -o results.txt

=head1 DESCRIPTION

# must supply these arguments... or else!
# INPUT
 -f1 || --file_1 /path/to/<file_name>     "old" ontology file 
 -f2 || --file_2 /path/to/<file_2_name>   "new" ontology file

# OUTPUT
 -o || --output /path/to/<file_name>     output file for results

# SUBSET
 -s || --subset <subset_name>            subset to use for graph-based comparisons


# optional args

 -v || --verbose                         prints various messages


Compares two OBO files and records the differences between them. These
differences include:

* new terms
* term merges
* term obsoletions
* changes to term content, such as addition, removal or editing of features like
  synonyms, xrefs, comments, def, etc..
* term movements into or out of the subset designated by the subset option


At present, only term differences are recorded in detail, although this could
presumably be extended to other stanza types in an ontology file. The comparison
is based on creating hashes of term stanza data, mainly because hashes are more
tractable than objects. 

=cut


use strict;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use GOBO::Graph;
use GOBO::Parsers::OBOParserDispatchHash;
use GOBO::InferenceEngine;
use GOBO::Util::GraphFunctions;

my $options = parse_options(\@ARGV);

# check verbosity
if (! defined $options->{verbose})
{	$options->{verbose} = $ENV{GO_VERBOSE} || 0;
}

my $data;
my $parser;
my $ss = $options->{subset};
my @tags_to_parse = qw(name is_a relationship subset);
my $regex = '^(' . join("|", @tags_to_parse) . '):\s*';
$regex = qr/$regex/;

my $output_fh = new FileHandle($options->{output}, "w");
if (! defined $output_fh)
{	die "Could not create the file " . $options->{output} . ": $!";
}

#use Time::HiRes qw(gettimeofday);
#my $start_time = gettimeofday;

foreach my $f ('f1', 'f2')
{	
	## let's quickly get the ontology data and do a big ass comparison that way
	local $/ = "\n[";
	$parser = new GOBO::Parsers::OBOParserDispatchHash;
	
#	print STDERR "Ready to read in $f!\n";
	open(FH, "<" . $options->{$f}) or die("Could not open " . $options->{$f} . "! $!");

	# remove and parse the header
	my @arr = split("\n", <FH> );
	$data->{$f}{header} = tag_val_arr_to_hash( \@arr );
	$data->{$f}{graph} = $parser->parse_header_from_array({ array => [@arr] });

	print STDERR "Parsed $f header; starting body\n" if $options->{verbose};
	my @lines;
	while (<FH>)
	{	if (/^(\S+)\]\s*.*?^id:\s*(\S+)/sm)
		{	# store the data as a sorted array indexed by stanza type and id
			$data->{$f}{$1}{$2} = block_to_sorted_array($_);

			# and also as a tag-value hash
			$data->{$f . "_hash"}{$1}{$2} = tag_val_arr_to_hash( $data->{$f}{$1}{$2} );

			# save alt_ids
			if ($1 eq 'Term' && $data->{$f . "_hash"}{Term}{$2}{alt_id})
			{	# check for dodgy alt ids...
				
				map { 
					if ($data->{$f . "_alt_ids"}{$_} )
					{	warn "$2: alt_id $_ is already assigned to " . $data->{$f . "_alt_ids"}{$_};
					}
					else
					{	$data->{$f . "_alt_ids"}{$_} = $2;
					}
				} @{$data->{$f . "_hash"}{Term}{$2}{alt_id}};
			}

			# extract the interesting data and add it to the graph
			# skip obsoletes
			next if $data->{$f . "_hash"}{$1}{$2}{is_obsolete};
			if ($1 eq 'Term')
			{	push @lines, ( "[$1]", "id: $2", grep { /$regex/ } @{$data->{$f}{$1}{$2}} );
			}
			elsif ($1 eq 'Typedef')
			{	push @lines, ("[$1]", "id: $2", @{$data->{$f}{$1}{$2}});
			}
		}
		else
		{	print STDERR "Couldn't understand data!\n";
		}
	}
	
	$data->{$f}{graph} = $parser->parse_body_from_array({ graph => $data->{$f}{graph}, array => [ @lines ] }) if $ss;
	print STDERR "Finished parsing $f body\n" if $options->{verbose};
	close FH;
}


#my $end_time = gettimeofday;
#print STDERR "took " . ($end_time - $start_time) . " secs to complete\n";

## ANALYSIS STAGE! ##


# ignore these tags when we're comparing hashes
my @tags_to_ignore = qw(id is_a relationship);
my $ignore_regex = '(' . join("|", @tags_to_ignore) . ')';
$ignore_regex = qr/$ignore_regex/;


## ok, check through the terms and compare 'em
foreach my $t (keys %{$data->{f1}{Term}})
{	## get stuff for stats
	$data->{f1_stats}{total}{ ($data->{f1_hash}{Term}{$t}{namespace}[0] || 'unknown') }++;
	$data->{f1_stats}{n_defined}{ ($data->{f1_hash}{Term}{$t}{namespace}[0] || 'unknown') }++ if $data->{f1_hash}{Term}{$t}{def};
	$data->{f1_stats}{is_obsolete}{ ($data->{f1_hash}{Term}{$t}{namespace}[0] || 'unknown') }++ if $data->{f1_hash}{Term}{$t}{is_obsolete};
	$data->{f1_stats}{def_not_obs}{ ($data->{f1_hash}{Term}{$t}{namespace}[0] || 'unknown') }++ if $data->{f1_hash}{Term}{$t}{def} && ! $data->{f1_hash}{Term}{$t}{is_obsolete};

	if (! $data->{f2}{Term}{$t})
	{	# check it hasn't been merged
		if ($data->{f2_alt_ids}{$t})
		{	# the term was merged. N'mind!
#			print STDERR "$t was merged into " . $data->{f2_alt_ids}{$t} . "\n";
			$data->{f1_to_f2_merge}{$t} = $data->{f2_alt_ids}{$t};
		}
		else
		{	warn "$t is only in file 1\n";
			$data->{diffs}{Term}{f1_only}{$t}++;
		}
	}
	else
	{	# quickly compare the arrays, see if they are the same
		next if join("\0", @{$data->{f1}{Term}{$t}}) eq join("\0", @{$data->{f2}{Term}{$t}});

		my $r = compare_hashes({ f1 => $data->{f1_hash}{Term}{$t}, f2 => $data->{f2_hash}{Term}{$t}, regex => $ignore_regex });
		if ($r)
		{	$data->{diffs}{Term}{both}{$t} = $r;
			foreach (keys %$r)
			{	$data->{diffs}{Term}{all_tags_used}{$_}++;
			}
		}
	}

#	# map the subsets
#	if ($data->{f1_hash}{Term}{$t}{subset} && grep { $options->{subset} eq $_ }  @{$data->{f1_hash}{Term}{$t}{subset}} )
#		$data->{f1_hash}{subset}{ $options->{subset} }{$t} = 1;
#	}

}

#print STDERR "data->diffs->term->all_tags_used: " . Dumper($data->{diffs}{Term}{all_tags_used});

foreach my $t (keys %{$data->{f2}{Term}})
{	if (! $data->{f1}{Term}{$t})
	{	# check it hasn't been de-merged
		if ($data->{f1_alt_ids}{$t})
		{	# erk! it was an alt id... what's going on?!
			warn "$t was an alt id for " . $data->{f1_alt_ids}{$t} . " but it has been de-merged!";
			$data->{f2_to_f1_merge}{$t} = $data->{f1_alt_ids}{$t};
		}
		else
		{	$data->{diffs}{Term}{f2_only}{$t}++;
		}
	}
	
	## get stuff for stats
	$data->{f2_stats}{total}{ ($data->{f2_hash}{Term}{$t}{namespace}[0] || 'unknown') }++;
	$data->{f2_stats}{n_defined}{ ($data->{f2_hash}{Term}{$t}{namespace}[0] || 'unknown') }++ if $data->{f2_hash}{Term}{$t}{def};
	$data->{f2_stats}{is_obsolete}{ ($data->{f2_hash}{Term}{$t}{namespace}[0] || 'unknown') }++ if $data->{f2_hash}{Term}{$t}{is_obsolete};
	$data->{f2_stats}{def_not_obs}{ ($data->{f2_hash}{Term}{$t}{namespace}[0] || 'unknown') }++ if $data->{f2_hash}{Term}{$t}{def} && ! $data->{f2_hash}{Term}{$t}{is_obsolete};

	
#	# map the subsets
#	if ($data->{f2_hash}{Term}{$t}{subset} && grep { $options->{subset} eq $_ }  @{$data->{f2_hash}{Term}{$t}{subset}} )
#	{	$data->{f2_hash}{subset}{ $options->{subset} }{$t} = 1;
#	}

}


## compare the other types of stanza
foreach my $type (keys %{$data->{f1_hash}})
{	next if $type eq 'Term';
	foreach my $t (keys %{$data->{f1}{$type}})
	{	
		if (! $data->{f2}{$type}{$t})
		{	# check it hasn't been merged
			if ($data->{f2_alt_ids}{$t})
			{	# the term was merged. N'mind!
	#			print STDERR "$t was merged into " . $data->{f2_alt_ids}{$t} . "\n";
				$data->{f1_to_f2_merge}{$t} = $data->{f2_alt_ids}{$t};
			}
			else
			{	warn "$type $t is only in file 1\n";
				$data->{diffs}{$type}{f1_only}{$t}++;
			}
		}
		else
		{	# quickly compare the arrays, see if they are the same
#			print STDERR "f1: " . Dumper($data->{f1}{$type}{$t}) . "\nf2: " . Dumper($data->{f2}{$type}{$t}) . "\n\n";
			next if join("\0", @{$data->{f1}{$type}{$t}}) eq join("\0", @{$data->{f2}{$type}{$t}});
	
			my $r = compare_hashes({ f1 => $data->{f1_hash}{$type}{$t}, f2 => $data->{f2_hash}{$type}{$t}, regex => qr/id/ });
			if ($r)
			{	$data->{diffs}{$type}{both}{$t} = $r;
				foreach (keys %$r)
				{	$data->{diffs}{$type}{all_tags_used}{$_}++;
				}
			}
		}
	}

	#print STDERR "data->diffs->term->all_tags_used: " . Dumper($data->{diffs}{Typedef}{all_tags_used});
	
	foreach my $t (keys %{$data->{f2_hash}{$type}})
	{	if (! $data->{f1}{$type}{$t})
		{	# check it hasn't been de-merged
			if ($data->{f1_alt_ids}{$t})
			{	# erk! it was an alt id... what's going on?!
				warn "$t was an alt id for " . $data->{f1_alt_ids}{$t} . " but it has been de-merged!";
				$data->{f2_to_f1_merge}{$t} = $data->{f1_alt_ids}{$t};
			}
			else
			{	$data->{diffs}{$type}{f2_only}{$t}++;
			}
		}
	}
	
	
#	print STDERR "differences hash: " . Dumper($data->{diffs}{$type}) . "\n\n";

}


if ($ss)
{	
	print STDERR "Starting subset analysis of subset links...\n" if $options->{verbose};
	# g1 and g2 should contain enough info to generate the slimming graph
	# get the terms in the subset for g1 and g2
	$data->{g1_subset} = GOBO::Util::GraphFunctions::get_subset_nodes({ graph => $data->{f1}{graph}, options => { subset => { $ss => 1 } } });
	$data->{g2_subset} = GOBO::Util::GraphFunctions::get_subset_nodes({ graph => $data->{f2}{graph}, options => { subset => { $ss => 1 } } });
	
	# get link data for the terms
	$data->{g1_link_data} = GOBO::Util::GraphFunctions::get_graph_links({ graph => $data->{f1}{graph}, subset => $data->{g1_subset}{subset}{ $ss }, options => $options });
	$data->{g2_link_data} = GOBO::Util::GraphFunctions::get_graph_links({ graph => $data->{f2}{graph}, subset => $data->{g2_subset}{subset}{ $ss }, options => $options });
	
	$data->{g1_link_data_slimmed} = GOBO::Util::GraphFunctions::trim_graph({ graph_data => $data->{g1_link_data} });
	
	$data->{g2_link_data_slimmed} = GOBO::Util::GraphFunctions::trim_graph({ graph_data => $data->{g2_link_data} });
	
	## go through the terms in g1 and g2, and find out if any terms have moved
	## let's populate us some look up hashes
	GOBO::Util::GraphFunctions::populate_lookup_hashes({ graph_data => $data->{g1_link_data_slimmed} });
	GOBO::Util::GraphFunctions::populate_lookup_hashes({ graph_data => $data->{g2_link_data_slimmed} });
	
	# go through the g2 subset terms and compare the data to that we got from g1
	foreach my $t (keys %{ $data->{g2_subset}{subset}{ $ss }})
	{	
		my $count;
		if (! $data->{g1_subset}{subset}{$ss}{$t})
		{	# $t is a new subset term in f2
#			print STDERR "$t is a new subset term in g2\n";
			push @{$data->{new_in_g2_subset}}, $t;
		}
		else
		{	if ($data->{g1_link_data_slimmed}{target_node_rel}{$t})
			{	# links from target $t in the graph for f1
				foreach my $n (keys %{$data->{g1_link_data_slimmed}{target_node_rel}{$t}})
				{	$count->{$n}++;
				}
			}
			else
			{	warn "No links in f1 involving subset term $t" if $options->{verbose};
			}
		}
		
		if ($data->{g2_link_data_slimmed}{target_node_rel}{$t})
		{	# links from target $t in the graph for f2
			foreach my $n (keys %{$data->{g2_link_data_slimmed}{target_node_rel}{$t}})
			{	$count->{$n}+= 10;
			}
		}
		else
		{	warn "No links in f2 involving subset term $t" if $options->{verbose};
		}
	
		foreach my $e (keys %$count) {
			next if $count->{$e} == 11;
			if ($count->{$e} == 1)
			{	# term has been removed from $ss
				$data->{subset_movements}{$t}{out}{$e} = 1;
			}
			elsif ($count->{$e} == 10)
			{	# term has been added to $ss
				$data->{subset_movements}{$t}{in}{$e} = 1;
			}
		}
	}
	
	
	# go through the g2 subset terms and compare the data to that we got from g1
	foreach my $t (keys %{ $data->{g1_subset}{subset}{ $ss }})
	{	if (! $data->{g2_subset}{subset}{$ss}{$t})
		{	# $t is no longer a subset term
		#	print STDERR "$t is no longer a subset term in g2\n";
			push @{$data->{removed_from_g2_subset}}, $t;
		}
	}
	print STDERR "Finished subset analysis\n" if $options->{verbose};
	
=cut
	my $pairs;
	
	foreach my $t (keys %{$data->{g1_link_data_slimmed}{target_node_rel}})
	{	foreach my $n (keys %{$data->{g1_link_data_slimmed}{target_node_rel}{$t}})
		{	push @$pairs, "$t $n";
		}
	}
	
	
	print STDERR "\n\n\ng1 data:\n";
	print STDERR join("\n", sort @$pairs) . "\n\n";
	undef @$pairs;
	
	foreach my $t (keys %{$data->{g2_link_data_slimmed}{target_node_rel}})
	{	foreach my $n (keys %{$data->{g2_link_data_slimmed}{target_node_rel}{$t}})
		{	push @$pairs, "$t $n";
		}
	}
	print STDERR "\n\n\ng2 data:\n";
	print STDERR join("\n", sort @$pairs) . "\n\n";
	
	
	print STDERR "subset movements: " . Dumper($data->{subset_movements})."\n";
=cut
}

print STDERR "Printing results!\n" if $options->{verbose};


#print STDERR "file 1 alt_ids: " . Dumper($data->{f1_alt_ids}) . "file 2 alt_ids: " . Dumper($data->{f2_alt_ids}) . "\n\n";

print_header($output_fh, $data, $options);

print_new_terms($output_fh, $data);

print_new_obsoletes($output_fh, $data);

print_new_merges($output_fh, $data);

print_term_name_changes($output_fh, $data);

print_subset_changes($output_fh, $data) if $ss;

print_term_changes($output_fh, $data);

print_stanza_changes($output_fh, $data);

print_errors($output_fh, $data);

print_stats($output_fh, $data);

exit(0);




# parse the options from the command line
sub parse_options {
	my $args = shift;
	
	my $opt;
	
	while (@$args && $args->[0] =~ /^\-/) {
		my $o = shift @$args;
		if ($o eq '-f1' || $o eq '--file_1' || $o eq '--file_one') {
			if (@$args && $args->[0] !~ /^\-/)
			{	$opt->{f1} = shift @$args;
			}
		}
		elsif ($o eq '-f2' || $o eq '--file_2' || $o eq '--file_two') {
			if (@$args && $args->[0] !~ /^\-/)
			{	$opt->{f2} = shift @$args;
			}
		}
		elsif ($o eq '-s' || $o eq '--subset') {
			while (@$args && $args->[0] !~ /^\-/)
			{	my $s = shift @$args;
				$opt->{subset} = $s;
			}
		}
		elsif ($o eq '-o' || $o eq '--output') {
			$opt->{output} = shift @$args if @$args && $args->[0] !~ /^\-/;
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
	return check_options($opt);
}


# process the input params
sub check_options {
	my $opt = shift;
	my $errs;

	if (!$opt)
	{	die "Error: please ensure you have specified an input file, a subset, and an output file.\nThe help documentation can be accessed with the command 'go-slimdown.pl --help'\n";
	}

	if (!$opt->{f1})
	{	push @$errs, "specify an input file using -i /path/to/<file_name>";
	}
	elsif (! -e $opt->{f1})
	{	push @$errs, "the file " . $opt->{f1} . " could not be found.\n";
	}

	if (!$opt->{f2})
	{	push @$errs, "specify an input file using -i /path/to/<file_name>";
	}
	elsif (! -e $opt->{f2})
	{	push @$errs, "the file " . $opt->{f2} . " could not be found.\n";
	}

	if (!$opt->{output})
	{	push @$errs, "specify an output file using -o /path/to/<file_name>";
	}

	if (!$opt->{subset})
	{	push @$errs, "specify a subset using -s <subset_name>";
	}


	if ($errs && @$errs)
	{	die "Error: please correct the following parameters to run the script:\n" . ( join("\n", map { " - " . $_ } @$errs ) ) . "\nThe help documentation can be accessed with the command\n\tgo-slimdown.pl --help\n";
	}

	return $opt;
}


# print the header for the Monthly Report
sub print_header {
	my $fh = shift;
	my $data = shift;
	my $args = shift;
	my $f_text = {
		f1 => 'file 1 (old): ',
		f2 => 'file 2 (new): ',
	};

	print $fh "Ontology Comparison Report\n==========================\n\nFiles used:\n";
	foreach my $f ("f1", "f2")
	{	my @f_data;
		my $header = $data->{$f}{"header"};
#		print STDERR "file $f header: " . Dumper($header);
	#	($header->{name} = $args->{$f}) =~ s/.+\///;
		my $slash = rindex $args->{$f}, "/";
		if ($slash > -1)
		{	push @f_data, substr $args->{$f}, ++$slash;
		}
		else
		{	push @f_data, $args->{$f};
		}

		if ($header->{"data-version"})
		{	push @f_data, "data version: " . $header->{"data-version"}[0];
		}
		if ($header->{date})
		{	push @f_data, "date: " . $header->{date}[0];
		}
		if ($header->{remark})
		{	foreach (@{$header->{remark}})
			{	if (/cvs version: \$Revision:\s*(\S+)/)
				{	push @f_data, "CVS revision: " . $1;
					last;
				}
			}
		}
		
		print $fh $f_text->{$f};
		
		if (@f_data)
		{	print $fh join("; ", @f_data) . "\n";
		}
		else
		{	print $fh "unknown\n";
		}
	}
	
	if ($args->{subset})
	{	print $fh "subset: " . $args->{subset} . "\n";
	}
	
	print $fh "\n\n";
}


sub print_summary {
	my $fh = shift;
	my $data = shift;

	## number of new terms

#	if ( $data->{diffs}{Term}{f2_only} && keys %{$data->{diffs}{Term}{f2_only}})
#	{	print $fh scalar keys %{$data->{diffs}{Term}{f2_only}} . " new terms\n";
#	}

	## number of merges

	## number of obsoletions
	
}


sub print_stats {
	my $fh = shift;
	my $data = shift;
	
	print $fh "\nFile Stats (for the new file)\n==========\n" . 
		join("\n", map { "$_: " . $data->{f2_stats}{total}{$_} . " terms ("
		. ( $data->{f2_stats}{n_defined}{$_} || '0') . " defined; "
		. ( $data->{f2_stats}{is_obsolete}{$_} || '0' ) . " obsolete)" } sort keys %{$data->{f2_stats}{total}}).
		"\n";

	my $grand_total;
	map { $grand_total->{total} += $data->{f2_stats}{total}{$_} } keys %{$data->{f2_stats}{total}};
	map { $grand_total->{n_defined} += $data->{f2_stats}{n_defined}{$_} } keys %{$data->{f2_stats}{n_defined}};
	map { $grand_total->{is_obsolete} += $data->{f2_stats}{is_obsolete}{$_} } keys %{$data->{f2_stats}{is_obsolete}};
	map { $grand_total->{def_not_obs} += $data->{f2_stats}{def_not_obs}{$_} } keys %{$data->{f2_stats}{def_not_obs}};

	foreach my $x qw(n_defined is_obsolete def_not_obs)
	{	if (! $grand_total->{$x})
		{	$grand_total->{$x} = "0";
			$grand_total->{$x . "_percent"} = "0";
			next;
		}
		$grand_total->{$x . "_percent"} = sprintf("%.1f", $grand_total->{$x} / $grand_total->{total} * 100);
	}


	print $fh "\ntotals: " . 
		$grand_total->{total} . " terms ("
		. $grand_total->{n_defined} . "/" . $grand_total->{n_defined_percent} . "% defined; "
		. $grand_total->{is_obsolete} . "/" . $grand_total->{is_obsolete_percent} . "% obsolete)"
		. "\n";
}


sub print_new_terms {
	my $fh = shift;
	my $data = shift;

#	print STDERR "diffs: " . Dumper($data->{diffs}{Term}) . "\n\n\n";
	
	print $fh "New terms\n=========\n";
	print $fh "KEY:columns are separated by tabs\nID\tname\tnamespace\tnearest GO slim parent terms\n\n";

	if ( $data->{diffs}{Term}{f2_only} && keys %{$data->{diffs}{Term}{f2_only}})
	{	foreach ( sort keys %{$data->{diffs}{Term}{f2_only}} )
		{	
			print $fh "$_\t" 
			. print_term_name($data, $_, 'f2', 1) . "\t" 
			. $data->{f2_hash}{Term}{$_}{namespace}[0] . "\t";
			if ($data->{f2_hash}{Term}{$_}{is_obsolete})
			{	print $fh "obsolete\t";
			}
			else
			{	# print the GS parents...
				my $t = $_;
				if ($data->{g2_link_data}{graph}{$t})
				{	
					my %parent_h;
					foreach my $r (keys %{$data->{g2_link_data_slimmed}{graph}{$t}})
					{	map { $parent_h{$_} = 1 } keys %{$data->{g2_link_data_slimmed}{graph}{$t}{$r}};
					}
					print $fh join(", ", sort keys %parent_h) . "\t";
				}
			}
			print $fh "\n";
		}
	}
	else
	{	print $fh "None\n";
	}
	print $fh "\n\n";
}


sub print_new_obsoletes {
	my $fh = shift;
	my $data = shift;

	print $fh "Obsoletions\n===========\n";

	my @obsoletes = grep {
		exists $data->{diffs}{Term}{both}{$_}{is_obsolete}
		&& exists $data->{diffs}{Term}{both}{$_}{is_obsolete}{f2}
	} keys %{$data->{diffs}{Term}{both}};

	my @new_obs = grep { exists $data->{f2_hash}{Term}{$_}{is_obsolete} } keys %{$data->{diffs}{Term}{f2_only}};

	if (@obsoletes || @new_obs)
	{	map { print $fh print_term_name($data, $_);
			if ($data->{f2_hash}{Term}{$_}{comment})
			{	(my $c = $data->{f2_hash}{Term}{$_}{comment}[0]) =~ s/This term was made obsolete because //;
				print $fh ": " . $c;
			}
		print $fh "\n" } sort @obsoletes;

		map { 
			print $fh print_term_name($data, $_);
			if ($data->{f2_hash}{Term}{$_}{comment})
			{	(my $c = $data->{f2_hash}{Term}{$_}{comment}[0]) =~ s/This term was made obsolete because //;
				print $fh ": " . $c;
			}
			print $fh "\n";
			} sort @new_obs;
	}
	else
	{	print $fh "None\n";
	}
	print $fh "\n\n";
	
}


sub print_new_merges {
	my $fh = shift;
	my $data = shift;

	print $fh "Term merges\n===========\n";
	if ($data->{f1_to_f2_merge})
	{	map { 
			print $fh "$_ was merged into "
			. print_term_name($data, $data->{f1_to_f2_merge}{$_}) . "\n";
		} keys %{$data->{f1_to_f2_merge}};
	}
	else
	{	print $fh "None\n";
	}
	print $fh "\n\n";
}


sub print_term_name_changes {
	my $fh = shift;
	my $data = shift;
	print $fh "Term name changes\n=================\n";
		
	my @name_changed = grep { exists $data->{diffs}{Term}{both}{$_}{name} } keys %{$data->{diffs}{Term}{both}};
	if (@name_changed)
	{	map { print $fh "$_: " 
			. print_term_name($data, $_, 'f1', 1)
			. " --> "
			. print_term_name($data, $_, 'f2', 1) 
			. "\n" } sort @name_changed;
	}
	else
	{	print $fh "None\n";
	}
	print $fh "\n\n";
}


sub print_term_def_changes {
	my $fh = shift;
	my $data = shift;

	print $fh "Term definition changes\n=======================\n";

	my @def_changed = grep { exists $data->{diffs}{Term}{both}{$_}{def} } keys %{$data->{diffs}{Term}{both}};
	if (@def_changed)
	{	map { 
			if ($data->{diffs}{Term}{both}{$_}{def}{f1} && $data->{diffs}{Term}{both}{$_}{def}{f2})
			{	print $fh "changed\t" . print_term_name($data, $_) . "\n";
			}
			elsif ($data->{diffs}{Term}{both}{$_}{def}{f1})
			{	print $fh "removed\t" . print_term_name($data, $_) . "\n";
			}
			else
			{	print $fh "added\t" . print_term_name($data, $_) . "\n";
			}
		} sort @def_changed;
	}
	else
	{	print $fh "None\n";
	}
	print $fh "\n\n";
}


sub print_term_changes {
	my $fh = shift;
	my $data = shift;
	
	return unless $data->{diffs}{Term}{both};

	my @ordered_attribs = qw(id
	is_anonymous
	name
	namespace
	alt_id
	def
	comment
	subset
	synonym
	xref
	is_a
	intersection_of
	union_of
	disjoint_from
	relationship
	is_obsolete
	replaced_by
	consider);

#	print STDERR "all tags used: " . Dumper($data->{diffs}{Term}{all_tags_used}) . "\n";

	my @single_attribs = qw(comment def namespace is_anonymous name is_obsolete);

	my $ignore = '^(' . join("|", qw(id name is_obsolete alt_id) ) . ')$';
	$ignore = qr/$ignore/;

	my @attribs = grep { exists $data->{diffs}{Term}{all_tags_used}{$_} && $_ ne 'id' } @ordered_attribs;
	print $fh "Term changes\n============\n";

	if (! @attribs )
	{	# nothing to report!
		print $fh "None\n\n\n";
		return;
	}
	print $fh "KEY:  '+' : added, '-' : removed, '*' : changed\n\n";

	foreach my $t (sort keys %{$data->{diffs}{Term}{both}})
	{	my $line;
		foreach my $c (@attribs)
		{	if ($data->{diffs}{Term}{both}{$t}{$c})
			{	if (grep { /^$c$/ } @single_attribs)
				{	if ($data->{diffs}{Term}{both}{$t}{$c}{f1} && $data->{diffs}{Term}{both}{$t}{$c}{f2})
					{	# changed
						push @$line, "*$c";
					}
					elsif ($data->{diffs}{Term}{both}{$t}{$c}{f2})
					{	push @$line, "+$c";
					}
					elsif ($data->{diffs}{Term}{both}{$t}{$c}{f1})
					{	push @$line, "-$c";
					}
				}
				else # multiple attributes
				{	#push @$line, "$c: ";
					if ($data->{diffs}{Term}{both}{$t}{$c}{f1} && $data->{diffs}{Term}{both}{$t}{$c}{f2})
					{	my $net = $data->{diffs}{Term}{both}{$t}{$c}{f2} - $data->{diffs}{Term}{both}{$t}{$c}{f1};
						if ($net == 0)
						{	push @$line, "*" . $data->{diffs}{Term}{both}{$t}{$c}{f1} . " $c" . "(s)"; # . " [f1: " . $data->{diffs}{Term}{both}{$t}{$c}{f1} . ", f2: ". $data->{diffs}{Term}{both}{$t}{$c}{f2} . "]";
						}
						elsif ($net < 0)
						{	$net = 0 - $net;
							push @$line, "*" . $data->{diffs}{Term}{both}{$t}{$c}{f2} . ", -$net" . " $c" . "(s)"; # [f1: " . $data->{diffs}{Term}{both}{$t}{$c}{f1} . ", f2: ". $data->{diffs}{Term}{both}{$t}{$c}{f2} . "]";
						}
						elsif ($net > 1)
						{	push @$line, "+$net, *" . $data->{diffs}{Term}{both}{$t}{$c}{f1} . " $c" . "(s)"; # . " [f1: " . $data->{diffs}{Term}{both}{$t}{$c}{f1} . ", f2: ". $data->{diffs}{Term}{both}{$t}{$c}{f2} . "]";
						}
					}
					elsif ($data->{diffs}{Term}{both}{$t}{$c}{f1})
					{	push @$line, "-" . $data->{diffs}{Term}{both}{$t}{$c}{f1} . " $c" . "(s)";
					}
					elsif ($data->{diffs}{Term}{both}{$t}{$c}{f2})
					{	push @$line, "+" . $data->{diffs}{Term}{both}{$t}{$c}{f2} . " $c" . "(s)";
					}
				}
			}
		}
		if ($line)
		{	print $fh print_term_name($data, $t) . "\n" . join("; ", @$line) . "\n";
			#print STDERR print_term_name($data, $t) . "\n$line\n";
		}
	}
	print $fh "\n\n";
}


sub print_subset_changes {
	my $fh = shift;
	my $data = shift;

print $fh "Subset Changes\n==============\n";


	print $fh "\nSubset term alterations\n";
	if ($data->{new_in_g2_subset} || $data->{removed_from_g2_subset})
	{	print $fh "\n";
		if ($data->{new_in_g2_subset})
		{	print $fh
			join("\n", map { "+ " . print_term_name($data, $_) } sort @{$data->{new_in_g2_subset}} ) . "\n";
		}
		if ($data->{removed_from_g2_subset})
		{	print $fh
			join("\n", map { "- " . print_term_name($data, $_) } sort @{$data->{removed_from_g2_subset}} ) . "\n";
		}
	}
	else
	{	print $fh "None\n";
	}
	print $fh "\nTerm movement between subsets\n";

	if (! $data->{subset_movements})
	{	print $fh "None\n";
	}
	else
	{	foreach my $s (sort keys %{$data->{subset_movements}})
		{	print $fh "\nTerm movements under " . print_term_name($data, $s) . "\n";
			if ($data->{subset_movements}{$s}{out})
			{	map { print $fh "- " . print_term_name($data, $_) . "\n" } keys %{$data->{subset_movements}{$s}{out}};
			}
			if ($data->{subset_movements}{$s}{in})
			{	map { print $fh "+ " . print_term_name($data, $_) . "\n" } keys %{$data->{subset_movements}{$s}{in}};
			}
		}
	}
	print $fh "\n\n";
}


sub print_stanza_changes {
	my $fh = shift;
	my $data = shift;

	foreach my $type (%{$data->{diffs}})
	{	next if $type eq 'Term';
		
		if ( $data->{diffs}{$type}{f2_only} && keys %{$data->{diffs}{$type}{f2_only}})
		{	print $fh "New ".$type."s\n";
			foreach ( sort keys %{$data->{diffs}{$type}{f2_only}} )
			{	print $fh "$_";
				if ($data->{f2_hash}{$type}{$_}{name}[0])
				{	print $fh ", " . $data->{f2_hash}{$type}{$_}{name}[0];
				}
				print $fh "\n";
			}
			print $fh "\n\n";
		}


#			my @name_changed = grep { exists $data->{diffs}{$type}{both}{$_}{name} } keys %{$data->{diffs}{$type}{both}};
#			if (@name_changed)
#			{	print $fh "$type name changes\n";
	
#				map { print $fh "$_: " 
#					. $data->{f1_hash}{$type}{$_}{name}[0]
#					. " --> "
#					. $data->{f2_hash}{$type}{$_}{name}[0]
#					. "\n" } sort @name_changed;
#				print $fh "\n\n";
#			}


		if ($data->{diffs}{$type}{both})
		{	print $fh "$type changes\n";

			foreach my $t (sort keys %{$data->{diffs}{$type}{both}})
			{	my $line;
				foreach my $c (sort keys %{$data->{diffs}{$type}{both}{$t}})
				{	if ($data->{diffs}{$type}{both}{$t}{$c}{f1} && $data->{diffs}{$type}{both}{$t}{$c}{f2})
					{	my $net = $data->{diffs}{$type}{both}{$t}{$c}{f2} - $data->{diffs}{$type}{both}{$t}{$c}{f1};
						if ($net == 0)
						{	push @$line, "*" . $data->{diffs}{$type}{both}{$t}{$c}{f1} . " $c" . "(s)";
						}
						elsif ($net < 0)
						{	$net = 0 - $net;
							push @$line, "*" . $data->{diffs}{$type}{both}{$t}{$c}{f2} . ", -$net" . " $c" . "(s)";
						}
						elsif ($net > 1)
						{	push @$line, "+$net, *" . $data->{diffs}{$type}{both}{$t}{$c}{f1} . " $c" . "(s)";
						}
					}
					elsif ($data->{diffs}{Term}{both}{$t}{$c}{f1})
					{	push @$line, "-" . $data->{diffs}{$type}{both}{$t}{$c}{f1} . " $c" . "(s)";
					}
					elsif ($data->{diffs}{Term}{both}{$t}{$c}{f2})
					{	push @$line, "+" . $data->{diffs}{$type}{both}{$t}{$c}{f2} . " $c" . "(s)";
					}
				}
				if ($line)
				{	print $fh "$t";
					if ($data->{f2_hash}{$type}{$t}{name}[0])
					{	print $fh ", " . $data->{f2_hash}{$type}{$t}{name}[0];
					}
					print $fh "\n" . join("; ", @$line) . "\n";
				}
			}
			print $fh "\n\n";
		}
	}
}


sub print_errors {
	my $fh = shift;
	my $data = shift;
	print_lost_terms($fh,$data);
	print_unobsoletions($fh,$data);
	print_unmerges($fh,$data);
}

sub print_lost_terms {
	my $fh = shift;
	my $data = shift;

	return unless $data->{diffs}{Term}{f1_only} && keys %{$data->{diffs}{Term}{f1_only}};

	print $fh "Terms lost\n";
	foreach ( sort keys %{$data->{diffs}{Term}{f1_only}} )
	{	print $fh print_term_name($data, $_, 'f1') . " (" .
		$data->{f1_hash}{Term}{$_}{namespace}[0]
		. ")\n";
	}
	print $fh "\n\n";
}

sub print_unobsoletions {
	my $fh = shift;
	my $data = shift;
	
	my @obsoletes = grep {
		exists $data->{diffs}{Term}{both}{$_}{is_obsolete}
		&& exists $data->{diffs}{Term}{both}{$_}{is_obsolete}{f1}
	} keys %{$data->{diffs}{Term}{both}};

	if (@obsoletes)
	{	print $fh "Previously obsolete terms reinstantiated\n";
		map { print $fh print_term_name($data, $_) . "\n" } sort @obsoletes;
		print $fh "\n\n";
	}
}

sub print_unmerges {
	my $fh = shift;
	my $data = shift;

	if ($data->{f2_to_f1_merge})
	{	print $fh "Term splits\n";
		map { 
			print $fh print_term_name($data, $_) . ", was split from "
			. print_term_name($data, $data->{f2_to_f1_merge}{$_}) . "\n";
		} keys %{$data->{f2_to_f1_merge}};
		print $fh "\n\n";
	}
}

sub print_term_name {
	my $data = shift;
	my $t_id = shift;
	my $file = shift || 'f2';
	my $no_id = shift || undef;
	
	if ($data->{$file . "_hash" }{Term}{$t_id})
	{	return $data->{$file . "_hash" }{Term}{$t_id}{name}[0] if $no_id;
		return $t_id . ", " . $data->{$file . "_hash" }{Term}{$t_id}{name}[0];
	}
	else
	{	if ($data->{$file . "_alt_ids"}{$t_id})
		{	
			return $t_id . ", alt id for " . $data->{$file . "_alt_ids"}{$t_id} . ", " . $data->{$file . "_hash" }{Term}{ $data->{$file . "_alt_ids"}{$t_id} }{name}[0];
		}
		return "unrecognized term" if $no_id;
		return "$t_id, unrecognized term";
	}
}



=head2 block_to_sorted_array

input:  a multi-line block of text (preferably an OBO format stanza!)
output: ref to an array with the following removed
        - empty lines
        - lines starting with "id: ", "[", and "...]"
        - trailing whitespace

        the array is sorted

=cut

sub block_to_sorted_array {
	my $block = shift;
	my $arr;
	foreach ( split( "\n", $block ) )
	{	next unless /\S/;
		next if /^(id: \S+|\[|\S+\])\s*$/;
		$_ =~ s/^(is_a:|relationship:)\s*(.+)\s*!\s.*$/$1 $2/;
		$_ =~ s/\s*$//;
		push @$arr, $_;
	}
	
	return [ sort @$arr ] || undef;
}


=head2 tag_val_arr_to_hash

input:  array ref containing ": " separated tag-value pairs
output: lines in the array split up by ": " and put into a hash
        of the form key-[array of values]

=cut

sub tag_val_arr_to_hash {
	my $arr = shift;
	if ($arr && ! ref $arr && $_[0])
	{	my @array = ( $arr, @_ );
		$arr = \@array;
	}

	return undef unless $arr && @$arr;
	my $h;
	foreach (@$arr)
	{	my ($k, $v) = split(": ", $_, 2);
		if (! $k || ! $v)
		{	#print STDERR "line: $_\n";
		}
		else
		{	push @{$h->{$k}}, $v;
		}
	}
	return $h;
}


=head2 compare_hashes

input:  two hashes of arrays
        regex       a regular expression for hash keys to ignore

output: hash of differences in the form
        {hash key}{ f1 => number of values unique to f1,
                    f2 => number of values unique to f2 }

=cut

sub compare_hashes {
	my $args = shift;
	my $f1 = $args->{f1};
	my $f2 = $args->{f2};
	my $regex = $args->{regex};

	my $results;

	foreach my $p (keys %$f1)
	{	# skip these guys
		next if $p =~ /^$regex$/;
		if (! $f2->{$p})
		{	$results->{$p}{f1} += scalar @{$f1->{$p}};
		}
		else
		{	# find the same / different values
			my @v1 = values %$f1;
			my @v2 = values %$f2;

			my %count;
			foreach my $e (@{$f1->{$p}})
			{	$count{$e}++;
			}
			foreach my $e (@{$f2->{$p}})
			{	$count{$e} += 10;
			}

			foreach my $e (keys %count) {
				next if $count{$e} == 11;
				if ($count{$e} == 1)
				{	$results->{$p}{f1}++;
				}
				elsif ($count{$e} == 10)
				{	$results->{$p}{f2}++;
				}
			}
		}
	}
	foreach (keys %$f2)
	{	if (! $f1->{$_})
		{	$results->{$_}{f2} += scalar @{$f2->{$_}};
		}
	}
	
	return $results;
}

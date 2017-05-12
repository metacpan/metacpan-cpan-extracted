#!/usr/bin/perl -w

use strict;
use Test;
#plan tests => 1;
use Test::More 'no_plan';
use Test::Deep;
use Test::Deep::NoTest;
#plan tests => ;
use GOBO::Parsers::GAFParser;
use GOBO::Parsers::OBOParser;
use GOBO::Parsers::OBOParserDispatchHash;

use FileHandle;
use Data::Dumper;

ok 1;
exit 0;


my $gaf_parser;
my $obo_parser;
my $dh_parser;

# tests 1 - 10
$gaf_parser = new GOBO::Parsers::GAFParser(file=>new FileHandle("t/data/128up.gaf"));
ok($gaf_parser->has_fh);
$gaf_parser->parse;
my $g_128up = $gaf_parser->graph;
ok($g_128up);


$gaf_parser = new GOBO::Parsers::GAFParser(file=>"t/data/AT1G49810.gaf");
ok($gaf_parser->has_fh);
$gaf_parser->parse;
my $g_AT1G = $gaf_parser->graph;
ok($g_AT1G);


$gaf_parser = new GOBO::Parsers::GAFParser(fh=>"t/data/128up.gaf");
ok($gaf_parser->has_fh);
$gaf_parser->parse;
my $g2_128up = $gaf_parser->graph;
ok($g2_128up);

is_deeply($g_128up, $g2_128up, "Checking that the GAF parsers returned the same results");

$gaf_parser = new GOBO::Parsers::GAFParser(fh=>new FileHandle("t/data/AT1G49810.gaf") );
ok($gaf_parser->has_fh);
$gaf_parser->parse;
my $g2_AT1G = $gaf_parser->graph;
ok($g2_AT1G);
is_deeply($g_AT1G, $g2_AT1G, "Checking that the GAF parsers returned the same results");


## setting the file using set_file
$gaf_parser->reset_parser;
$gaf_parser = new GOBO::Parsers::GAFParser;
$gaf_parser->set_file("t/data/128up.gaf");
ok($gaf_parser->has_fh, "set_file used to initialize the fh");  #11
$gaf_parser->parse;
undef $g2_128up;
$g2_128up = $gaf_parser->graph;
is_deeply($g_128up, $g2_128up, "set_file: GAF parsers returned the same results"); # 12

my $fh = new FileHandle("t/data/AT1G49810.gaf");
$gaf_parser->reset_parser;
$gaf_parser->set_file($fh);
ok($gaf_parser->has_fh); # 13
$gaf_parser->parse;
undef $g2_AT1G;
$g2_AT1G = $gaf_parser->graph;
is_deeply($g_AT1G, $g2_AT1G, "set_file: GAF parsers returned the same results"); # 14

# using parse_file
$gaf_parser->reset_parser;
$gaf_parser->parse_file(file => new FileHandle("t/data/128up.gaf"));
ok($gaf_parser->has_fh); # 15
undef $g2_128up;
$g2_128up = $gaf_parser->graph;
is_deeply($g_128up, $g2_128up, "parse_file: GAF parsers returned the same results"); # 16

undef $gaf_parser;
$gaf_parser = new GOBO::Parsers::GAFParser;
#$gaf_parser->parse_file(file => "t/data/AT1G49810.gaf");
$gaf_parser->parse_file("t/data/AT1G49810.gaf");
ok($gaf_parser->has_fh); # 17
undef $g2_AT1G;
$g2_AT1G = $gaf_parser->graph;
is_deeply($g_AT1G, $g2_AT1G, "parse_file: GAF parsers returned the same results"); # 18


## testing the OBO parsers...

my $tags = {
	has_x => [ qw( nodes terms relations links declared_subsets annotations instances formulae ) ],
	body_only => [ qw( nodes terms relations links annotations instances formulae ) ],
	header_only => [ qw(default_namespace date comment format_version version property_value) ],
	both => [ qw(declared_subsets) ],
};

eval { $obo_parser = new GOBO::Parsers::OBOParser(file=>'/a/load/of/bollox'); };
ok( defined $@ );

#check the OBOParser quickly...
$obo_parser = new GOBO::Parsers::OBOParser(file=>'t/data/gtp.obo');
$dh_parser = new GOBO::Parsers::OBOParserDispatchHash(file=>'t/data/gtp.obo');
ok($obo_parser->has_fh && $dh_parser->has_fh);
$obo_parser->parse;
$dh_parser->parse;
ok( $obo_parser->graph->has_terms && $dh_parser->graph->has_terms, "Checking there are terms in the graph");
cmp_deeply( $obo_parser->graph, $dh_parser->graph, "Comparing OBO and DH parser graphs");


## OK, basics done. Let's try a bit of parsing...
# this is a graph with everything in the known (obo) world in it.
$obo_parser = new GOBO::Parsers::OBOParser(file=>'t/data/obo_file_2.obo');
$dh_parser = new GOBO::Parsers::OBOParserDispatchHash(file=>'t/data/obo_file_2.obo');
my $results;
my $errs;
	
foreach my $p ($obo_parser, $dh_parser)
{	$p->parse;
	my $graph = $p->graph;
	# check that we have these entities in our graph
	foreach my $e (@{$tags->{has_x}})
	{	my $fn = "has_$e";
	#	print STDERR "fn: $fn; result of graph->fn: ". Dumper( $graph->$fn ) . "\n";
		push @$errs, $e if ! $graph->$fn;
	}
	ok( ! defined $errs, "Checking entities in the graph" );
	print STDOUT "Did not find the following entities: " . join(", ", @$errs) . "\n" if $errs && @$errs;
	
	push @{$results->{ ref($p) }}, $graph;
	
	my $g_keys;  # store the non-body stuff in g_keys
	foreach my $k (keys %$graph)
	{	next if grep { $k eq $_ } @{$tags->{body_only}};
		$g_keys->{$k} = $graph->{$k};
	}
	
	## let's try a few options now...
	
#	print STDOUT "\n\n\nStarting options testing!\n";
	
	# ignore body and header
	$p->reset_parser;
	$p->parse_file
	(file=>'t/data/obo_file_2.obo', options => { body => { ignore => '*' }, header => { ignore => '*' } });
	
	my $new_graph = $p->graph;
	#print STDOUT "ignore body and header graph: " . Dumper($new_graph);
	isa_ok( $new_graph, "GOBO::Graph", "Ignoring body and header" );

	push @{$results->{ ref($p) }}, $new_graph;


	undef $errs;
	foreach my $e (@{$tags->{has_x}})
	{	my $fn = "has_$e";
		push @$errs, $e if $new_graph->$fn;
	}
	
	ok( ! $errs, "Checking entities in the graph" );
	print STDOUT "Found the following entities: " . join(", ", @$errs) . "\n" if $errs && @$errs;
	
	$p->reset_parser;
	$p->parse_file(file=>'t/data/obo_file_2.obo', options => { header => { ignore => '*' } });
	$new_graph = $p->graph;
	print STDOUT "ignoring headers\n";
	
	push @{$results->{ ref($p) }}, $new_graph;
	#foreach my $e (@{$tags->{has_x}})
	#{	print STDOUT "graph->$e: " . Dumper( $graph->$e ) . "\n";
	#}
	
	undef $errs;
	foreach my $e (@{$tags->{has_x}})
	{	push @$errs, $e if scalar @{ $new_graph->$e } != scalar @{ $graph->$e };
	}
	ok( ! defined $errs, "Ignored header: checking body elements" );
	if ($errs && @$errs)
	{	print STDOUT "Discrepancies in the following: " . join(", ", @$errs ) . "\n";
	}
	
	undef $errs;
	foreach my $e (@{$tags->{header_only}})
	{	push @$errs, $e if $new_graph->{$e};
	}
	
	ok( ! defined $errs, "Ignored header: checking header elements" );
	print STDOUT "Found the following entities: " . join(", ", @$errs) . "\n" if $errs && @$errs;
	
	
	$p->reset_parser;
	$p->parse_file(file=>'t/data/obo_file_2.obo', options => { body => { ignore => '*' } });
	$new_graph = $p->graph;
	push @{$results->{ ref($p) }}, $new_graph;

	undef $errs;
	foreach my $e (@{$tags->{body_only}})
	{	my $fn = "has_$e";
		push @$errs, $e if $new_graph->$fn;
	}
	
	ok( ! defined $errs, "Ignored body: checking body elements" );
	print STDOUT "Found the following entities: " . join(", ", @$errs) . "\n" if $errs && @$errs;
	
	undef $errs;
	foreach my $e (@{$tags->{header_only}}, @{$tags->{both}})
	{	if (! eq_deeply( $graph->{$e}, $new_graph->{$e} ))
		{	push @$errs, $e;
		}
	}
	ok( ! defined $errs, "Ignored body: checking header elements" );
	print STDOUT "Found the following entities: " . join(", ", @$errs) . "\n" if $errs && @$errs;
	
	
	## ignore everything except the instance and typedef stanza
	$p->reset_parser;
	$p->parse_file(file=>'t/data/obo_file.obo', options => { body => { parse_only => { instance => '*', annotation => '*' } } });
	
	$new_graph = $p->graph;
	push @{$results->{ ref($p) }}, $new_graph;

	foreach my $e (@{$tags->{body_only}})
	{	my $fn = "has_$e";
		push @$errs, $e if $new_graph->$fn;
	}
	
	ok( ! defined $errs, "Parse only instances and annotations: checking body elements" );
	print STDOUT "Found the following entities: " . join(", ", @$errs) . "\n" if $errs && @$errs;
	
	
	## ignore everything except the instance and typedef stanza
	$p->reset_parser;
	$p->parse_file(file=>'t/data/transporters.obo', options => { body => { parse_only => { term => ['id', 'namespace', 'synonym'] } } });
	
	$new_graph = $p->graph;
	push @{$results->{ ref($p) }}, $new_graph;

	foreach my $e (@{$tags->{body_only}})
	{	next if $e eq 'terms' || $e eq 'nodes';
		my $fn = "has_$e";
		push @$errs, $e if $new_graph->$fn;
	}
	ok( ! defined $errs, "Parse only term ids, names and namespaces: checking body elements" );
	print STDOUT "Found the following entities: " . join(", ", @$errs) . "\n" if $errs && @$errs;
	
	
	## ignore everything except the instance and typedef stanza
	$p->reset_parser;
	$p->parse_file(file=>'t/data/obo_file_2.obo', options => { body => { ignore => { term => ['is_a', 'relationship', 'synonym' ] } } });
	
}

my @p_types = ( keys %$results );
# check that both parsers got the same results
while (@{$results->{$p_types[0]}})
{	#my $g1 = pop @{$results->{$p_types[0]}}
	cmp_deeply( pop @{$results->{$p_types[0]}}, pop @{$results->{$p_types[1]}}, "Comparing results...");
}

## try using the Dispatch Hash parser
$dh_parser = new GOBO::Parsers::OBOParserDispatchHash;
#my $dh_parser = new GOBO::Parsers::AltOBOParser;
$dh_parser->parse_file(file => 't/data/obo_file_2.obo');

$obo_parser = new GOBO::Parsers::OBOParser;
$obo_parser->parse_file(file=>'t/data/obo_file_2.obo');

ok($dh_parser->graph, "Checking parser produced a graph");

undef $errs;
foreach my $e (@{$tags->{has_x}})
{	push @$errs, $e if scalar @{ $dh_parser->graph->$e } != scalar @{ $obo_parser->graph->$e };
}
ok( ! defined $errs, "Ignored header: checking body elements" );
if ($errs && @$errs)
{	print STDOUT "Discrepancies in the following: " . join(", ", @$errs ) . "\n";
	foreach (@$errs)
	{	if ($_ eq 'nodes')
		{	print STDOUT "$_: got:\n" . join("\n", sort map { $_->id } @{$dh_parser->graph->$_}) . "\n\n\n$_: expected:\n" . join("\n", sort map { $_->id } @{$obo_parser->graph->$_}) . "\n\n\n\n";
		}
		elsif ($_ eq 'links')
		{	print STDOUT "$_: got:\n" . join("\n", @{$dh_parser->graph->$_}) . "\n\n\n$_: expected:\n" . join("\n", @{$obo_parser->graph->$_}) . "\n\n\n\n";
		}
	}
}

cmp_deeply($dh_parser->graph, $obo_parser->graph, "Checking the dispatch hash parser");

## let's try parse_header_from_arr
undef $dh_parser;
$dh_parser = new GOBO::Parsers::OBOParserDispatchHash( file=>'t/data/obo_file_2.obo' );
$dh_parser->parse_header;

my @header_arr;
my @body_arr;
{	local $/ = "\n[";
	open(FH, "<" . 't/data/obo_file_2.obo') or die("Could not open t/data/obo_file_2.obo: $!");
	@header_arr = split("\n", <FH> );
	close FH;
	
	local $/ = "\n";
	open(FH, "<" . 't/data/obo_file_2.obo') or die("Could not open t/data/obo_file_2.obo: $!");

	while (<FH>)
	{	push @body_arr, $_;
	}

	
	my $i = 1;
	while ($i == 1)
	{	if ( $body_arr[0] =~ /^\[\S+/ )
		{	$i = 0;
			last;
		}
		shift @body_arr;
	}
#	print STDOUT "first in array body_arr: " . $body_arr[0] . "\n";
}

my $graph_data = $dh_parser->parse_header_from_array({ array => [ @header_arr ] });

cmp_deeply($graph_data, $dh_parser->graph, "Checking parse_header_from_array");


## let's try parse_body_from_arr
# delete the graph
$dh_parser->graph( new GOBO::Graph );
$dh_parser->parse_body;
$graph_data = $dh_parser->parse_body_from_array({ array => [ @body_arr ] });

cmp_deeply($graph_data, $dh_parser->graph, "Checking parse_body_from_array");



exit(0);

=cut
#print STDOUT "term: " . Dumper( [ @{$new_graph->terms}[0-5] ] ) . "\n";
system("clear");

## ignore everything except the instance and typedef stanza
$obo_parser->reset_parser;
$obo_parser->parse_file(file=>'t/data/obo_file_2.obo', options => { body => { ignore => { term => ['is_a', 'relationship', 'synonym' ], typedef => '*', 'annotation' => [ '*' ] } } });

system("clear");
system("clear");
system("clear");

print STDOUT "terms: " . Dumper($obo_parser->graph->terms);
#$obo_parser->graph->terms->dump(3);


# print $parser->graph;
=cut

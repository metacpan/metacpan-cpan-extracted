use strict;
use warnings;
use Test::More;
use Hypatia;
use Hypatia::DBI::Test::SQLite;
use Scalar::Util qw(blessed);

BEGIN
{
    eval "require DBD::SQLite";
    if($@)
    {
	require Test::More;
	Test::More::plan(skip_all=>"DBD::SQLite is required to run these tests.")
    }
}

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_graphviz_test_k4"});
my $dbh=$hdts->dbh;

 my $hypatia=Hypatia->new({
    back_end=>"GraphViz2",
    dbi=>{dbh=>$hdts->dbh,
	table=>"hypatia_graphviz_test_k4"},
	columns=>{v1=>"a",v2=>"b"}
});
 
ok(blessed($hypatia) eq "Hypatia");
ok(blessed($hypatia->dbh) eq 'DBI::db');
ok($hypatia->dbh->{Active});

my $gv2=$hypatia->graph;

ok(blessed($gv2) eq "GraphViz2");

my $node_hash = $gv2->node_hash;

ok(scalar(keys %$node_hash) == 4);

foreach my $i(1..4)
{
	ok(grep{$i eq $_}(keys %$node_hash));
}

my $edge_hash = $gv2->edge_hash;

foreach my $i(1..3)
{
	foreach my $j(($i+1)..4)
	{
		ok(grep{$_ eq $j}(keys %{$edge_hash->{$i}}));
	}
}

use Data::Dumper;print Dumper($edge_hash) . "\n";

done_testing();

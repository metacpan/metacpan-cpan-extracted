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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_graphviz_test_petersen"});
my $dbh=$hdts->dbh;

 my $hypatia=Hypatia->new({
    back_end=>"GraphViz2",
    dbi=>{dbh=>$hdts->dbh,
	table=>"hypatia_graphviz_test_petersen"},
});
 
ok(blessed($hypatia) eq "Hypatia");
ok(blessed($hypatia->dbh) eq 'DBI::db');
ok($hypatia->dbh->{Active});

my $gv2=$hypatia->graph;

ok(blessed($gv2) eq "GraphViz2");

my $node_hash = $gv2->node_hash;

ok(scalar(keys %$node_hash) == 10);

foreach my $i(1..10)
{
	ok(grep{$_ eq $i}(keys %$node_hash));
}

my $edge_hash = $gv2->edge_hash;

my @edges = ([1,2],[1,5],[1,6],[2,3],[2,7],[3,4],[3,8],[4,5],[4,9],[5,1],[5,10],[6,8],[6,9],[7,9],[7,10],[8,10]);

foreach my $pair(@edges)
{
	ok(grep{$_ eq $pair->[1]}(keys %{$edge_hash->{$pair->[0]}}));
}

done_testing();

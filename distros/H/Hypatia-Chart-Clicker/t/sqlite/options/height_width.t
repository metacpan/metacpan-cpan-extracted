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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_test_xy"});

my $hypatia=Hypatia->new({
    dbi=>{dbh=>$hdts->dbh,table=>"hypatia_test_xy"},
    columns=>{x=>"x1",y=>"y1"},
    back_end=>"Chart::Clicker",
    graph_type=>"Line",
    options=>{width=>800,height=>600}
});

isa_ok($hypatia,"Hypatia");

my $cc=$hypatia->chart;

isa_ok($cc,"Chart::Clicker");

ok($cc->width == 800);
ok($cc->height == 600);

done_testing();
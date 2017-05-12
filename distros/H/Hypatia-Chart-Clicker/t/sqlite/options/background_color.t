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
    options=>{background_color=>0.5}
});

isa_ok($hypatia,"Hypatia");

my $cc=$hypatia->chart;

isa_ok($cc,"Chart::Clicker");

my $bc=$cc->background_color;

ok($bc->r == 0.5 and $bc->g == 0.5 and $bc->b == 0.5 and $bc->a == 0.5);

undef $hypatia;
undef $cc;
undef $bc;

$hypatia=Hypatia->new({
    dbi=>{dbh=>$hdts->dbh,table=>"hypatia_test_xy"},
    columns=>{x=>"x1",y=>"y1"},
    back_end=>"Chart::Clicker",
    graph_type=>"Line",
    options=>{background_color=>{r=>0.8,g=>0,b=>0.9,a=>0.6}}
});

isa_ok($hypatia,"Hypatia");

$cc=$hypatia->chart;

isa_ok($cc,"Chart::Clicker");

$bc=$cc->background_color;

ok($bc->r == 0.8 and $bc->g == 0 and $bc->b == 0.9 and $bc->a == 0.6);

done_testing();
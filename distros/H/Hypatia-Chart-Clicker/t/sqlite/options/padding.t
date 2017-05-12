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
    options=>{padding=>5}
});

isa_ok($hypatia,"Hypatia");

my $cc=$hypatia->chart;

isa_ok($cc,"Chart::Clicker");

isa_ok($cc->padding,"Graphics::Primitive::Insets");

ok($cc->padding->$_ == 5) foreach (qw(top bottom right left));

undef $hypatia;
undef $cc;


$hypatia=Hypatia->new({
    dbi=>{dbh=>$hdts->dbh,table=>"hypatia_test_xy"},
    columns=>{x=>"x1",y=>"y1"},
    back_end=>"Chart::Clicker",
    graph_type=>"Line",
    options=>{padding=>{top=>3,bottom=>4,right=>5,left=>6}}
});

isa_ok($hypatia,"Hypatia");

$cc=$hypatia->chart;

isa_ok($cc,"Chart::Clicker");

isa_ok($cc->padding,"Graphics::Primitive::Insets");

ok($cc->padding->top == 3);
ok($cc->padding->bottom == 4);
ok($cc->padding->right == 5);
ok($cc->padding->left == 6);


done_testing();
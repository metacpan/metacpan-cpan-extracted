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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_test_bubble_fail"});
my $dbh=$hdts->dbh;

 eval{Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"bubble",
    dbi=>{dbh=>$hdts->dbh,
	table=>"hypatia_test_bubble_fail"}
})->_guess_columns};
 
 ok($@);
 
 done_testing();
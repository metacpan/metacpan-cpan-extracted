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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_test_bubble_multi2"});
my $dbh=$hdts->dbh;

 my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"bubble",
    dbi=>{dbh=>$hdts->dbh,
	table=>"hypatia_test_bubble_multi2"},
	columns=>{x=>"x",y=>[qw(y1 y2)],size=>[qw(size1 size2)]}
});
 
ok(blessed($hypatia) eq "Hypatia");
ok(blessed($hypatia->dbh) eq "DBI::db");
ok($hypatia->dbh->{Active});

my $cc=$hypatia->chart;

ok(blessed($cc) eq "Chart::Clicker");
 
 my $dataset = $cc->datasets->[0];
 ok(blessed($dataset) eq "Chart::Clicker::Data::DataSet");

ok(@{$dataset->series} == 2);

my $dataseries=$dataset->series->[0];
ok(blessed($dataseries) eq "Chart::Clicker::Data::Series::Size");
my $keys=$dataseries->keys;
my $values=$dataseries->values;
my $sizes=$dataseries->sizes;

ok(@$keys == 4);
ok(@$values == 4);
ok(@$sizes == 4);

ok(scalar(grep{$_ == -1 or $_ == 1 or $_ == 5 or $_ == 6}@$keys) == 4);
ok(scalar(grep{$_ == 2 or $_ == 1 or $_ == 0 or $_ == -3}@$values) == 4);
ok(scalar(grep{$_ == 4 or $_ == 0.4 or $_ == 2}@$sizes) == 4);

$dataseries=$dataset->series->[1];
$keys=$dataseries->keys;
$values=$dataseries->values;
$sizes=$dataseries->sizes;

ok(@$keys == 4);
ok(@$values == 4);
ok(@$sizes == 4);

ok(scalar(grep{$_ == -1 or $_ == 1 or $_ == 5 or $_ == 6}@$keys) == 4);
ok(scalar(grep{$_ == -3 or $_ == 5 or $_ == 8}@$values) == 4);
ok(scalar(grep{$_ == 1 or $_ == 1.21 or $_ == 3 or $_ == 0.5}@$sizes) == 4);

done_testing();
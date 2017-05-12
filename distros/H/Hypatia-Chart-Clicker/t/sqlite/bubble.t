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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_test_bubble"});
my $dbh=$hdts->dbh;

 my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"bubble",
    dbi=>{dbh=>$hdts->dbh,
	table=>"hypatia_test_bubble"},
	columns=>{x=>"a",y=>"b",size=>"c"}
});
 
ok(blessed($hypatia) eq "Hypatia");
ok(blessed($hypatia->dbh) eq 'DBI::db');
ok($hypatia->dbh->{Active});

my $cc=$hypatia->chart;

ok(blessed($cc) eq 'Chart::Clicker');
 
 my $dataset = $cc->datasets->[0];
 ok(blessed($dataset) eq 'Chart::Clicker::Data::DataSet');

my $dataseries=$dataset->series->[0];
ok(blessed($dataseries) eq 'Chart::Clicker::Data::Series::Size');
my $keys=$dataseries->keys;
my $values=$dataseries->values;
my $sizes=$dataseries->sizes;

ok(@$keys == 4);
ok(@$values == 4);
ok(@$sizes == 4);

ok(scalar(grep{$_ == 0 or $_ == 0.9 or $_ == 2 or $_ == 6}@$keys) == 4);
ok(scalar(grep{$_ == 3 or $_ == 4 or $_ == 6.1 or $_ == 4.4}@$values) == 4);
ok(scalar(grep{$_ == 1.1 or $_ == 0.5 or $_ == 2.2 or $_ == 1.9}@$sizes) == 4);

done_testing();
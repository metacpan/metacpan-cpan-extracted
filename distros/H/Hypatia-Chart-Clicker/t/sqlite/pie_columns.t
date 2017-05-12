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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_test_pie"});
my $dbh=$hdts->dbh;

 my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"Pie",
    dbi=>{dbh=>$hdts->dbh,
	table=>"hypatia_test_pie"},
});
 
ok(blessed($hypatia) eq "Hypatia");
ok(blessed($hypatia->dbh) eq 'DBI::db');
ok($hypatia->dbh->{Active});

ok(blessed($hypatia->cols) eq "Hypatia::Columns");
ok(not $hypatia->using_columns);

my $cc=$hypatia->chart;

ok($hypatia->using_columns);
ok($hypatia->columns->{label} eq "type");
ok($hypatia->columns->{values} eq "number");

ok(blessed($cc) eq 'Chart::Clicker');
 
 my $dataset = $cc->datasets->[0];
 ok(blessed($dataset) eq 'Chart::Clicker::Data::DataSet');

ok(@{$dataset->series} == 3);

my $dataseries=$dataset->series->[0];
my $keys=$dataseries->keys;
my $values=$dataseries->values;
my $name=$dataseries->name;

ok(@$keys == 2 and scalar(grep{$_ == 1 or $_ == 2}@$keys) == 2);
ok(@$values == 2 and scalar(grep{$_ == 0 or $_ == 2}@$values) == 2);
ok($name eq "'some other thing'");

$dataseries=$dataset->series->[1];
$keys=$dataseries->keys;
$values=$dataseries->values;
$name=$dataseries->name;

ok(@$keys == 2 and scalar(grep{$_ == 1 or $_ == 2}@$keys) == 2);
ok(@$values == 2 and scalar(grep{$_ == 0 or $_ == 1.48}@$values) == 2);
ok($name eq "'some type'");

$dataseries=$dataset->series->[2];
$keys=$dataseries->keys;
$values=$dataseries->values;
$name=$dataseries->name;

ok(@$keys == 2 and scalar(grep{$_ == 1 or $_ == 2}@$keys) == 2);
ok(@$values == 2 and scalar(grep{$_ == 0 or $_ == 1.78}@$values) == 2);
ok($name eq "'yet another thing'");


done_testing();

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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_test_bubble_multi1"});
my $dbh=$hdts->dbh;

 my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"bubble",
    dbi=>{dbh=>$hdts->dbh,
	table=>"hypatia_test_bubble_multi1"},
});
 
ok(blessed($hypatia) eq "Hypatia");
ok(blessed($hypatia->dbh) eq "DBI::db");
ok($hypatia->dbh->{Active});

ok(blessed($hypatia->cols) eq "Hypatia::Columns");
ok(not $hypatia->using_columns);

my $cc=$hypatia->chart;

ok($hypatia->using_columns);

ok(@{$hypatia->columns->{$_}} == 2) foreach(qw(x y size));

ok($hypatia->columns->{x}->[0] eq "x1");
ok($hypatia->columns->{x}->[1] eq "x2");
ok($hypatia->columns->{y}->[0] eq "y1");
ok($hypatia->columns->{y}->[1] eq "y2");
ok($hypatia->columns->{size}->[0] eq "size1");
ok($hypatia->columns->{size}->[1] eq "size2");

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

ok(scalar(grep{$_ == 3 or $_ == 1 or $_ == 8 or $_ == 6}@$keys) == 4);
ok(scalar(grep{$_ == 2 or $_ == 6 or $_ == 7 or $_ == 2}@$values) == 4);
ok(scalar(grep{$_ == 0.4 or $_ == 1 or $_ == 2.01 or $_ == 0.2}@$sizes) == 4);

$dataseries=$dataset->series->[1];
$keys=$dataseries->keys;
$values=$dataseries->values;
$sizes=$dataseries->sizes;

ok(@$keys == 4);
ok(@$values == 4);
ok(@$sizes == 4);

ok(scalar(grep{$_ == 5 or $_ == 4 or   $_ == 9}@$keys) == 4);
ok(scalar(grep{$_ == 1 or $_ == 7 or $_ == -1 or $_ == 5}@$values) == 4);
ok(scalar(grep{$_ == 0.8 or $_ == 1.3 or $_ == 1.38 or $_ == 3}@$sizes) == 4);

done_testing();
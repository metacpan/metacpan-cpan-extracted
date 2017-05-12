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

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_test_xy",sqlite_db_file=>"hypatia_test.db"});

foreach my $graph_type(qw(Area Bar Line Point))
{
    my $hypatia=Hypatia->new({
	back_end=>"Chart::Clicker",
	graph_type=>$graph_type,
	dbi=>{dsn=>"dbi:SQLite:dbname=" . $hdts->sqlite_db_file,
	    query=>"select x1,y1,y2 from hypatia_test_xy"},
    });
    
    ok(blessed($hypatia) eq "Hypatia");
    ok(blessed($hypatia->dbh) eq "DBI::db");
    ok($hypatia->dbh->{Active});
    
    ok(blessed($hypatia->cols) eq 'Hypatia::Columns');
    
    ok(not $hypatia->using_columns);
    
    my $cc=$hypatia->chart;
    
    ok($hypatia->using_columns);
        
    ok($hypatia->columns->{x} eq "x1");
    ok(@{$hypatia->columns->{y}} == 2);

    ok($hypatia->columns->{y}->[0] eq "y1");
    ok($hypatia->columns->{y}->[1] eq "y2");

    
    ok(blessed($cc) eq "Chart::Clicker");
    
    ok(@{$cc->datasets} == 1);
    ok(@{$cc->datasets->[0]->series} == 2);
    
    my $dataseries = $cc->datasets->[0]->series;
    
    my $series = $dataseries->[0];
    my $keys = $series->keys;
    my $values = $series->values;
    
    ok(@$keys == 5);
    ok(@$values == 5);
    
    ok(grep{$_ ==1 or $_ == 2 or $_== 4 or $_==5 or $_==6}@$keys == 5);
    ok(scalar(grep{$_ == 7.22 or $_ == 3.88 or $_ == 6.2182 or $_ == 4.1 or $_ == 2.71828}@$values) == 5);
    
    $series=$dataseries->[1];
    $keys=$series->keys;
    $values=$series->values;
    
    ok(@$keys == 5);
    ok(@$values == 5);
    
    ok(grep{$_ ==1 or $_ == 2 or $_== 4 or $_==5 or $_==6}@$keys == 5);
    ok(scalar(grep{$_ == 2.1 or $_ == -0.5 or $_ == 3 or $_ == 3.1415926 or $_ == 1.41}@$values) == 5);
    
}

done_testing();
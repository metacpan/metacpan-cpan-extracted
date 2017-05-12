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

foreach my $axis(qw(domain_axis range_axis))
{
    my $hypatia=Hypatia->new({
	dbi=>{dbh=>$hdts->dbh,table=>"hypatia_test_xy"},
	columns=>{x=>"x1",y=>"y1"},
	back_end=>"Chart::Clicker",
	graph_type=>"Line",
	options=>{$axis=>{label=>"This is a label"}}
    });

    isa_ok($hypatia,"Hypatia");
    
    my $cc=$hypatia->chart;
    
    isa_ok($cc,"Chart::Clicker");
    
    my $dc=$cc->get_context("default");
    
    my $axis_obj = $dc->$axis();
    
    isa_ok($axis_obj,"Chart::Clicker::Axis");
    
    ok($axis_obj->label eq "This is a label");
}

done_testing();
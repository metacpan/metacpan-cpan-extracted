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
	options=>{$axis=>{tick_label_color=>0.5}}
    });

    isa_ok($hypatia,"Hypatia");
    
    my $cc=$hypatia->chart;
    
    isa_ok($cc,"Chart::Clicker");
    
    my $dc=$cc->get_context("default");
    
    my $axis_obj = $dc->$axis();
    
    isa_ok($axis_obj,"Chart::Clicker::Axis");
    
    my $tick_label_color = $axis_obj->tick_label_color;
    
    ok($tick_label_color->r == 0.5 and $tick_label_color->g == 0.5 and $tick_label_color->b == 0.5 and $tick_label_color->a == 0.5);

    undef $hypatia;
    undef $cc;
    undef $dc;
    undef $axis_obj;
    undef $tick_label_color;

    $hypatia=Hypatia->new({
	dbi=>{dbh=>$hdts->dbh,table=>"hypatia_test_xy"},
	columns=>{x=>"x1",y=>"y1"},
	back_end=>"Chart::Clicker",
	graph_type=>"Line",
	options=>{$axis=>{tick_label_color=>{r=>0.8,g=>0,b=>0.9,a=>0.6}}}
    });

    isa_ok($hypatia,"Hypatia");
    
    $cc = $hypatia->chart;
    
    $dc=$cc->get_context("default");
    
    $axis_obj = $dc->$axis();
    
    isa_ok($axis_obj,"Chart::Clicker::Axis");
    
    $tick_label_color = $axis_obj->tick_label_color;

    ok($tick_label_color->r == 0.8 and $tick_label_color->g == 0 and $tick_label_color->b == 0.9 and $tick_label_color->a == 0.6);

}

done_testing();
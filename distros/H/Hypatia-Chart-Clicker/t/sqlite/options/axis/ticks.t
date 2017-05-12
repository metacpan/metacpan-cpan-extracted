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

my @days_of_week = qw(Sun Mon Tues Wed Thur Fri Sat);

my $hdts=Hypatia::DBI::Test::SQLite->new({table=>"hypatia_cc_ticks_test"});

my $hypatia=Hypatia->new({
    dbi=>{dbh=>$hdts->dbh,table=>"hypatia_cc_ticks_test"},
    back_end=>"Chart::Clicker",
    graph_type=>"Bar",
    options=>{domain_axis=>{
			    ticks=>7,
			    tick_values=>[map{$_ - 0.5}1..7],
			    tick_labels=>\@days_of_week
			    }
	      }
});

isa_ok($hypatia,"Hypatia");

my $cc=$hypatia->chart;

isa_ok($cc,"Chart::Clicker");

my $dc=$cc->get_context("default");

my $axis_obj = $dc->domain_axis;

isa_ok($axis_obj,"Chart::Clicker::Axis");

ok($axis_obj->ticks == 7);

foreach my $i(0..6)
{
    ok(grep{$i + 0.5 == $_}@{$axis_obj->tick_values});
    ok(grep{$_ eq $days_of_week[$i]}@{$axis_obj->tick_labels});
}


done_testing();
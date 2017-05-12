#!perl -T

use Test::More tests => 2;

# use Data::Dumper;

BEGIN {
	use_ok( 'LJ::Schedule::Vcal' );
}

# Do a Palm vcal first
{
    no warnings;

    my $cal = LJ::Schedule::Vcal->new({filename => './t/test2.vcal'});
    $cal->prep_cal_for_lj();

#    print STDERR Dumper $cal;

    my $evts = $cal->evts();

    ok(scalar(@$evts) == 4);
}

# Now do an iCal one
#{
#    my $cal = LJ::Schedule::Vcal->new({filename => './t/test2.vcal.ics'});
#    $cal->prep_cal_for_lj();
#
#    print STDERR Dumper $cal;
#
#    my $evts = $cal->evts();
#
#    ok(scalar(@$evts) == 4);
#}

1;


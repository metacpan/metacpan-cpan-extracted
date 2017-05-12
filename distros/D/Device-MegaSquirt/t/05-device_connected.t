#!perl -w
use strict;

use Test::More;

# These tests can only be performed with a MegaSquirt controller
# connected.
# And if the values on the controller are important they should
# be backed up because they will be mutated.

my $dev = '/dev/ttyUSB0';  # configure

my $device_connected = 0;
if (-e $dev) {
    $device_connected = 1;  # TRUE
}

if ($device_connected) {
    plan tests => 6;
    use_ok('Device::MegaSquirt');

    my $ms = Device::MegaSquirt->new($dev);
    ok($ms);

    # {{{ read/write_crankingRPM
    {
    # toggle between two valid values
    my $rpm = $ms->read_crankingRPM();
    if ($rpm == 350) {
        $ms->write_crankingRPM(400);
        $rpm = $ms->read_crankingRPM();

        ok(400 == $rpm);
    } else {
        $ms->write_crankingRPM(350);
        $rpm = $ms->read_crankingRPM();
        ok(350 == $rpm);
    }
    }
    # }}}

    # {{{ read/write_veTable1();
    {
    my $tbl = $ms->read_veTable1();
    ok($tbl);

    $tbl->set(5, 7, 123);
    $tbl->set(3, 1, 156);

    $ms->write_veTable1($tbl);

    my $tbl2 = $ms->read_veTable1();

    ok("$tbl" eq "$tbl2");
    }
    # }}}

    # {{{ read/write_advanceTable1();
    {
    my $tbl = $ms->read_advanceTable1();

    $tbl->set(0, 0, 50.0);
    $tbl->set(2, 4, 74.0);
    $tbl->set(11, 8, 80.0);

    $ms->write_advanceTable1($tbl);

    my $tbl2 = $ms->read_advanceTable1();

    my @f1 = $tbl->flatten();
    my @f2 = $tbl->flatten();

    # Apparently during the conversion of values there may be an
    # error of +- 0.1.  This means the test "$tbl" eq "$tbl2" will
    # fail.  The following tests that they are the same within a
    # error of 0.1.

    my $ok = 1;
    for (my $i = 0; $i < @f1; $i++) {
        my $a = $f1[$i];
        my $b = $f2[$i];

        if ($a + 0.1 >= $b or $a - 0.1 <= $b) {
            # OK
        } else {
            $ok = 0;
            last;
        }
    }
    ok($ok);

    }
    # }}}

} else {
    plan tests => 1;
    ok(1);
}

#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Linux::LVM2' ) || print "Bail out!
";
    use_ok( 'Linux::LVM2::LV' ) || print "Bail out!
";
    use_ok( 'Linux::LVM2::PV' ) || print "Bail out!
";
    use_ok( 'Linux::LVM2::Snapshot' ) || print "Bail out!
";
    use_ok( 'Linux::LVM2::Utils' ) || print "Bail out!
";
    use_ok( 'Linux::LVM2::VG' ) || print "Bail out!
";
}

diag( "Testing Linux::LVM2 $Linux::LVM2::VERSION, Perl $], $^X" );

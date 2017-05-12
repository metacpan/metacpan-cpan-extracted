#!perl -T

use Test::More tests => 8;

BEGIN {
    use_ok( 'Linux::Virt' ) || print "Bail out!
";
    use_ok( 'Linux::Virt::Plugin' ) || print "Bail out!
";
    use_ok( 'Linux::Virt::Plugin::KVM' ) || print "Bail out!
";
    use_ok( 'Linux::Virt::Plugin::Libvirt' ) || print "Bail out!
";
    use_ok( 'Linux::Virt::Plugin::LXC' ) || print "Bail out!
";
    use_ok( 'Linux::Virt::Plugin::Openvz' ) || print "Bail out!
";
    use_ok( 'Linux::Virt::Plugin::Vserver' ) || print "Bail out!
";
    use_ok( 'Linux::Virt::Plugin::Xen' ) || print "Bail out!
";
}

diag( "Testing Linux::Virt $Linux::Virt::VERSION, Perl $], $^X" );

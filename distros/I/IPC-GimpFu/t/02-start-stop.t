#!perl
#
# NOTE: This test doesn't run under tainted mode, since it needs to
# start and stop daemons.

use Test::More tests => 5;

BEGIN { use_ok( 'IPC::GimpFu' ); }
require_ok( 'IPC::GimpFu' );

my $gimp = IPC::GimpFu->new({ autostart => 1 });
isa_ok($gimp, 'IPC::GimpFu');

ok( $gimp->start() != 0 );
ok( $gimp->stop()  != 0 );

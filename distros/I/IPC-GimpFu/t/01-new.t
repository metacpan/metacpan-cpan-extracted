#!perl -T

use Test::More tests => 7;

BEGIN { use_ok( 'IPC::GimpFu' ); }
require_ok( 'IPC::GimpFu' );

my $gimp1 = IPC::GimpFu->new({ server => 'remote' });
isa_ok($gimp1, 'IPC::GimpFu');

# A remote server can't be controlled:
ok( $gimp1->start() == 0 );
ok( $gimp1->stop()  == 0 );

my $gimp2 = IPC::GimpFu->new({ autostart => 1 });
isa_ok($gimp2, 'IPC::GimpFu');

my $gimp3 = IPC::GimpFu->new({ server => 'remote', autostart => 1 });
ok(not defined $gimp3);

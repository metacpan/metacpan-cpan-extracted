#!perl
#
# NOTE: This test doesn't run under tainted mode, since it needs to
# start and stop daemons.

use Test::More tests => 10;

BEGIN { use_ok( 'IPC::GimpFu' ); }
require_ok( 'IPC::GimpFu' );

my $gimp = IPC::GimpFu->new({ autostart => 1 });
isa_ok($gimp, 'IPC::GimpFu');

is  ( $gimp->run()         , 0              , 'no command is detected'   );
is  ( $gimp->run('')       , 0              , 'empty command is detected');
like( $gimp->run('(+ 2 2)'), qr/^Success|4$/, '(+ 2 2) is Success || 4'  );
isnt( $gimp->run('(2 + 2)'), qr/^Error/     , '(2 + 2) is an error'      );

isnt( $gimp->stop()        , 0              , 'killing works'                  );
like( $gimp->run('(+ 2 2)'), qr/^Success|4$/, 'again: (+ 2 2) is Success || 4' );
isnt( $gimp->stop()        , 0              , 'killing works again'            );

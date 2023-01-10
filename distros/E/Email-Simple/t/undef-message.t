use v5.12.0;
use warnings;

use Test::More tests => 3;

use_ok("Email::Simple");

eval { Email::Simple->new };

ok( $@, 'throws an error' );
like( $@, qr/unable to parse undefined message/i, 'throws sane error' );


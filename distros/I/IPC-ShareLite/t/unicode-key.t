#!perl

use strict;
use warnings;
use Test::More tests => 3;
use IPC::ShareLite;

my $share1 = eval {
  IPC::ShareLite->new(
    '-key'     => "AAA\x{104}",    # in hex it's 41 41 41 c4 84
    '-create'  => 'yes',
    '-destroy' => 'no',
  );
};
like $@, qr/not 8-bit clean/, '8-bit clean error (1)';

my $share2 = eval {
  IPC::ShareLite->new(
    '-key'     => "AAA\x{118}",    # in hex it's 41 41 41 c4 98
    '-create'  => 'yes',
    '-destroy' => 'no',
  );
};
like $@, qr/not 8-bit clean/, '8-bit clean error (2)';

if ( $share1 and $share2 ) {
  $share1->store( 'Hello world' );
  ok !defined $share2->fetch, 'unicode key aliasing';
}
else {
  pass 'unicode keys rejected';
}

# vim:ts=2:sw=2:et:ft=perl


# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Hey::heyPass' ); }

my $hp = Hey::heyPass->new({
  uuid => '1f0123de58d123ddb4da123851399123',
  key => 'your-app-password-here',
});

isa_ok ($hp, 'Hey::heyPass');
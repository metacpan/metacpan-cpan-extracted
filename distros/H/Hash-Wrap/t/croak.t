#! perl

use Test2::V0;

use Hash::Wrap;

my $obj = wrap_hash( {} );

like( dies{ $obj->foo },
      qr{t/croak.t},
      "croak message has correct call frame",
);


done_testing;

use strict;
use warnings;
use Test::More 'no_plan';

use MRO::Magic ();

{
  my $ok = eval {
    package Foo;
    sub __metamethod__ { "just here to cause problems" }
    MRO::Magic->import( sub { 1 } );
    1;
  };

  my $error = $@;
  ok( ! $ok, "we can't use MRO::Magic without custom name if conflict exists");
  like($error, qr/already/, "... got the right error, more or less");
}

{
  my $ok = eval {
    package Bar;
    MRO::Magic->import(metamethod => \'doesnt_exist');
    1;
  };

  my $error = $@;
  ok( ! $ok, "we can't provide MRO::Magic by name if it doesn't exist");
  like($error, qr/can't find/, "... got the right error, more or less");
}


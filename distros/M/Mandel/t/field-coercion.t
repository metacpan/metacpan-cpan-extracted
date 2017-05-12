use strict;
use warnings;
use Test::More;

package main;

{
  package WithCoerce;
  use Mandel::Document;
  use Types::Standard qw( ArrayRef Str Split );
  field names => (
    isa    => (ArrayRef[Str])->plus_coercions(Split[qr/\s/]),
  );
}

my $doc = WithCoerce->new;

is_deeply $doc->names('a b c')->names, [qw(a b c)], "Coercion ok!";

done_testing;

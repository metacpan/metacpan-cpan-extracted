use strict; use warnings;
use feature 'say';

use Types::Standard 'Num';

use List::Objects::WithUtils;
use Benchmark 'cmpthese', 'timethese';

say "  >>> array types <<<";

my @values = ( 1 .. 100 );

my $basic = sub { my $arr = array @values };

my $immutable = sub { my $arr = immarray @values };

my $typed = sub { my $arr = array_of Num() => @values };

my $typed_immutable = sub { my $arr = immarray_of Num() => @values };

my $results = timethese( 100_000 =>
  +{
      array       => $basic,
      immarray    => $immutable,
      array_of    => $typed,
      immarray_of => $typed_immutable,
  }
);
cmpthese($results);


say "  >>> hash types <<<";
my $ltr = 'a';
my %hsh = map {; $ltr++ => $_ } 1 .. 100;

$basic = sub { my $hash = hash %hsh };
$immutable = sub { my $hash = immhash %hsh };
$typed = sub { my $hash = hash_of Num() => %hsh };
$typed_immutable = sub { my $hash = immhash_of Num() => %hsh };

my $hash_results = timethese( 100_000 =>
  +{
      hash       => $basic,
      immhash    => $immutable,
      hash_of    => $typed,
      immhash_of => $typed_immutable,
  }
);
cmpthese($hash_results);



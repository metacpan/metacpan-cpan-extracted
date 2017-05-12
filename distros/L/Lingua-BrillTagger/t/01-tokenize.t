
use strict;
use Test::More;
use File::Spec;

use Lingua::BrillTagger;

my @examples =
(
 q{I can't get no beans.}
 =>
 q{I ca n't get no beans .},

 q{"We have no useful information on whether users are at risk,"
   said James A. Talcott of Boston's Dana-Farber Cancer Institute.}
 =>
 q{`` We have no useful information on whether users are at risk , ''
   said James A. Talcott of Boston 's Dana-Farber Cancer Institute .},

 q{Pants cost $8.90 today.}
 =>
 q{Pants cost $ 8.90 today .},
 
 q{Pants cost $8.91 tomorrow.}
 =>
 q{Pants cost $ 8.91 tomorrow .},
);

plan tests => 2 + @examples/2;

ok 1, "Module is loaded";

my $t = new Lingua::BrillTagger;
ok $t, "Created new Lingua::BrillTagger object";

foreach my $i (0..(@examples-2)/2) {
  my ($string, $result) = @examples[ 2*$i, 2*$i + 1 ];
  my @tokens = split ' ', $result;
  my $got = $t->tokenize($string);
  is( "@$got", "@tokens", "Check tokenize() output [$i]" );
}




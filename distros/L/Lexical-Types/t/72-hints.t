#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

SKIP: {
 skip 'This fails on perl 5.11.x even without using Lexical::Types' => 2
                                              if "$]" >= 5.011 and "$]" < 5.012;
 local %^H = (a => 1);

 require Lexical::Types;

 my $err = do {
  local $@;
  eval <<'  VIVIFICATION_TEST';
   package Lexical::Types::TestVivification;
   sub TYPEDSCALAR { }
   my Lexical::Types::TestVivification $lexical;
  VIVIFICATION_TEST
  $@;
 };

 # Force %^H repopulation with an Unicode match
 my $x = "foo";
 utf8::upgrade($x);
 $x =~ /foo/i;

 my $hints = join ',',
              map { $_, defined $^H{$_} ? $^H{$_} : '(undef)' }
               sort keys(%^H);
 is $err,   '',    'vivification test code did not croak';
 is $hints, 'a,1', 'Lexical::Types does not vivify entries in %^H';
}

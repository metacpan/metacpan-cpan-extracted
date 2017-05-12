# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/4.t'

#########################

use lib qw(t/lib);
use Test::More tests => 12;

BEGIN { use_ok( 'Lingua::SoundChange' ) }

#########################
# Testing the rules
#########################

my($lang, $out);

$lang = Lingua::SoundChange->new( { '+vcd' => 'bdg', 'cap'   => 'AEIOU',
                                    '-vcd' => 'ptk', 'small' => 'aeiou' },
                                  [ '<-vcd>/<+vcd>/<small>_<small>',
                                    '<small>/<cap>/_#' ],
                                  { longVars => 1 } );
ok(ref $lang, '$lang is a reference');
$out = $lang->change(['qwerty', 'motor', 'bateau']);
is(@$out, 3, 'three output items');

# If no rules apply, then the 'rules' key is empty
is(@{ $out->[0]{rules} }, 0, 'no rules --> 0');
is($out->[0]{word}, 'qwerty', 'word is qwerty');

# If one rule applies, then it has one element
is(@{ $out->[1]{rules} }, 1, 'one rule --> 1');
is($out->[1]{rules}[0],
   "<-vcd>-><+vcd> /<small>_<small> applies to motor at 2\n",
   'rule 1/1');
is($out->[1]{word}, 'modor', 'word is modor');

# If two rules applied, then it has two elements
is(@{ $out->[2]{rules} }, 2, 'two rules --> 2');
is($out->[2]{rules}[0],
   "<-vcd>-><+vcd> /<small>_<small> applies to bateau at 2\n",
   'rule 1/2');
is($out->[2]{rules}[1],
   "<small>-><cap> /_# applies to badeau at 6\n",
   'rule 2/2');
is($out->[2]{word}, 'badeaU', 'word is badeaU');

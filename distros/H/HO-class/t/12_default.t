
use strict;
use warnings;

use Test::More tests => 2;

package Alphabet;

use HO::class
  _ro => 'alphabet' => sub {['a','b','c']},
  _ro => 'map' => sub {{'a' => 1,'b' => 26,'c' => 8}};
  
package main;

my $a = Alphabet->new;
is_deeply([$a->alphabet],['a','b','c'],'array default');
is_deeply(scalar $a->map, {'a' => 1,'b' => 26,'c' => 8},'hash default');


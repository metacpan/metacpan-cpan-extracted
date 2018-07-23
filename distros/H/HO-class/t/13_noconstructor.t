
use strict;
use warnings;

use Test::More tests => 7;

package Alphabet;

use HO::class
  _ro => 'alphabet' => sub {['a','b','c']},
  _ro => 'map' => sub {{'a' => 1,'b' => 26,'c' => 8}},
  'noconstructor';

package Ab0;

BEGIN { our @ISA = qw(Alphabet); }

use HO::class;

package Ab1;

BEGIN { our @ISA = qw(Alphabet); }

use HO::class 'noconstructor';

sub create
{
  my ($pack) = @_;
  $pack = ref($pack) || $pack;
  bless [ [] , {} ] , $pack
}

package main;

ok( !Alphabet->can('new'),'no constructor');
ok( Ab0->can('new'),'a constructor in derived class');
ok( !Ab1->can('new'),'explicit no constructor in derived class');

my $a = Ab0->new;
is_deeply([$a->alphabet],['a','b','c'],'array default');
is_deeply(scalar $a->map, {'a' => 1,'b' => 26,'c' => 8},'hash default');

my $b = Ab1->create;
is_deeply([$b->alphabet], [], 'custom constructor 1');
is_deeply($b->map, {}, 'custom constructor 2');

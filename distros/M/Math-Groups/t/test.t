use Test::More tests=>57;

use Carp;
use strict;
use utf8;
use Math::Groups;
use Math::Cartesian::Product;
use Math::Permute::List;
use Data::Dump qw(dump);

# c4 - defined via modular addition
my $g = Group {my ($a, $b) = @_; ($a+$b)%4} 0..3;
ok $g->abelian;
ok defined $g->cyclic;
ok !$g->subGroup(1);
ok !$g->subGroup(3);
ok  $g->subGroup(2);
ok $g->homoMorphic($g, 2=>0, 1=>2, 3=>2);
ok 4 == $g->order;
ok 0 == $g->inverse(0); ok !$g->order(0);
ok 1 == $g->inverse(3); ok 4 == $g->order(1);
ok 2 == $g->inverse(2); ok 2 == $g->order(2);
ok 3 == $g->inverse(1); ok 4 == $g->order(3);

if (1)                                                                          # Find automorphisms
 {my $p = '';
  autoMorphisms {$p .= dump({@_})."\n"} $g;
  ok $p eq <<'END';
{ 1 => 1, 2 => 2, 3 => 3 }
{ 1 => 3, 2 => 2, 3 => 1 }
END
 }

# c4 - defined via modular multiplication
my $h = Group {my ($a, $b) = @_; ($a*$b)%5} 1..4;
ok $h->abelian;
ok defined $h->cyclic;

ok $g->isoMorphic($h, 1=>2, 2=>4, 3=>3);
ok $g->isoMorphic($h, 1=>3, 2=>4, 3=>2);

ok $h->isoMorphic($h, 2=>2, 3=>3, 4=>4);
ok $h->isoMorphic($h, 2=>3, 3=>2, 4=>4);

ok !$h->subGroup(2);
ok !$h->subGroup(3);
ok  $h->subGroup(4);
ok 4 == $h->order;
ok 1 == $h->inverse(1); ok !$h->order(1);
ok 2 == $h->inverse(3); ok 4 == $h->order(2);
ok 3 == $h->inverse(2); ok 4 == $h->order(3);
ok 4 == $h->inverse(4); ok 2 == $h->order(4);

if (1)                                                                          # Find automorphisms
 {my $p = '';
  autoMorphisms {$p .= dump({@_})."\n"} $h;
  ok $p eq <<'END';
{ 2 => 2, 3 => 3, 4 => 4 }
{ 2 => 3, 3 => 2, 4 => 4 }
END
 }

if (1)                                                                          # Find isomorphisms
 {my $p = '';
  isoMorphisms {$p .= dump({@_})."\n"} $g, $h;
  ok $p eq <<'END';
{ 1 => 2, 2 => 4, 3 => 3 }
{ 1 => 3, 2 => 4, 3 => 2 }
END
 }

# d2 = Viergruppe = c2*2
my $𝘃 = [cartesian {1} ([1,-1]) x 2];                                           # Elements are corners of a square centred on the origin with radius 1
my $𝕧; map {my ($a, $b) = @{$$𝘃[$_]}; $𝕧->{$a}{$b} = $_} 0..$#$𝘃;               # Corner coordinates to corner number

my $v = Group
 {my ($a, $b, $c, $d) = map {@$_} @$𝘃[@_];                                      # Convert corner numbers to coordinates of corner
	$𝕧->{$a*$c}{$b*$d}                                                            # Multiply corners to get product, return corner number
 } 0..$#$𝘃;

ok  $v->abelian;
ok !$v->cyclic;
ok  $v->subGroup(1);
ok  $v->subGroup(2);
ok  $v->subGroup(3);
ok  $v->autoMorphic(1=>1, 2=>3, 3=>2);                                          # Inner automorphisms
ok  $v->autoMorphic(1=>2, 2=>1, 3=>3);
ok  $v->autoMorphic(1=>3, 2=>2, 3=>1);

ok  $v->autoMorphic(1=>2, 2=>3, 3=>1);                                          # Outer automorphisms
ok  $v->autoMorphic(1=>3, 2=>1, 3=>2);

if (1)
 {my $p = '';
  autoMorphisms {$p .= dump({@_})."\n"} $v;
  ok $p eq <<'END';
{ 1 => 1, 2 => 2, 3 => 3 }
{ 1 => 1, 2 => 3, 3 => 2 }
{ 1 => 2, 2 => 1, 3 => 3 }
{ 1 => 3, 2 => 1, 3 => 2 }
{ 1 => 2, 2 => 3, 3 => 1 }
{ 1 => 3, 2 => 2, 3 => 1 }
END
 }
ok 4 == $v->order;
ok 0 == $v->inverse(0); ok !$v->order(0);
ok 1 == $v->inverse(1); ok 2 == $v->order(1);
ok 2 == $v->inverse(2); ok 2 == $v->order(2);
ok 3 == $v->inverse(3); ok 2 == $v->order(3);

if (1)                                                                          # Find isomorphisms
 {my $p = '';
  isoMorphisms {$p .= dump({@_})."\n"} $g, $v;
  ok !$p;
END
 }

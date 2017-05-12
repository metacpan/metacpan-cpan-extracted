use strict;
use warnings;
use Test::More;

use Inline C => <<'END', structs => 1, force_build => 1;
struct Foo {
  int inum;
  double dnum;
  char *str;
};
END

my $id;
sub refcnt { $Inline::Struct::Foo::_map_{$id}->{REFCNT} }

my $o = Inline::Struct::Foo->new();
($id) = keys %Inline::Struct::Foo::_map_;

is refcnt, 1, 'created';
my $o2 = $o->inum(10);
is refcnt, 2, 'when ref saved';
$o2 = undef;
is refcnt, 1, 'when ref undef-ed';
$o->inum(10);
is refcnt, 1, 'inum';
$o->dnum(3.1415);
is refcnt, 1, 'dnum';
$o->str('Wazzup?');
is refcnt, 1, 'str';
$o->inum(11);
is refcnt, 1, 'inum2';
$o = undef;
ok !exists($Inline::Struct::Foo::_map_{$id}), 'undef2';

done_testing;

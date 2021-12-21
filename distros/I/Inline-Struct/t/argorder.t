use Test::More;
BEGIN { require './t/common.pl'; }

use Inline C => config => inc => q{-DNUMBER=16}, structs => 1;
use Inline C => <<EOF, force_build => 1;
struct Foo {int i;};
typedef struct Foo Foo;

SV *func(Foo *foo) {
  return newSVpvf("i=%d", foo->i + NUMBER);
}
EOF

my $o = Inline::Struct::Foo->new;
$o->i(1);
is func($o), 'i=17';

done_testing;

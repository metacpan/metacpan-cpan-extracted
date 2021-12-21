use strict;
use warnings;
use Test::More;
BEGIN { require './t/common.pl'; }

use Inline C => <<'END', structs => 1, force_build => 1;
struct Foo {
  SV *hash;
};
END

my $o = Inline::Struct::Foo->new();
my $HASH = { a => { b => 'c' } };
$o->hash($HASH);
is_deeply $o->hash, $HASH, "hashref retrieved";

$o = Inline::Struct::Foo->new($HASH);
is_deeply $o->hash, $HASH, "hashref as new retrieved";

done_testing;

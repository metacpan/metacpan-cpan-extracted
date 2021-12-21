use strict;
use warnings;
use Test::More;
BEGIN { require './t/common.pl'; }

use Inline C => <<'END', structs => 1, force_build => 1;
struct Foo {
   SV *src;
   SV *dst;
   SV *other;
   char *prt;
};
END

my @KEYS = qw(src dst prt other);
my $STR = 'longer';
my %VALS = map { ($_ => $STR) } @KEYS;

my $o = Inline::Struct::Foo->new;
$o->$_($STR) for @KEYS;
is $o->$_(), $VALS{$_}, "orig $_" for @KEYS;

my $copy = $o;
is $o->$_(), $VALS{$_}, "orig after copy $_" for @KEYS;
is $copy->$_(), $VALS{$_}, "copy $_" for @KEYS;

done_testing;

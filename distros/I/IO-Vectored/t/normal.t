use strict;
use Test::More tests => 4;

use IO::Vectored;

pipe(my $r1, my $w1) || die "pipe: $!";
pipe(my $r2, my $w2) || die "pipe: $!";

if (!fork) {
  my $val = ' ' x 1000;
  my $len = sysreadv $r1, $val || die "sysreadv: $!";
  $val = substr($val, 0, $len);
  syswritev $w2, $val || die "syswritev: $!";
  exit;
}


my @vector = qw(hello sweet world what is up?);
my $str = join '', @vector;
ok(length($str) % 4 == 0, "chose valid length string");

my $rv = syswritev($w1, @vector) || die "syswritev: $!";
is($rv, length($str), 'syswritev returned right length');

my @vector2 = (' ' x (length($str)/4)) x 4;
my $rv2 = sysreadv($r2, @vector2) || die "sysreadv: $!";
is($rv2, length($str), 'sysreadv returned right length');
is(join('', @vector2), $str, 'round-trip OK');

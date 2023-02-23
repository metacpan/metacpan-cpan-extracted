use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

my $tests = 5;

# Because of the way I (sisyphus) build this module with MS
# Visual Studio, XSubs that take a filehandle as an argument
# do not work. It therefore suits my purposes to be able to
# avoid calling (and testing) those particular XSubs
$tests = 1 if $ENV{SISYPHUS_SKIP};

print "1..$tests\n";

if($tests == 1) {
  warn "\nskipping all tests - \$ENV{SISYPHUS_SKIP} is set\n";
  print "ok 1\n";
  exit 0;
}

my($WR, $RD, $RD2);

open $WR, '>', 'out.txt' or warn "Can't open out.txt for writing: $!";

my $op = Math::MPFI->new(1125);
my $fr = Math::MPFR->new();

Rmpfi_out_str(\*$WR, 10, 0, $op);

close $WR or warn "Can't close out.txt after witing to it: $!";

open $RD, '<', 'out.txt' or warn "Can't open out.txt for reading: $!";

my $str = <$RD>;

chomp($str);

my ($got, $discard) = Rmpfi_init_set_str($str, 10);

Rmpfi_get_left($fr, $got);
if($fr == 1125) {print "ok 1\n"}
else {
  warn "1: \$fr: $fr\n";
  print "not ok 1\n";
}

Rmpfi_get_right($fr, $got);
if($fr == 1125) {print "ok 2\n"}
else {
  warn "2: \$fr: $fr\n";
  print "not ok 2\n";
}

close $RD or warn "Can't close out.txt after reading: $!";


open $RD2, '<', 'out.txt' or warn "Can't re-open out.txt for reading: $!";

my $mpfi = Math::MPFI->new();

Rmpfi_inp_str($mpfi, \*$RD2, 10);

close $RD2 or warn "Can't close out.txt after re-opening it: $!";

Rmpfi_get_left($fr, $mpfi);
if($fr == 1125) {print "ok 3\n"}
else {
  warn "3: \$fr: $fr\n";
  print "not ok 3\n";
}

Rmpfi_get_right($fr, $mpfi);
if($fr == 1125) {print "ok 4\n"}
else {
  warn "4: \$fr: $fr\n";
  print "not ok 4\n";
}


if(!unlink('out.txt')) {
  warn "Failed to remove out.txt\n";
  print "not ok 5\n";
}
else {
  print "ok 5\n";
}

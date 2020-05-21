use Test::More tests => 1;
use POSIX ();

POSIX::setlocale( &POSIX::LC_ALL, "C" );

my $fn;
BEGIN {
  $fn=$0;
  $fn=~s!/*t/+[^/]*$!! or die "Wrong test script location: $0";
  $fn='.' unless( length $fn );
}

use Linux::Smaps ();

my $s=eval { Linux::Smaps->new(filename=>$fn.'/t/testcases/special-then-mem') };
like $@, qr{Linux::Smaps: Linux::Smaps::VMA::special_attribute method is already defined}, "dies with expected message";

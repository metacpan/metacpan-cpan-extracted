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

my $s=eval { Linux::Smaps->new(filename=>$fn.'/t/testcases/empty') };
like $@, qr{Linux::Smaps: .*: read failed: Permission denied}, "dies with expected message";

# Local Variables:
# mode: cperl
# End:

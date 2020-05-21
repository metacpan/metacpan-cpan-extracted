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

my $s1=Linux::Smaps->new(filename=>$fn.'/t/testcases/double-vdso');
my $s2=Linux::Smaps->new(filename=>$fn.'/t/testcases/single-vdso');

my ($newlist, $difflist, $oldlist)=$s1->diff( $s2 );
ok @$newlist==0 && @$difflist==0 && @$oldlist==0,
  'double-vdso match single-vdso';

# Local Variables:
# mode: cperl
# End:

use Test::More tests => 2;
use POSIX ();

POSIX::setlocale( &POSIX::LC_ALL, "C" );

my $fn;
BEGIN {
  $fn=$0;
  $fn=~s!/*t/+[^/]*$!! or die "Wrong test script location: $0";
  $fn='.' unless( length $fn );
}

use Linux::Smaps ();
eval {require Config};
SKIP: {
  skip "64bit support not checked on non-64bit perl", 2
    unless( $Config::Config{use64bitint} || $Config::Config{use64bitall} );
  $s=Linux::Smaps->new(filename=>$fn.'/t/testcases/smaps64');
  my $stack = $s->stack;

  is $stack->size, 132, "smaps64 stack is 132k";
  is $stack->vma_end-$stack->vma_start, 132*1024, "smaps64 stack is 4k via vma_start/end";
}

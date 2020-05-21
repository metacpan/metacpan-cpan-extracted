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

my $s = Linux::Smaps->new(filename=>$fn.'/t/testcases/deleted');
is scalar @{[$s->vmas]}, 1, "just a single vma";
ok(($s->vmas)[0]->is_deleted, "found a deleted vma");

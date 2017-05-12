use Test::More tests => 13;
use POSIX ();

POSIX::setlocale( &POSIX::LC_ALL, "C" );
my ($s, $old);

my $fn;
BEGIN {
  $fn=$0;
  $fn=~s!/*t/+[^/]*$!! or die "Wrong test script location: $0";
  $fn='.' unless( length $fn );
}

use Linux::Smaps (filename=>$fn.'/t/smaps');

$s=Linux::Smaps->new(uninitialized=>1);
$s->filename=$fn.'/t/smaps';
$s->update;
ok( ($s->vmas)[0]->file_name eq '/opt/apache22-worker/sbin/httpd',
    'filename parameter to new()' );

$s=Linux::Smaps->new(procdir=>$fn, pid=>'t');
ok( ($s->vmas)[0]->file_name eq '/opt/apache22-worker/sbin/httpd',
    'procdir parameter to new()' );

ok( ($s->vmas)[8]->file_name eq '/home/r2/work/mp2/trunk/trunk/blib/arch/auto/APR/Pool/Pool.so',
    '(deleted) vma file_name' );

ok( !($s->vmas)[0]->is_deleted, 'existing vma is not deleted' );

ok( ($s->vmas)[8]->is_deleted, '(deleted) vma is deleted' );
ok( $s->stack->size==92, 'size check' );
ok( $s->stack->vma_end-$s->stack->vma_start==92*1024, 'size check 2' );

eval {require Config};
SKIP: {
  skip "64bit support not checked on non-64bit perl", 4
    unless( $Config::Config{use64bitint} || $Config::Config{use64bitall} );
  $s=Linux::Smaps->new(filename=>$fn.'/t/smaps64');
  $s=($s->vmas)[431];
  ok( $s->file_name eq '/dev/zero', 'smaps64 name is /dev/zero' );
  ok( $s->is_deleted, 'smaps64 is_deleted==1' );
  ok( $s->size==88, 'smaps64 size=88' );
  ok( $s->vma_end-$s->vma_start==88*1024, 'smaps64 vma_end-vma_start=88*1024' );
}

SKIP: {
  skip "64bit overflow not checked on 64bit perl", 1
    if( $Config::Config{use64bitint} || $Config::Config{use64bitall} );
  eval {(Linux::Smaps->new(filename=>$fn.'/t/smaps64')->vmas)[0]->vma_start};
  like( $@, qr/Integer overflow in hexadecimal number/, "integer overflow" );
}

my $s1=Linux::Smaps->new(filename=>$fn.'/t/double-vdso');
my $s2=Linux::Smaps->new(filename=>$fn.'/t/single-vdso');

my ($newlist, $difflist, $oldlist)=$s1->diff( $s2 );
ok @$newlist==0 && @$difflist==0 && @$oldlist==0,
  'double-vdso match single-vdso';

# Local Variables:
# mode: perl
# End:

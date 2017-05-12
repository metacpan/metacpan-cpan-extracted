use Test::More tests => 11;
use POSIX ();

POSIX::setlocale( &POSIX::LC_ALL, "C" );
my ($s, $old);

my $fn;
BEGIN {
  $fn=$0;
  $fn=~s!/*t/+[^/]*$!! or die "Wrong test script location: $0";
  $fn='.' unless( length $fn );
}

use Linux::Smaps ();

eval {require Config};
SKIP: {
  skip "non-64bit perl", 11
    unless( $Config::Config{use64bitint} || $Config::Config{use64bitall} );
  my $s=eval {Linux::Smaps->new(filename=>$fn.'/t/smaps-VmFlags')};
  isa_ok $s, 'Linux::Smaps';
  is_deeply +($s->vmas)[0]->vmflags, [qw/rd ex mr mw me dw/], 'vmflags';
  is +($s->vmas)[0]->file_name, '/bin/cat', 'filename';
  is_deeply $s->heap->vmflags, [qw/rd wr mr mw me ac/], '[heap] vmflags';
  is $s->heap->file_name, '[heap]', '[heap] filename';
  is_deeply $s->stack->vmflags, [qw/rd wr mr mw me gd ac/], '[stack] vmflags';
  is $s->stack->file_name, '[stack]', '[stack] filename';
  is_deeply $s->vdso->vmflags, [qw/rd ex mr mw me de/], '[vdso] vmflags';
  is $s->vdso->file_name, '[vdso]', '[vdso] filename';
  is_deeply $s->vsyscall->vmflags, [qw/rd ex/], '[vsyscall] vmflags';
  is $s->vsyscall->file_name, '[vsyscall]', '[vsyscall] filename';
}

# Local Variables:
# mode: perl
# End:

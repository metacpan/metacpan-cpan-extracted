use Test::More tests => 6;
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

my $s=eval {Linux::Smaps->new(filename=>$fn.'/t/testcases/smaps32')};
is_deeply $s->heap->vmflags, [qw/rd wr mr mw me ac/], '[heap] vmflags';
is $s->heap->file_name, '[heap]', '[heap] filename';
is_deeply $s->stack->vmflags, [qw/rd wr mr mw me gd ac/], '[stack] vmflags';
is $s->stack->file_name, '[stack]', '[stack] filename';
is_deeply $s->vdso->vmflags, [qw/rd ex mr mw me de/], '[vdso] vmflags';
is $s->vdso->file_name, '[vdso]', '[vdso] filename';

# Local Variables:
# mode: cperl
# End:

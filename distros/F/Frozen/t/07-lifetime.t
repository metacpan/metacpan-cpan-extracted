#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use File::Temp ();
use Scalar::Util qw(weaken);
use Config;

# The string-lifetime rule, proved rather than assumed.
#
# The hazard: an SV whose PV points into a mapping, outliving the mapping. It
# has bitten this workspace before, and it bit in the worst way - the tests
# passed, because the page happened not to be reused before the process
# exited. So every assertion here that could crash runs in a CHILD, where a
# crash is an exit status the parent can assert on rather than a dead test
# run.

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $path = "$dir/cat.frz";
my %data = (greeting => 'hello world, a string long enough to be a real one',
            other    => 'second');
Frozen->freeze_to($path, \%data);

my $poison = $ENV{FZ_DEBUG_POISON} ? 1 : 0;
diag($poison ? 'built with -DFZ_DEBUG_POISON: a stale pointer must fault'
             : 'ordinary build: a stale pointer may or may not fault, which '
             . 'is exactly why the poison build exists');

# ---- the default is a copy, and a copy survives the close ----------------

{
    my $fz   = Frozen->open($path);
    my $slot = $fz->find('greeting');
    ok(defined $slot, 'found the key');
    my $str = $fz->string_at($slot);
    is($str, $data{greeting}, 'and read the string');

    $fz->close;
    is($str, $data{greeting},
       'the string still holds its bytes after the container closed - '
     . 'because the default is a copy, not a borrow');
}

# ---- borrow is not offered, and the reason is Perl ----------------------
#
# A borrowed string would be an SV whose PV points into the mapping. It cannot
# be delivered: `my $s = $fz->string_at(...)` ASSIGNS, and assignment copies,
# so the caller gets a copy of the borrowed SV rather than the borrowed SV.
# Returning a reference instead would make every caller write `$$s` to save a
# memcpy, which is a worse API than the thing it saves.

{
    my $fz = Frozen->open($path);
    ok(!$fz->can('borrow'), 'there is no borrow door on the Perl side');
    my $s = $fz->string_at($fz->find('greeting'));
    $fz->close;
    is($s, $data{greeting},
       'so every string survives its container by construction, not by care');
}

# ---- the crash cases, in a child -----------------------------------------
#
# A borrowed string whose container was closed by hand. Under the poison build
# this MUST fault; under an ordinary build it may quietly work, and the test
# says which it is rather than pretending the two are the same.

{
    my $prog = <<'CODE';
use strict; use warnings;
use Frozen ();
my $path = shift;
my $fz   = Frozen->open($path);
my $s    = $fz->string_at($fz->find('greeting'));
$fz->close;              # explicit close, with the string still in hand
my $len  = length $s;    # touches the PV
print "read $len\n";
CODE
    my $file = "$dir/child.pl";
    open my $fh, '>', $file or die $!;
    print {$fh} $prog;
    close $fh;

    my @inc = map { "-I$_" } grep { !ref } @INC;
    my $out = `"$^X" @inc "$file" "$path" 2>&1`;
    my $rc  = $?;

    # With copies, this MUST succeed on every build, poisoned or not. That is
    # the point of copying: the poison build cannot find a stale pointer
    # because there is no way to hold one.
    is($rc, 0, 'a string read before close survives it, under any build');
    like($out, qr/read \d+/, 'and still has its bytes');
}

# ---- global destruction ---------------------------------------------------
#
# A container in a global, torn down at exit. `$^X -w` in a temp file rather
# than -e with angle brackets, because those are cmd.exe redirection on Win32.

{
    my $file = "$dir/global.pl";
    open my $fh, '>', $file or die $!;
    print {$fh} <<'CODE';
use strict; use warnings;
use Frozen ();
our $KEPT = Frozen->open($ARGV[0]);
print "ok\n";
CODE
    close $fh;
    my @inc = map { "-I$_" } grep { !ref } @INC;
    my $out = `"$^X" -w @inc "$file" "$path" 2>&1`;
    like($out, qr/^ok$/m, 'a container in a global tears down at exit');
    unlike($out, qr/warn|uninitial|during global/i,
           'without a warning during global destruction')
        or diag $out;
}

# ---- fork -----------------------------------------------------------------
#
# The point of the whole dist: a container mapped in the parent is readable in
# every child, and closing it in one does not disturb another.

SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';
    my $fz = Frozen->open($path);
    pipe(my $r, my $w) or die $!;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $r;
        my $v = $fz->string_at($fz->find('greeting'));
        print {$w} (($v eq $data{greeting}) ? "child-ok\n" : "child-bad\n");
        $fz->close;                  # closing here must not touch the parent
        close $w;
        exit 0;
    }
    close $w;
    chomp(my $said = <$r> // '');
    close $r;
    waitpid $pid, 0;
    is($said, 'child-ok', 'a child reads the mapping the parent made');
    is($fz->string_at($fz->find('greeting')), $data{greeting},
       'and the parent still reads after the child closed its copy');
}

done_testing;

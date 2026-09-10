#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use File::Temp ();

# THE PERMANENT GATE, and the reason Phase 01's benchmark was not the end of
# the measurement. A benchmark proves a claim once; this keeps proving it.
#
# Skips where it cannot be answered honestly rather than passing vacuously:
# /proc/self/smaps_rollup is the only thing that separates shared from
# private, and `ps -o rss` counts shared pages in full in every process, so it
# would report the sharing as already gone and pass a design that does
# nothing.

plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';
plan skip_all => 'needs /proc/self/smaps_rollup, which only Linux has'
    unless -r '/proc/self/smaps_rollup';

sub pss_kib {
    open my $fh, '<', '/proc/self/smaps_rollup' or return 0;
    my %v;
    while (<$fh>) { $v{$1} = $2 if /^(\w+):\s+(\d+) kB/ }
    close $fh;
    return ($v{Pss} || 0, $v{Private_Dirty} || 0);
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $N   = 20_000;

# The block is built in a CHILD that exits, so the measuring parent never
# allocated it - which is what a deploy-time artifact actually looks like, and
# what Phase 01 had to fix to measure anything meaningful. Perl does not
# return freed memory to the OS, so a parent that BUILT the data carries its
# peak for the rest of its life.
my $path = "$dir/big.frz";
{
    my $pid = fork; die "fork: $!" unless defined $pid;
    if (!$pid) {
        my %h = map { ("key$_" => "a translated string for key $_") } 1 .. $N;
        Frozen->freeze_to($path, \%h);
        exit 0;
    }
    waitpid $pid, 0;
}
ok(-s $path, 'the block was built out of process');

my $W = 4;
my $K = 5_000;

# The control: the same data as a Perl hash, preloaded before the fork. This
# is what Frozen is being compared against, measured in the same run rather
# than quoted from a benchmark that ran on another day.
sub pool {
    my ($setup, $read) = @_;
    my $ctx = $setup->();
    pipe(my $r, my $w) or die $!;
    my @kids;
    for my $i (1 .. $W) {
        my $pid = fork; die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $r;
            srand(1000 + $i);
            $read->($ctx, $K);
            my ($pss, $pd) = pss_kib();
            print {$w} "$pss $pd\n";
            close $w;
            exit 0;
        }
        push @kids, $pid;
    }
    close $w;
    my ($pss, $pd) = (0, 0);
    while (my $l = <$r>) { my @f = split ' ', $l; $pss += $f[0]; $pd += $f[1] }
    close $r;
    waitpid $_, 0 for @kids;
    my ($ppss, $ppd) = pss_kib();
    return ($ppss + $pss, $ppd + $pd);
}

my ($fz_pss, $fz_pd) = pool(
    sub { Frozen->open($path) },
    sub { my ($fz, $k) = @_;
          my $root = $fz->root;
          my $s = 0;
          for (1 .. $k) {
              my ($v) = $fz->fetch($root, "key" . (1 + int rand $N));
              $s += length($v || '');
          }
          return $s; },
);

my ($pl_pss, $pl_pd) = pool(
    sub { my %h = map { ("key$_" => "a translated string for key $_") } 1 .. $N;
          \%h },
    sub { my ($h, $k) = @_;
          my $s = 0;
          for (1 .. $k) { $s += length($h->{"key" . (1 + int rand $N)} || '') }
          return $s; },
);

diag(sprintf "pool Pss: Frozen %d KiB, Perl hash %d KiB", $fz_pss, $pl_pss);
diag(sprintf "pool private_dirty: Frozen %d KiB, Perl hash %d KiB", $fz_pd, $pl_pd);

cmp_ok($fz_pss, '<', $pl_pss,
       'a pool reading a Frozen block costs less Pss than the same pool '
     . 'reading a preloaded Perl hash');

# A threshold derived from the file size rather than a hard-coded number, so
# it stays meaningful if the data changes.
my $blocksize = int((-s $path) / 1024);
cmp_ok($fz_pd, '<', $pl_pd,
       'and less private_dirty - the pages the block occupies are shared, '
     . "not copied per worker (block is ${blocksize} KiB)");

done_testing;

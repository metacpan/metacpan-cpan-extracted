#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

# End-to-end exercise of the marshal layer: we drive _send_job_xs from
# the parent and _worker_loop_xs from a forked child via a real pipe,
# then verify the file the worker materialised on disk matches what we
# sent. This catches endianness / length-overflow regressions in
# marshal.c without needing a separate C harness.

if ($^O eq 'MSWin32') {
    plan skip_all => 'requires fork(2)';
}

my $dir = tempdir(CLEANUP => 1);

pipe(my $job_r, my $job_w) or die "pipe: $!";
pipe(my $err_r, my $err_w) or die "pipe: $!";

my $pid = fork();
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    close $job_w; close $err_r;
    File::Raw::Archive::_worker_loop_xs(fileno($job_r), fileno($err_w));
    close $job_r; close $err_w;
    require POSIX;
    POSIX::_exit(0);
}
close $job_r;
close $err_w;

# Test 1: simple ASCII file, no xattrs, integer mtime.
{
    my $out = "$dir/plain.txt";
    File::Raw::Archive::_send_job_xs(
        fileno($job_w),
        $out,
        "hello, world\n",
        0644,           # mode
        1735689600,     # mtime
        0,              # mtime_ns
        501,            # uid
        20,             # gid
        0,              # apply_xattrs
        undef,          # xattrs
    );
}

# Test 2: binary content with NULs, sub-second mtime, larger than the
# stack buffer just to make sure the chunked write path works.
my $binary = join '', map { pack('N', $_) } 1 .. 100_000;
{
    my $out = "$dir/binary.bin";
    File::Raw::Archive::_send_job_xs(
        fileno($job_w),
        $out,
        $binary,
        0600,
        1700000000,
        500_000_000,    # half-second
        1000,
        1000,
        0,
        undef,
    );
}

# Test 3: xattrs (binary value) round-trip via the wire.
{
    my $out = "$dir/with-xattrs.txt";
    File::Raw::Archive::_send_job_xs(
        fileno($job_w),
        $out,
        "labelled\n",
        0644, 0, 0, 0, 0,
        1,
        { 'user.label' => 'foo', 'user.bin' => "\x00\xff\x01" },
    );
}

# Signal end-of-jobs and reap the worker.
close $job_w;

# Drain any error lines (should be empty on success).
my @errors;
while (defined(my $line = readline($err_r))) {
    chomp $line;
    push @errors, $line;
}
close $err_r;
waitpid($pid, 0);

is(scalar @errors, 0, 'worker reported no errors')
    or diag("worker errors:\n  " . join("\n  ", @errors));

# Verify file 1.
ok(-f "$dir/plain.txt", 'plain.txt exists');
{
    open my $fh, '<:raw', "$dir/plain.txt" or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    is($content, "hello, world\n", 'plain.txt content matches');
}

# Verify file 2.
ok(-f "$dir/binary.bin", 'binary.bin exists');
is(-s "$dir/binary.bin", length($binary), 'binary.bin size matches');
{
    open my $fh, '<:raw', "$dir/binary.bin" or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    is($content, $binary, 'binary.bin bytes match (round-trips u32 endianness)');
}

# Verify file 3.
ok(-f "$dir/with-xattrs.txt", 'with-xattrs.txt exists');
{
    open my $fh, '<:raw', "$dir/with-xattrs.txt" or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    is($content, "labelled\n", 'with-xattrs content matches');
}

done_testing;

use v5.36;
use strict;
use warnings;

use File::Find qw(find);
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Test::More;

my $root = "$Bin/..";
my @pod_file;
find(
    sub {
        return if !-f || !/\.pm\z/;
        push @pod_file, $File::Find::name;
    },
    "$root/lib/Linux",
);

my $count = 0;
for my $file (sort @pod_file) {
    open my $fh, '<', $file or die "open $file: $!";
    my $source = do { local $/; <$fh> };
    close $fh;
    next if $source !~ /^=head1 SYNOPSIS\s*\n(.*?)(?=^=head1\s)/ms;

    # SYNOPSIS may interleave prose with verbatim Perl paragraphs.
    my $synopsis = join "\n\n", grep { /\A[ \t]+\S/ }
        split /\n[ \t]*\n/, $1;
    ok(length($synopsis), "$file SYNOPSIS contains Perl examples");
    $synopsis =~ s/^  //mg;
    $synopsis =~ s/\A\s+|\s+\z//g;
    $synopsis = "use v5.36;\n$synopsis\n";
    $count++;

    my ($program, $path) = tempfile('linux-event-pod-XXXXXX',
        SUFFIX => '.pl', TMPDIR => 1, UNLINK => 1);
    print {$program} $synopsis or die "write $path: $!";
    close $program or die "close $path: $!";

    my $error = gensym;
    my $pid = open3(undef, my $output, $error,
        $^X, "-I$root/blib/lib", "-I$root/blib/arch", '-c', $path);
    my $stdout = do { local $/; <$output> } // '';
    my $stderr = do { local $/; <$error> } // '';
    waitpid($pid, 0);
    my $status = $? >> 8;
    my $name = $file =~ s{\A\Q$root/\E}{}r;
    is($status, 0, "$name SYNOPSIS compiles")
        or diag("Extracted SYNOPSIS:\n$synopsis\n$stdout$stderr");

    if (!$status && $name eq 'lib/Linux/Event/IO/Pipe.pm') {
        my $run_error = gensym;
        my $run_pid = open3(undef, my $run_output, $run_error,
            $^X, "-I$root/blib/lib", "-I$root/blib/arch", $path);
        my $run_stdout = do { local $/; <$run_output> } // '';
        my $run_stderr = do { local $/; <$run_error> } // '';
        waitpid($run_pid, 0);
        is($? >> 8, 0, "$name SYNOPSIS runs")
            or diag($run_stdout . $run_stderr);
        like($run_stdout, qr/^Received: hello\n\z/,
            "$name SYNOPSIS produces the documented result");
    }
}

ok($count >= 10, 'checked the documented public SYNOPSIS examples');
done_testing;

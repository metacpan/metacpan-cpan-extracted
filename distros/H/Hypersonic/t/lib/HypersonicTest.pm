package HypersonicTest;
# Shared helpers for fork+server+probe tests.
#
# The key job: capture the forked server child's STDERR/STDOUT to a
# temp file so that when wait_for_port times out we can diag() the
# actual error. Without this, CPAN tester reports just show "Server
# failed to start" with zero clue why the child died (this is what
# the OpenBSD smoke reports for Hypersonic 0.13 looked like).
use strict;
use warnings;
use Exporter 'import';
use IO::Socket::INET;
use File::Temp ();
use Test::More ();

our @EXPORT_OK = qw(spawn_server wait_for_port diag_child_log);

# spawn_server(\&child_code) -> ($pid, $log_path)
#
# Forks; in the child, redirects STDERR+STDOUT to a tempfile then runs
# the caller's coderef. Returns ($pid, $log_path) to the parent so it
# can later cat $log_path on failure.
sub spawn_server {
    my $child_code = shift;
    my $log = File::Temp->new(SUFFIX => '.log', UNLINK => 0);
    my $log_path = $log->filename;
    close $log;

    my $pid = fork();
    die "Fork failed: $!" unless defined $pid;
    if ($pid == 0) {
        # Child: redirect both streams to the log so anything the
        # server prints (or croaks with) survives the fork boundary.
        # We open + dup2 at the fd level (via POSIX::dup2) so that C
        # code in the JIT-loaded .so that writes directly with
        # fprintf(stderr,...) or write(2,...) also lands in the log.
        # Pure `open STDERR, ...` only redirects Perl's PerlIO layer
        # and can leave C stdio still pointing at the original fd 2,
        # which is why earlier CPAN tester reports showed
        # "(child wrote no output)" - the croak DID happen but its
        # bytes went to a closed fd.
        require POSIX;
        open(my $log_fh, '>', $log_path) or die "open log: $!";
        $log_fh->autoflush(1);
        POSIX::dup2(fileno($log_fh), 1) or die "dup2 stdout: $!";
        POSIX::dup2(fileno($log_fh), 2) or die "dup2 stderr: $!";
        # Re-open Perl's STDOUT/STDERR onto the now-redirected fds so
        # `print` / `warn` from Perl also reach the log.
        open STDOUT, '>&=', 1 or die "reopen stdout: $!";
        open STDERR, '>&=', 2 or die "reopen stderr: $!";
        select STDERR; $| = 1;
        select STDOUT; $| = 1;
        # Make sure any C-level stdio buffers get flushed if the
        # child dies via croak/exit/SIGPIPE rather than reaching the
        # explicit exit() below.
        eval { $child_code->(); };
        my $err = $@;
        STDOUT->flush;
        STDERR->flush;
        if ($err) {
            print STDERR "child died: $err\n";
            POSIX::_exit(70);  # EX_SOFTWARE
        }
        POSIX::_exit(0);
    }
    return ($pid, $log_path);
}

# wait_for_port($port [, $opts]) -> 1 / 0
#
# Probes 127.0.0.1:$port until something accepts or we give up. On
# timeout, if $opts->{log} is given, diag()s the child's captured
# output; if $opts->{pid} is given, diag()s the child's exit status.
sub wait_for_port {
    my ($port, $opts) = @_;
    $opts //= {};
    my $max_tries = $opts->{tries} // 50;

    for (1 .. $max_tries) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 0.1,
        );
        if ($sock) { close $sock; return 1; }
        select undef, undef, undef, 0.1;
    }

    # Server didn't come up - surface as much detail as we can.
    if ($opts->{pid}) {
        my $waited = waitpid($opts->{pid}, 1);  # WNOHANG
        if ($waited == $opts->{pid}) {
            Test::More::diag("Child server exited prematurely "
                . "(wstat=$?, exit=" . ($? >> 8)
                . ", signal=" . ($? & 0x7f) . ")");
        } else {
            Test::More::diag("Child server still alive but not "
                . "listening on port $port; killing");
            kill 'TERM', $opts->{pid};
        }
    }
    if ($opts->{log}) {
        diag_child_log($opts->{log});
    }
    return 0;
}

# diag_child_log($path) - dump captured child output via diag,
# truncating absurdly long output so a runaway child can't drown the
# test summary.
sub diag_child_log {
    my $path = shift;
    return unless -e $path;
    open my $fh, '<', $path or do {
        Test::More::diag("(could not read child log $path: $!)");
        return;
    };
    local $/;
    my $content = <$fh>;
    close $fh;
    if (!defined $content || $content eq '') {
        Test::More::diag("(child wrote no output to $path)");
        return;
    }
    # Cap at 8KB
    if (length($content) > 8192) {
        $content = substr($content, 0, 8192) . "\n[...truncated]\n";
    }
    Test::More::diag("--- captured server child output ---\n$content"
                   . "--- end child output ---");
}

1;

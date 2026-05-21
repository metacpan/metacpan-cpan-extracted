use Test2::V0;
use Test2::IPC;

use POSIX();
use Time::HiRes qw/sleep time/;
use File::Spec;
use File::Temp qw/tempdir/;

use IPC::Manager qw/ipcm_service/;

# Regression coverage for the parent-side strip of `exec.stay_in_begin`.
# ipcm_service() used to `delete $params{exec}` before serialising
# %params for the exec'd child, so the child always saw $params->{exec}
# as undef and silently fell back to the runtime "-e fires service"
# path even when stay_in_begin = 1 was requested. With the fix in
# place, the child's run() must be on the stack at BEGIN time of the
# -e snippet -- i.e. _post_exec_run must NOT appear in run()'s caller
# stack.

my $tmp     = tempdir(CLEANUP => 1);
my $marker  = File::Spec->catfile($tmp, 'caller_stack');
my $svc_dir = File::Spec->catdir($tmp, 'lib');

mkdir $svc_dir or die "mkdir $svc_dir: $!";

my $svc_file = File::Spec->catfile($svc_dir, 'TestStayInBeginXportSvc.pm');
open my $fh, '>', $svc_file or die "open $svc_file: $!";
print $fh <<'PERL';
package TestStayInBeginXportSvc;
use strict;
use warnings;

use Object::HashBase qw{
    <name <orig_io <ipcm_info <watch_pids <redirect <marker
};
use Role::Tiny::With;

sub pid     { $_[0]->{pid} }
sub set_pid { $_[0]->{pid} = $_[1] }

sub handle_request        { return undef }
sub run_returns_to_caller { 1 }

sub run {
    my $self = shift;

    # Capture the full caller stack so the parent test can assert
    # that this run() was invoked from inside BEGIN (via $code in
    # State::import) and NOT from runtime via _post_exec_run.
    my @stack;
    for (my $i = 0;; $i++) {
        my @c = caller($i);
        last unless @c;
        push @stack, $c[3];
    }

    open my $mfh, '>', $self->{marker} or die "open $self->{marker}: $!";
    print $mfh "$_\n" for @stack;
    close $mfh;

    return 0;
}

with 'IPC::Manager::Role::Service';

1;
PERL
close $fh;

my @inc_flags = map { "-I$_" } grep { !ref($_) } @INC;

# Run the ipcm_service() call in a forked middle process so the test
# itself never has to swallow the inevitable "Timeout waiting for
# service to come up" croak. Our test service does not bring up an
# IPC bus -- it longjumps out of run() and returns -- so the parent
# side of ipcm_service will time out on the ready handshake. The
# grandchild (the exec'd perl) writes the marker independently before
# its own exit, well before the parent's timeout fires.
my $errlog = File::Spec->catfile($tmp, 'middle.err');
my $pid = fork // die "fork: $!";
if (!$pid) {
    # ipcm_service does a require_mod on $params{class} on the
    # parent side before fork+exec, so $svc_dir must be in @INC here
    # in addition to being passed via -I to the exec'd child.
    unshift @INC, $svc_dir;

    my $handle;
    eval {
        # Scalar (not void) context so $return_handle is set inside
        # ipcm_service; the exec branch builds a handle and waits
        # for ready either way.
        $handle = ipcm_service(
            'xport_svc',
            class   => 'TestStayInBeginXportSvc',
            timeout => 1,
            marker  => $marker,
            exec    => {
                cmd           => [@inc_flags, "-I$svc_dir"],
                stay_in_begin => 1,
            },
        );
        1;
    } or do {
        my $err = $@ // '';
        if (open my $efh, '>', $errlog) {
            print $efh $err;
            close $efh;
        }
    };
    POSIX::_exit(0);
}

waitpid($pid, 0);

# The grandchild was reparented to init when the middle process
# exited, so poll for its marker rather than waitpid'ing on it.
my $deadline = time + 30;
sleep(0.05) until -e $marker || time > $deadline;

ok(-e $marker, "exec'd grandchild ran run() and wrote the caller-stack marker")
    or do {
        diag("no marker at $marker; exec.stay_in_begin may not have been transported");
        if (-e $errlog) {
            open my $efh, '<', $errlog;
            local $/;
            diag("middle process eval error:\n" . <$efh>);
        }
    };

if (-e $marker) {
    open my $rfh, '<', $marker or die "open $marker: $!";
    chomp(my @stack = <$rfh>);
    close $rfh;

    diag("caller stack from grandchild run():\n  " . join("\n  ", @stack))
        if $ENV{TEST_VERBOSE};

    my $has_post_exec_run = grep { $_ eq 'IPC::Manager::Service::State::_post_exec_run' } @stack;
    ok(!$has_post_exec_run,
        "_post_exec_run is NOT in run()'s caller stack -- stay_in_begin took effect");

    # The setjump-body anon sub inside _ipcm_service is the immediate
    # caller of run() in both code paths, so confirm that at least
    # _ipcm_service is somewhere on the stack (sanity check that we
    # actually captured a real caller chain rather than an empty list).
    my $has_ipcm_service = grep { $_ eq 'IPC::Manager::Service::State::_ipcm_service' } @stack;
    ok($has_ipcm_service, "_ipcm_service is on the caller stack (sanity check)");
}

done_testing;

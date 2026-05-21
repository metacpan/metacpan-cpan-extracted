use Test2::V0;
use Test2::IPC;

use File::Spec;
use File::Temp qw/tempdir/;
use IPC::Manager::Serializer::JSON;

# Minimal Role::Service consumer that:
#   * overrides run() with a setjump frame that is immediately longjumped
#   * writes a marker file after the longjump returns ("POST-JUMP" sentinel)
#   * returns 0 from run()
#   * opts into run_returns_to_caller so _ipcm_service must return rather
#     than exit, completing the exec.stay_in_begin = 1 BEGIN-return path
#
# Lives on disk in the tempdir so the exec'd perl can load it via @INC.

my $tmp = tempdir(CLEANUP => 1);

my $marker = File::Spec->catfile($tmp, 'post_jump_marker');

my $svc_dir = File::Spec->catdir($tmp, 'lib');
mkdir $svc_dir or die "mkdir $svc_dir: $!";

my $svc_file = File::Spec->catfile($svc_dir, 'TestStayInBeginSvc.pm');
open my $fh, '>', $svc_file or die "open $svc_file: $!";
print $fh <<'PERL';
package TestStayInBeginSvc;
use strict;
use warnings;

use Long::Jump qw/setjump longjump/;

use Object::HashBase qw{
    <name <orig_io <ipcm_info <watch_pids <redirect <marker
};
use Role::Tiny::With;

sub pid     { $_[0]->{pid} }
sub set_pid { $_[0]->{pid} = $_[1] }

sub handle_request { return undef }

sub run_returns_to_caller { 1 }

sub run {
    my $self = shift;

    my $payload = setjump unit_test_jump => sub {
        longjump unit_test_jump => 'handed', 'off';
    };

    die "setjump did not return longjump payload" unless ref($payload) eq 'ARRAY';
    die "longjump payload not preserved"           unless "@$payload" eq 'handed off';

    open my $mfh, '>', $self->{marker} or die "open $self->{marker}: $!";
    print $mfh "POST-JUMP\n";
    close $mfh;

    return 0;
}

with 'IPC::Manager::Role::Service';

1;
PERL
close $fh;

my %params = (
    name      => 'stay_in_begin_test',
    class     => 'TestStayInBeginSvc',
    ipcm_info => 'unused',
    marker    => $marker,
);

my $json = IPC::Manager::Serializer::JSON->serialize(\%params);

# The wire format that State.pm itself uses for the exec.stay_in_begin = 1
# path is the inline "exec(_post_exec_run())" -e snippet plus the JSON blob
# on @ARGV. _post_exec_run() is what fires the synchronous _ipcm_service
# call from inside State::import, so any failure to return out of that call
# will leave $exit = 255 and the exec'd perl will exit 255.

# Make sure the exec'd perl can find this dist's lib and the on-disk test
# service class.
my @inc_flags = map { "-I$_" } grep { !ref($_) } @INC;

# Spawn the BEGIN-return path. We do this directly with fork+exec rather
# than ipcm_service() because ipcm_service blocks waiting for the spawned
# service to signal that it is ready, and a service that uses run() to
# longjump out and immediately return cannot service that handshake.
my $pid = fork // die "fork: $!";
if (!$pid) {
    exec(
        $^X,
        @inc_flags,
        "-I$svc_dir",
        "-MIPC::Manager::Service::State",
        "-e" => "exit(IPC::Manager::Service::State\::_post_exec_run())",
        $json,
    ) or die "exec: $!";
}

waitpid($pid, 0);
my $status = $?;
my $exit   = $status >> 8;

ok(-e $marker, "POST-JUMP marker file was written by the service's run()");

if (-e $marker) {
    open my $rfh, '<', $marker or die "open $marker: $!";
    my $contents = do { local $/; <$rfh> };
    close $rfh;
    is($contents, "POST-JUMP\n", "marker file contents are the POST-JUMP sentinel");
}

is($status, 0, "child exited cleanly (signal 0, no core)");
is($exit, 0, "exit code is 0 -- _ipcm_service returned through BEGIN");

done_testing;

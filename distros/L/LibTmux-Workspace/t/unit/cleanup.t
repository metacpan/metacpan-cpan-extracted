use v5.44;
use Test2::V1;
use JSON::PP     ();
use MIME::Base64 qw(decode_base64);
use LibTmux::Workspace;
use LibTmux::Server;
use LibTmux::Snapshot;
use LibTmux::CommandResult;

package FailedWorkspaceCleanup {
    use parent 'LibTmux::Server';
    sub snapshot    ($self) { LibTmux::Snapshot->from_records(sessions => []) }
    sub new_session ($self, %args) { die $self->{primary} }

    sub kill_session ($self, %args) {
        $self->{cleanup_target} = $args{session};
        die $self->{cleanup};
    }
}

my $owned = LibTmux::Snapshot->from_records(
    server_id  => 'owned-socket',
    generation => 'old-generation',
    sessions   => [{id => '$0'}],
    complete   => false,
)->sessions->one;
my $workspace = LibTmux::Workspace->new(
    config => {
        schema   => 'libtmux.workspace/v1',
        sessions => [
            {
                name    => 'owned',
                windows => [{panes => [{command => ['unused']}]}],
            }
        ],
    }
);
my $cause   = LibTmux::X::Codec->new(message => 'capture failed');
my $primary = LibTmux::X::Creation->new(
    message    => 'created before capture failed',
    created    => $owned,
    cause      => $cause,
    dispatched => true,
);
my $result = bless {
    stdout     => "partial\0\xff",
    stderr     => "rejected\n",
    exit_code  => 1,
    signal     => 0,
    raw_status => 256,
    },
    'LibTmux::CommandResult';
for my $kind (qw(NoSuchTarget StaleReference Command Timeout)) {
    my $cleanup = "LibTmux::X::$kind"->new(
        message    => 'cleanup failed',
        dispatched => false,
        result     => $result,
    );
    my $server = FailedWorkspaceCleanup->new;
    $server->{primary} = $primary;
    $server->{cleanup} = $cleanup;
    my $error;
    try { $workspace->load(server => $server) } catch ($caught) {
        $error = $caught
    }
    T2->is(refaddr($error->cause),
        refaddr($primary), 'primary exception identity survives');
    T2->is(refaddr($server->{cleanup_target}),
        refaddr($owned), 'rollback uses the owned receipt');
    my $entry = $error->report->{cleanup_errors}[0];
    T2->is(ref($entry), 'HASH', "$kind cleanup retains structured context");
    next unless ref($entry) eq 'HASH';
    T2->is($entry->{target}, $owned->identity,
        'cleanup identifies the captured generation');
    T2->is($entry->{action}, 'kill_session',
        'cleanup identifies the attempted action');
    T2->is(refaddr($entry->{error}),
        refaddr($cleanup), 'cleanup exception identity survives');
    my $data = $error->report_data;
    my $wire = JSON::PP->new->core_bools->decode(JSON::PP->new->encode($data));
    my $failure = $wire->{cleanup_errors}[0]{error};
    T2->is($failure->{class}, "LibTmux::X::$kind",
        'JSON retains the exception class');
    T2->is($failure->{dispatched},
        false, 'JSON preserves false dispatch evidence');
    T2->is(decode_base64($failure->{result}{stdout_base64}),
        $result->stdout, 'JSON retains arbitrary output octets');
    T2->is($failure->{result}{raw_status}, 256, 'JSON retains native status');
    T2->is($wire->{cause}{cause}{class},
        'LibTmux::X::Codec', 'JSON retains the primary cause chain');
    $data->{cleanup_errors}[0]{action} = 'changed';
    T2->is($entry->{action}, 'kill_session',
        'export cannot rewrite the in-memory outcome');
}
T2->done_testing;

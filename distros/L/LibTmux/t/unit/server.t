use v5.44;
use Test2::V1;
use Scalar::Util qw(blessed);
use LibTmux::Server;

sub failure ($code, $type, $label) {
    my $caught;
    try { $code->() } catch ($e) {
        $caught = $e
    }
    T2->ok(blessed($caught) && $caught->isa("LibTmux::X::$type"), $label);
}
my $server = LibTmux::Server->new(
    executable  => '/missing-libtmux-test',
    socket_name => 'never-start'
);
failure(sub { $server->cmd('display-message', {}) },
    'InvalidArgument', 'raw command references are rejected before I/O');
failure(sub { $server->new_session(name => 'x', bogus => 1) },
    'InvalidArgument', 'unknown operation options are rejected before I/O');
failure(sub { LibTmux::Server->new(timeout => 'wide') },
    'InvalidArgument', 'invalid deadlines fail at construction');
failure(sub { $server->query_panes(where => {width => {-gte => 'wide'}}) },
    'InvalidFilter', 'criteria validation precedes acquisition');
failure(sub { $server->new_window(session => '$1', command => []) },
    'InvalidArgument', 'empty command argv cannot select an implicit shell');
failure(
    sub {
        $server->split_pane(
            pane          => '%0',
            command       => ['cat'],
            shell_command => 'cat'
        );
    },
    'InvalidArgument',
    'shell and literal commands are exclusive'
);
my $keys     = ['A'];
my $prepared = $server->operation('send_keys', pane => '%0', keys => $keys);
$keys->[0] = 'B';
my $sent;
$prepared->run(
    sub ($request, $done, $fail) {
        my $stdout =
            $request->{argv}[-1] eq '-V' ? "tmux 3.8\n"
            : (grep { $_ eq 'display-message' } $request->{argv}->@*)
            ? "/owned\t123\t456\t3.8\n"
            : '';
        $sent = $request->{argv}[-1]
            if grep { $_ eq 'send-keys' } $request->{argv}->@*;
        $done->(
            bless {
                stdout     => $stdout,
                stderr     => '',
                exit_code  => 0,
                signal     => 0,
                raw_status => 0
            },
            'LibTmux::CommandResult'
        );
        return sub { };
    },
    sub { },
    sub ($error) { die $error }
);
T2->is($sent, 'A', 'prepared operation owns caller argument containers');
failure(
    sub { $server->select_layout(window => '@0', layout => 'no-such-layout') },
    'InvalidArgument',
    'unsafe invalid layout is refused before daemon dispatch'
);
T2->ok(
    !$server->explain_panes(where => {title => "nul\0text"})->lowering->{exact},
    'NUL text stays local because process arguments cannot represent it'
);
T2->done_testing;

use v5.44;
use Test2::V1;
use LibTmux::Snapshot;
use LibTmux::Server;
my $snapshot = LibTmux::Snapshot->from_records(
    complete => true,
    windows  => [{id => '@0'}],
    panes    => [{id => '%0'}]
);
my $error;
try { $snapshot->windows->where({panes => {-none => {}}}) } catch ($caught) {
    $error = $caught
}
T2->ok(
    ref($error) && $error->isa('LibTmux::X::Unloaded'),
    'unknown child membership cannot prove an empty relation'
);
$error = undef;
try { $snapshot->windows->one->active_pane } catch ($caught) {
    $error = $caught
}
T2->ok(
    ref($error) && $error->isa('LibTmux::X::Unloaded'),
    'unknown child membership cannot prove no active pane'
);

package IncompleteLiveCapture {
    use parent 'LibTmux::Server';
    sub _binary_op ($self) { LibTmux::Operation->value('3.8') }

    sub _identity_op ($self) {
        LibTmux::Operation->value(
            {
                server_id  => 'owned',
                generation => '1/2',
                version    => '3.8',
                pid        => 1
            }
        );
    }

    sub _list_op ($self, $kind, $version) {
        return LibTmux::Operation->value([{id => '$1'}]) if $kind eq 'session';
        return LibTmux::Operation->value(
            $self->{include_window}
            ? [
                {
                    id            => '@0',
                    session_id    => '$1',
                    window_index  => 0,
                    window_active => 1
                }
                ]
            : []
        ) if $kind eq 'window';
        return LibTmux::Operation->value([]);
    }
}
for my $include_window (false, true) {
    my $server = IncompleteLiveCapture->new;
    $server->{include_window} = $include_window;
    my $failure;
    try { $server->snapshot } catch ($caught) {
        $failure = $caught
    }
    T2->ok(
        ref($failure) && $failure->isa('LibTmux::X::AcquisitionRace'),
        'strict live capture rejects disappearing required adjacency'
    );
}
my $old = LibTmux::Snapshot->from_records(
    metadata => {version => '3.3a'},
    panes    => [{id => '%0'}]
);
my $capability;
try { $old->panes->one->cursor_shape } catch ($caught) {
    $capability = $caught
}
T2->ok(
    ref($capability) && $capability->isa('LibTmux::X::Unsupported'),
    'known daemon capability absence differs from an unloaded supported field'
);
T2->done_testing;

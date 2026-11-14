package LibTmux::Async::Server;
use v5.44;
use LibTmux::Async;
use LibTmux::Server;
use LibTmux::Async::Transport;
use LibTmux::Async::X;

sub new ($class, %args) {
    my %async;
    for my $key (qw(loop max_concurrent max_queue)) {
        $async{$key} = delete $args{$key} if exists $args{$key};
    }
    my $transport = LibTmux::Async::Transport->new(%async);
    return bless {
        core       => LibTmux::Server->new(%args),
        transport  => $transport,
        loop       => $async{loop},
        operations => {},
        next_id    => 0,
        closing    => false
    }, $class;
}

sub _submit ($self, $name, %args) {
    my $future = $self->{loop}->new_future;
    return $future->fail(
        LibTmux::Async::X::Closed->new(message => 'async server is closing'))
        if $self->{closing};
    my $operation;
    try {
        $operation =
            $name eq 'attach_argv'
            ? LibTmux::Operation->value($self->{core}->attach_argv(%args))
            : $self->{core}->operation($name, %args);
    }
    catch ($error) { return $future->fail($error) }
    my $id = ++$self->{next_id};
    $self->{operations}{$id} = $future;
    $future->on_ready(sub { delete $self->{operations}{$id} });
    my $cancel = $operation->run(
        sub ($request, $done, $fail) {
            my $request_future = $self->{transport}->execute(%$request);
            $request_future->on_done(sub ($result) { $done->($result) });
            $request_future->on_fail(sub ($error) { $fail->($error) });
            return
                sub { $request_future->cancel unless $request_future->is_ready };
        },
        sub ($value) { $future->done($value) unless $future->is_ready },
        sub ($error) { $future->fail($error) unless $future->is_ready }
    );
    $future->on_cancel($cancel);
    return $future;
}

sub close ($self) {
    $self->{closing} = true;
    $_->cancel for values $self->{operations}->%*;
    return $self->{transport}->close;
}
sub cmd      ($self, @argv)  { $self->_submit('cmd',      argv => \@argv) }
sub listings ($self, $kind)  { $self->_submit('listings', kind => $kind) }
sub batch ($self, $requests) { $self->_submit('batch', requests => $requests) }
sub execute         ($self, %args) { $self->_submit('execute',         %args) }
sub new_session     ($self, %args) { $self->_submit('new_session',     %args) }
sub new_window      ($self, %args) { $self->_submit('new_window',      %args) }
sub split_pane      ($self, %args) { $self->_submit('split_pane',      %args) }
sub snapshot        ($self, %args) { $self->_submit('snapshot',        %args) }
sub query_panes     ($self, %args) { $self->_submit('query_panes',     %args) }
sub explain_panes   ($self, %args) { $self->_submit('explain_panes',   %args) }
sub rename_session  ($self, %args) { $self->_submit('rename_session',  %args) }
sub rename_window   ($self, %args) { $self->_submit('rename_window',   %args) }
sub link_window     ($self, %args) { $self->_submit('link_window',     %args) }
sub unlink_window   ($self, %args) { $self->_submit('unlink_window',   %args) }
sub move_window     ($self, %args) { $self->_submit('move_window',     %args) }
sub select_window   ($self, %args) { $self->_submit('select_window',   %args) }
sub select_pane     ($self, %args) { $self->_submit('select_pane',     %args) }
sub select_layout   ($self, %args) { $self->_submit('select_layout',   %args) }
sub resize_pane     ($self, %args) { $self->_submit('resize_pane',     %args) }
sub set_title       ($self, %args) { $self->_submit('set_title',       %args) }
sub send_keys       ($self, %args) { $self->_submit('send_keys',       %args) }
sub send_text       ($self, %args) { $self->_submit('send_text',       %args) }
sub capture_pane    ($self, %args) { $self->_submit('capture_pane',    %args) }
sub kill_pane       ($self, %args) { $self->_submit('kill_pane',       %args) }
sub kill_window     ($self, %args) { $self->_submit('kill_window',     %args) }
sub kill_session    ($self, %args) { $self->_submit('kill_session',    %args) }
sub kill_server     ($self, %args) { $self->_submit('kill_server',     %args) }
sub clients         ($self, %args) { $self->_submit('clients',         %args) }
sub attach_argv     ($self, %args) { $self->_submit('attach_argv',     %args) }
sub detach_client   ($self, %args) { $self->_submit('detach_client',   %args) }
sub set_option      ($self, %args) { $self->_submit('set_option',      %args) }
sub get_option      ($self, %args) { $self->_submit('get_option',      %args) }
sub unset_option    ($self, %args) { $self->_submit('unset_option',    %args) }
sub set_hook        ($self, %args) { $self->_submit('set_hook',        %args) }
sub show_hooks      ($self, %args) { $self->_submit('show_hooks',      %args) }
sub set_environment ($self, %args) { $self->_submit('set_environment', %args) }
sub get_environment ($self, %args) { $self->_submit('get_environment', %args) }

sub unset_environment ($self, %args) {
    $self->_submit('unset_environment', %args);
}
sub set_buffer    ($self, %args) { $self->_submit('set_buffer',    %args) }
sub show_buffer   ($self, %args) { $self->_submit('show_buffer',   %args) }
sub delete_buffer ($self, %args) { $self->_submit('delete_buffer', %args) }

=head1 NAME

LibTmux::Async::Server - Optional Future facade over the core protocol

=head1 SYNOPSIS

    use v5.44;
    use IO::Async::Loop::Ppoll;
    use LibTmux::Async::Server;
    my $loop = IO::Async::Loop::Ppoll->new;
    my $server = LibTmux::Async::Server->new(loop => $loop, socket_name => 'owned');
    my $capture = $server->snapshot;
    $loop->await($capture);
    my $panes = $capture->get->panes->where({ active => true });
    $loop->await($server->close);

=head1 METHODS

=head2 new

C<new(loop =E<gt> $loop, %connection_options)> constructs without I/O.
Borrow an L<IO::Async::Loop::Ppoll>; connection options belong to
L<LibTmux::Server/new>. C<max_concurrent> and C<max_queue> configure the
owned L<LibTmux::Async::Transport>. Its L<backend and signal contract|LibTmux::Async::Transport/new>
applies to this facade. No event loop is run implicitly.

=head2 close

Cancel active operations, suppress subsequent command continuations, reject
new operations, and return a fresh cleanup observer L<Future>. Only successful
C<is_done> completion proves owned processes and pipes finished. Cancellation
of an observer does not cancel cleanup. The caller must drive its borrowed
loop through shutdown. No tmux server is destroyed by closing this facade.

=head1 CORE OPERATIONS

Each operation below returns a L<Future> yielding exactly one value with the
corresponding core method's result and error contract. Void core methods yield
one C<undef>. Failures contain the original typed core exception. Preparation
and result parsing use L<LibTmux::Operation>; no blocking core operation runs
inside the event loop. Captured L<LibTmux::Selection> filtering stays local.
Cancelling a Future requests process cleanup and prevents later requests; it
cannot reverse already accepted mutations. Independent operations may overlap;
C<batch> requests remain ordered. C<Future::AsyncAwait> is optional caller syntax.

=head2 execute

See L<LibTmux::Server/execute> for arguments, returned value, and completion.

=head2 cmd

See L<LibTmux::Server/cmd> for arguments, returned value, and completion.

=head2 new_session

See L<LibTmux::Server/new_session> for arguments, returned value, and completion.

=head2 new_window

See L<LibTmux::Server/new_window> for arguments, returned value, and completion.

=head2 split_pane

See L<LibTmux::Server/split_pane> for arguments, returned value, and completion.

=head2 snapshot

See L<LibTmux::Server/snapshot> for arguments, returned value, and completion.

=head2 listings

See L<LibTmux::Server/listings> for arguments, returned value, and completion.

=head2 query_panes

See L<LibTmux::Server/query_panes> for arguments, returned value, and completion.
Its observer runs inline in void context; a returned L<Future> is ignored.
Cancellation before the decision suppresses it. If the observer cancels its
query or calls L</close>, cancellation takes precedence over subsequent return
or exception delivery. Continue driving the loop until close cleanup completes.

=head2 explain_panes

See L<LibTmux::Server/explain_panes> for arguments, returned value, and completion.

=head2 rename_session

See L<LibTmux::Server/rename_session> for arguments, returned value, and completion.

=head2 rename_window

See L<LibTmux::Server/rename_window> for arguments, returned value, and completion.

=head2 link_window

See L<LibTmux::Server/link_window> for arguments, returned value, and completion.

=head2 unlink_window

See L<LibTmux::Server/unlink_window> for arguments, returned value, and completion.

=head2 move_window

See L<LibTmux::Server/move_window> for arguments, returned value, and completion.

=head2 select_window

See L<LibTmux::Server/select_window> for arguments, returned value, and completion.

=head2 select_pane

See L<LibTmux::Server/select_pane> for arguments, returned value, and completion.

=head2 select_layout

See L<LibTmux::Server/select_layout> for arguments, returned value, and completion.

=head2 resize_pane

See L<LibTmux::Server/resize_pane> for arguments, returned value, and completion.

=head2 set_title

See L<LibTmux::Server/set_title> for arguments, returned value, and completion.

=head2 send_keys

See L<LibTmux::Server/send_keys> for arguments, returned value, and completion.

=head2 send_text

See L<LibTmux::Server/send_text> for arguments, returned value, and completion.

=head2 capture_pane

See L<LibTmux::Server/capture_pane> for arguments, returned value, and completion.

=head2 kill_pane

See L<LibTmux::Server/kill_pane> for arguments, returned value, and completion.

=head2 kill_window

See L<LibTmux::Server/kill_window> for arguments, returned value, and completion.

=head2 kill_session

See L<LibTmux::Server/kill_session> for arguments, returned value, and completion.

=head2 kill_server

See L<LibTmux::Server/kill_server> for arguments, returned value, and completion.

=head2 clients

See L<LibTmux::Server/clients> for arguments, returned value, and completion.

=head2 attach_argv

See L<LibTmux::Server/attach_argv> for arguments, returned value, and completion.

=head2 detach_client

See L<LibTmux::Server/detach_client> for arguments, returned value, and completion.

=head2 set_option

See L<LibTmux::Server/set_option> for arguments, returned value, and completion.

=head2 get_option

See L<LibTmux::Server/get_option> for arguments, returned value, and completion.

=head2 unset_option

See L<LibTmux::Server/unset_option> for arguments, returned value, and completion.

=head2 set_hook

See L<LibTmux::Server/set_hook> for arguments, returned value, and completion.

=head2 show_hooks

See L<LibTmux::Server/show_hooks> for arguments, returned value, and completion.

=head2 set_environment

See L<LibTmux::Server/set_environment> for arguments, returned value, and completion.

=head2 get_environment

See L<LibTmux::Server/get_environment> for arguments, returned value, and completion.

=head2 unset_environment

See L<LibTmux::Server/unset_environment> for arguments, returned value, and completion.

=head2 set_buffer

See L<LibTmux::Server/set_buffer> for arguments, returned value, and completion.

=head2 show_buffer

See L<LibTmux::Server/show_buffer> for arguments, returned value, and completion.

=head2 delete_buffer

See L<LibTmux::Server/delete_buffer> for arguments, returned value, and completion.

=head2 batch

See L<LibTmux::Server/batch> for arguments, returned value, and completion.

=cut

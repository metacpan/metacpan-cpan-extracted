package LibTmux::Entity;
use v5.44;
use LibTmux::Schema;

sub _new ($class, $store, $kind, $id) {
    bless {store => $store, kind => $kind, id => $id}, $class;
}
sub kind       ($self) { $self->{kind} }
sub _store     ($self) { $self->{store} }
sub server_id  ($self) { $self->{store}->server_id }
sub generation ($self) { $self->{store}->generation }

sub identity ($self) {
    join "\0", $self->server_id, $self->generation, $self->kind, $self->{id};
}

sub _read ($self, $field) {
    $self->{store}->_read($self->kind, $self->{id}, $field);
}

sub to_record ($self) {
    +{$self->{store}->{records}{$self->kind}{$self->{id}}->%*};
}

=head1 NAME

LibTmux::Entity - Read-only handle retaining a captured graph

=head1 DESCRIPTION

Field readers and relationships resolve locally in the retained graph.
L</to_record> returns detached scalar record data. Handles retain no transport.

=head1 METHODS

=head2 kind

Return the schema entity-kind string. Concrete public field readers belong to L<LibTmux::Pane>, L<LibTmux::Window>, L<LibTmux::WindowLink>, L<LibTmux::Session>, and L<LibTmux::Client>.

=head2 server_id

Return the captured server scope. No daemon discovery or refresh occurs.

=head2 generation

Return the captured generation. Restarted daemons cannot silently reuse this handle.

=head2 identity

Return an opaque identity key scoped by server, generation, kind, and string ID. It is suitable for local equality; duplicate selection occurrences remain separate occurrences.

=head2 to_record

Return a fresh hash reference of captured scalar fields and adjacency IDs. Editing it does not change the retained graph. Retaining the entity retains its captured graph, with no transport ownership or reference cycle.

=head1 EXECUTION

All methods in this module operate on local captured data and perform no tmux
I/O. Ordering is deterministic; public query methods do not mutate membership.
Typed validation/evaluation errors propagate. See L<LibTmux::Server/snapshot>
for explicit acquisition and L<LibTmux::X> for machine-readable failures.

=cut

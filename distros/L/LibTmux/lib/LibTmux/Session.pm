package LibTmux::Session;
use v5.44;
use parent 'LibTmux::Entity';

sub attached     ($self) { $self->_read('attached') }
sub created      ($self) { $self->_read('created') }
sub id           ($self) { $self->_read('id') }
sub name         ($self) { $self->_read('name') }
sub path         ($self) { $self->_read('path') }
sub window_links ($self) { $self->_read('window_links') }

=head1 NAME

LibTmux::Session - Captured session entity

=head1 METHODS

=head2 attached

integer. Local captured data; no I/O.

=head2 created

integer. Local captured data; no I/O.

=head2 id

string. Local captured data; no I/O.

=head2 name

string. Local captured data; no I/O.

=head2 path

bytes. Local captured data; no I/O.

=head2 window_links

L<LibTmux::Selection> of L<LibTmux::WindowLink> entities. Local captured data; no I/O.

=head1 OWNERSHIP

Readers use the retained graph and never refresh it. Acquire a new snapshot for
new state. Inherited L<to_record|LibTmux::Entity/to_record> exports a detached scalar record.

=cut

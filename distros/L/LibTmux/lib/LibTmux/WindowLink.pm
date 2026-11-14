package LibTmux::WindowLink;
use v5.44;
use parent 'LibTmux::Entity';

sub active  ($self) { $self->_read('active') }
sub id      ($self) { $self->_read('id') }
sub index   ($self) { $self->_read('index') }
sub session ($self) { $self->_read('session') }
sub window  ($self) { $self->_read('window') }

=head1 NAME

LibTmux::WindowLink - Captured window_link entity

=head1 METHODS

=head2 active

boolean. Local captured data; no I/O.

=head2 id

string. Local captured data; no I/O.

=head2 index

integer. Local captured data; no I/O.

=head2 session

L<LibTmux::Session> entity. Local captured data; no I/O.

=head2 window

L<LibTmux::Window> entity. Local captured data; no I/O.

=head1 OWNERSHIP

Readers use the retained graph and never refresh it. Acquire a new snapshot for
new state. Inherited L<to_record|LibTmux::Entity/to_record> exports a detached scalar record.

=cut

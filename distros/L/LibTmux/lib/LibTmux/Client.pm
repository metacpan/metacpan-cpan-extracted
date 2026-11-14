package LibTmux::Client;
use v5.44;
use parent 'LibTmux::Entity';

sub height  ($self) { $self->_read('height') }
sub id      ($self) { $self->_read('id') }
sub name    ($self) { $self->_read('name') }
sub pid     ($self) { $self->_read('pid') }
sub session ($self) { $self->_read('session') }
sub tty     ($self) { $self->_read('tty') }
sub width   ($self) { $self->_read('width') }

=head1 NAME

LibTmux::Client - Captured client entity

=head1 METHODS

=head2 height

integer. Local captured data; no I/O.

=head2 id

string. Local captured data; no I/O.

=head2 name

string. Local captured data; no I/O.

=head2 pid

integer. Local captured data; no I/O.

=head2 session

L<LibTmux::Session> entity or undef. Local captured data; no I/O.

=head2 tty

bytes. Local captured data; no I/O.

=head2 width

integer. Local captured data; no I/O.

=head1 OWNERSHIP

Readers use the retained graph and never refresh it. Acquire a new snapshot for
new state. Inherited L<to_record|LibTmux::Entity/to_record> exports a detached scalar record.

=cut

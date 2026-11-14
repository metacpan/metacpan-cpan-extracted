package LibTmux::Pane;
use v5.44;
use parent 'LibTmux::Entity';

sub active          ($self) { $self->_read('active') }
sub current_command ($self) { $self->_read('current_command') }
sub current_path    ($self) { $self->_read('current_path') }
sub cursor_shape    ($self) { $self->_read('cursor_shape') }
sub dead            ($self) { $self->_read('dead') }
sub exit_status     ($self) { $self->_read('exit_status') }
sub height          ($self) { $self->_read('height') }
sub id              ($self) { $self->_read('id') }
sub index           ($self) { $self->_read('index') }
sub pid             ($self) { $self->_read('pid') }
sub title           ($self) { $self->_read('title') }
sub width           ($self) { $self->_read('width') }
sub window          ($self) { $self->_read('window') }

=head1 NAME

LibTmux::Pane - Captured pane entity

=head1 METHODS

=head2 active

boolean. Local captured data; no I/O.

=head2 current_command

string. Local captured data; no I/O.

=head2 current_path

bytes. Local captured data; no I/O.

=head2 cursor_shape

string. Local captured data; no I/O.

=head2 dead

boolean. Local captured data; no I/O.

=head2 exit_status

integer or undef. Local captured data; no I/O.

=head2 height

integer. Local captured data; no I/O.

=head2 id

string. Local captured data; no I/O.

=head2 index

integer. Local captured data; no I/O.

=head2 pid

integer. Local captured data; no I/O.

=head2 title

string. Local captured data; no I/O.

=head2 width

integer. Local captured data; no I/O.

=head2 window

L<LibTmux::Window> entity. Local captured data; no I/O.

=head1 OWNERSHIP

Readers use the retained graph and never refresh it. Acquire a new snapshot for
new state. Inherited L<to_record|LibTmux::Entity/to_record> exports a detached scalar record.

=cut

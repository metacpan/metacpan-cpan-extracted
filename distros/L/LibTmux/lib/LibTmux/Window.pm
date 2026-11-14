package LibTmux::Window;
use v5.44;
use parent 'LibTmux::Entity';

sub active_pane ($self) { $self->_read('active_pane') }
sub height      ($self) { $self->_read('height') }
sub id          ($self) { $self->_read('id') }
sub layout      ($self) { $self->_read('layout') }
sub links       ($self) { $self->_read('links') }
sub name        ($self) { $self->_read('name') }
sub panes       ($self) { $self->_read('panes') }
sub width       ($self) { $self->_read('width') }

=head1 NAME

LibTmux::Window - Captured window entity

=head1 METHODS

=head2 active_pane

L<LibTmux::Pane> entity or undef. Local captured data; no I/O.

=head2 height

integer. Local captured data; no I/O.

=head2 id

string. Local captured data; no I/O.

=head2 layout

string. Local captured data; no I/O.

=head2 links

L<LibTmux::Selection> of L<LibTmux::WindowLink> entities. Local captured data; no I/O.

=head2 name

string. Local captured data; no I/O.

=head2 panes

L<LibTmux::Selection> of L<LibTmux::Pane> entities. Local captured data; no I/O.

=head2 width

integer. Local captured data; no I/O.

=head1 OWNERSHIP

Readers use the retained graph and never refresh it. Acquire a new snapshot for
new state. Inherited L<to_record|LibTmux::Entity/to_record> exports a detached scalar record.

=cut

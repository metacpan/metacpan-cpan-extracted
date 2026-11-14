package LibTmux::WindowSelection;
use v5.44;
use parent 'LibTmux::Selection';
sub _kind ($self) { 'window' }

=head1 NAME

LibTmux::WindowSelection - Native array selection of captured window entities

=head1 DESCRIPTION

Inherits the fixed-return local query API of L<LibTmux::Selection>. Members
must be defined L<LibTmux::Window> handles from one server generation. Empty
instances still validate against the window schema. Native array edits are
possible; query methods validate membership and never perform tmux I/O.

=cut

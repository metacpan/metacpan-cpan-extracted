package LibTmux::PaneSelection;
use v5.44;
use parent 'LibTmux::Selection';
sub _kind ($self) { 'pane' }

=head1 NAME

LibTmux::PaneSelection - Native array selection of captured pane entities

=head1 DESCRIPTION

Inherits the fixed-return local query API of L<LibTmux::Selection>. Members
must be defined L<LibTmux::Pane> handles from one server generation. Empty
instances still validate against the pane schema. Native array edits are
possible; query methods validate membership and never perform tmux I/O.

=cut

package LibTmux::WindowLinkSelection;
use v5.44;
use parent 'LibTmux::Selection';
sub _kind ($self) { 'window_link' }

=head1 NAME

LibTmux::WindowLinkSelection - Native array selection of captured window_link entities

=head1 DESCRIPTION

Inherits the fixed-return local query API of L<LibTmux::Selection>. Members
must be defined L<LibTmux::WindowLink> handles from one server generation. Empty
instances still validate against the window_link schema. Native array edits are
possible; query methods validate membership and never perform tmux I/O.

=cut

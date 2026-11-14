package LibTmux::SessionSelection;
use v5.44;
use parent 'LibTmux::Selection';
sub _kind ($self) { 'session' }

=head1 NAME

LibTmux::SessionSelection - Native array selection of captured session entities

=head1 DESCRIPTION

Inherits the fixed-return local query API of L<LibTmux::Selection>. Members
must be defined L<LibTmux::Session> handles from one server generation. Empty
instances still validate against the session schema. Native array edits are
possible; query methods validate membership and never perform tmux I/O.

=cut

package LibTmux::ClientSelection;
use v5.44;
use parent 'LibTmux::Selection';
sub _kind ($self) { 'client' }

=head1 NAME

LibTmux::ClientSelection - Native array selection of captured client entities

=head1 DESCRIPTION

Inherits the fixed-return local query API of L<LibTmux::Selection>. Members
must be defined L<LibTmux::Client> handles from one server generation. Empty
instances still validate against the client schema. Native array edits are
possible; query methods validate membership and never perform tmux I/O.

=cut

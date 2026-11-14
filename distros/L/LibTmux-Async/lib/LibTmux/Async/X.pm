package LibTmux::Async::X;
use v5.44;
use LibTmux::X;

package LibTmux::Async::X::QueueFull;
our @ISA = ('LibTmux::X');

package LibTmux::Async::X::Closed;
our @ISA = ('LibTmux::X');

=head1 NAME

LibTmux::Async::X - Async admission failures

=head2 QueueFull

The configured running and pending limits are occupied. No command was
submitted for this request. Returned through a failed L<Future>.

=head2 Closed

Shutdown has started and new work is refused. Callers may still observe
cleanup through L<LibTmux::Async::Transport/close>.

=cut

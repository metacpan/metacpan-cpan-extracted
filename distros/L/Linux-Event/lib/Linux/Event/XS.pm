package Linux::Event::XS;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.012';

use XSLoader;
XSLoader::load('Linux::Event', $VERSION);

1;

__END__

=head1 NAME

Linux::Event::XS - XS hot-path helpers for Linux::Event

=head1 DESCRIPTION

This module contains private XS helpers used by L<Linux::Event>.  The API is
not public and may change between releases.

=head1 PRIVATE FUNCTIONS

=head2 registry_new

Create an fd-indexed registry object.

=head2 registry_get($registry, $fd)

Return the value stored for C<$fd>, or undef.

=head2 registry_set($registry, $fd, $value)

Store C<$value> for C<$fd>, replacing any previous value.

=head2 registry_delete($registry, $fd)

Remove and return the value stored for C<$fd>, or undef.

=head2 registry_count($registry)

Return the number of live entries.

=head2 backend_watch_new

Create a private backend-side watcher record.

=head2 backend_watch_fh

Return the filehandle stored in a backend watcher record.

=head2 backend_watch_mask / backend_watch_set_mask

Read or update the readiness mask stored in a backend watcher record.

=head2 backend_watch_set_loop_tag

Update the loop and tag stored in a backend watcher record.

=head2 backend_watch_dispatch

Translate an epoll event hash into the internal readiness mask and invoke the stored dispatch callback.

=head2 epoll_new / epoll_add / epoll_modify / epoll_delete / epoll_wait_dispatch

Private XS epoll backend helpers.  The XS epoll object owns the epoll fd and a
reused C<struct epoll_event> buffer for dispatch-heavy paths.

=head2 timer_heap_new / timer_heap_at_ns / timer_heap_cancel / timer_heap_next_deadline_ns / timer_heap_pop_expired

Private XS timer heap helpers used by C<Linux::Event::Scheduler>.

=cut

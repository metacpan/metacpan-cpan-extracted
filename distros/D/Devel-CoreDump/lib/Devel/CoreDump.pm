use strict;
use warnings;

package Devel::CoreDump;

use XSLoader;
use IO::Handle;

our $VERSION = '0.02';

XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=head1 NAME

Devel::CoreDump - create core dumps of the running perl interpreter, without terminating

=head1 SYNOPSIS

    use Devel::CoreDump;

    Devel::CoreDump->write('perl.core');

=head1 DESCRIPTION

This module allows to create GDB readable coredumps from the running perl
interpreter, without terminating execution.

=head1 METHODS

=head2 get

    my $fh = Devel::CoreDump->get;

Returns a file handle that can be read to obtain a snapshot of the current
state of this process. If a core file could not be generated for any reason, an
exception is thrown.

This function momentarily suspends all threads, while creating a COW
(copy-on-write) copy of the process's address space.

This function is neither reentrant nor async signal safe. Callers should wrap a
mutex around the invocation of this function, if necessary.

The current implementation tries very hard to behave reasonably when called
from a signal handler, but no guarantees are made that this will always work.
Most importantly, it is the caller's responsibility to make sure that there are
never more than one instance of C<get()> or C<write()> executing concurrently.

=head2 write($file)

    Devel::CoreDump->write('perl.core');

Writes the core file to disk. This is a convenience method wrapping
C<get()>. If a core file could not be generated for any reason,
an exception is thrown.

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008  Florian Ragwitz

This software is distributed under the terms of the BSD License


Parts of this module are taken from Google's coredumper library.
L<http://code.google.com/p/google-coredumper/>.

Copyright (c) 2005-2008, Google Inc.  All rights reserved.

Coredumper is distributed under the terms of the BSD License.

=cut

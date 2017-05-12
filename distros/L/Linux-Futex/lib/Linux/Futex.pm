package Linux::Futex;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.6';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Linux::Futex - Perl extension for using Futexes

=head1 SYNOPSIS

    use Linux::Futex ();
    my $mutex_buf = "    ";
    my $mutex = Linux::Futex::addr($mutex_buf);
    Linux::Futex::init($mutex); # Execute once to set to zero
    Linux::Futex::lock($mutex);
    # do something critical
    Linux::Futex::unlock($mutex);

Note that this examples mutex is local so wouldn't be much use for inter-process.
Use shared memory (eg. L<IPC::SharedMem>) to make this work.

=head1 DESCRIPTION

This perl module implements the high performance lightweight process
synchronization method using 'futexes' implemented in recent Linux Kernels.

=head2 EXPORT

None by default.

=over

=item addr()

Return the address of a string for use in mutex calls. Uses
the same format as IPC::SharedMem. Requires a string of at least 4 bytes.

=item init()

Initialize the futex with 0

=item lock()

Lock the futex. If currently locked then block until released.

=item unlock()

Unlock the futex. If not currently locked then no-op.

=back

=head1 SEE ALSO

The original paper on which this code is based:

=over

=item *
I<Futexes Are Tricky> by Ulrich Drepper (E<lt>drepper@redhat.comE<gt>),
(Published on Nov 5, 2011)

=back

Some further discussion and improvements in:

=over

=item *
  See L<http://locklessinc.com/articles/mutex_cv_futex/>

=back

=head1 AUTHOR

Nick Townsend, E<lt>nick.townsend@mac.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Nick Townsend

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

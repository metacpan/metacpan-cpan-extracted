package IO::All::SFTP;

use warnings;
use strict;

require LWP::Debug;
use IO::All::LWP '-base';

our $VERSION = '0.01';

const type => 'sftp';

sub sftp { my $self=shift; $self->lwp_init(__PACKAGE__, @_) }

=head1 NAME

IO::All::SFTP - use sftp from IO::All

=head1 SYNOPSIS

Here's a quick example of how to use this:

    use IO::All;
    # print the contents of the remove file
    $test < io('sftp://guest:guest@asdf/home/guest/test');
    print $test;

For more information on the interface, see the L<IO::All> POD.

=head1 ACKNOWLEDGEMENTS

I did not write any of the code that this module uses. All of the code
is in LWP::Protocol::sftp and IO::All::LWP. This module just tells
IO::All::LWP to use LWP::Protocol::sftp.

So kudos to Salvador Fandiño for LWP-Protocol-sftp and Ivan
Tubert-Brohman and Brian Ingerson for IO-All-LWP.

=head1 BUGS

One bug that I've found while testing is that if you don't have the
host you are connecting to in your known_hosts, it will just hang.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ryan Niebur, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<IO::All>, L<IO::All::LWP>

=cut

1;

# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Error;

use strict;
use warnings;

use Errno;

use Carp ();

=head1 NAME

Filesys::POSIX::Error - Throw Errno values with L<Carp::confess()|Carp/confess>

=head1 SYNOPSIS

    use Filesys::POSIX::Error;

    throw &Errno::ENOENT;

=head1 DESCRIPTION

C<Filesys::POSIX::Error> provides C<throw()>, a function which allows one to
set L<C<$!>|perlvar/$!> and throw a stack trace containing a stringification
thereof in one simple action.

=cut

BEGIN {
    require Exporter;

    our @EXPORT_OK = qw(throw);
}

our @ISA = ('Exporter');

sub throw ($) {
    my ($errno) = @_;

    $! = $errno;

    Carp::confess "$!";
}

1;

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 CONTRIBUTORS

=over

=item Rikus Goodell <rikus.goodell@cpanel.net>

=item Brian Carlson <brian.carlson@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.

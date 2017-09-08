package MariaDB::NonBlocking;

use 5.006;
use strict;
use warnings;

=head1 NAME

MariaDB::NonBlocking - Nonblocking connections to MySQL using libmariadbclient

=head1 VERSION

Version 0.06

=cut

use Exporter qw(import);
use XSLoader qw();

BEGIN {
    our $VERSION = '0.06';
};
XSLoader::load(__PACKAGE__);

our @EXPORT_OK = qw/
    MYSQL_WAIT_READ
    MYSQL_WAIT_WRITE
    MYSQL_WAIT_EXCEPT
    MYSQL_WAIT_TIMEOUT
/;
our %EXPORT_TAGS = (
    'all' => [ @EXPORT_OK ]
);

=head1 SYNOPSIS

A very thin wrapper around the MariaDB non-blocking library to MySQL.
You probably want to check out L<MariaDB::NonBlocking::Promises> for
something that you can actually use for querying!

This class provides access to the basic functionality, so
without adding some sort of eventloop around it it won't be
very useful.

    use MariaDB::NonBlocking;
    my $maria = MariaDB::NonBlocking->init;

    my $wait_for = $maria->connect_start({
                    host        => ...,
                    port        => ...,
                    user        => ...,
                    password    => ...,
                    database    => ...,
                    unix_socket => ...,

                    charset     => ...,

                    mysql_use_results  => undef, # not very useful yet

                    mysql_connect_timeout => ...,
                    mysql_write_timeout   => ...,
                    mysql_read_timeout    => ...,

                    mysql_init_command => ...,
                    mysql_compression  => ...,

                    # NOT TESTED, LIKELY TO SEGFAULT, DO NOT USE YET:
                    ssl => {
                        key    => ...,
                        cert   => ...,
                        ca     => ...,
                        capath => ...,
                        cipher => ...,
                        reject_unauthorized => 1,
                    },
               });

    # Your event loop here
    while ( $wait_for ) {
        
    }

=head1 EXPORT

Four constants are optionally exported.  They can be logically-and'd with
the status (C<$wait_for>) returned by the C<_start> and C<_cont> methods,
to figure out what events the library wants us to wait on.

They should also be used to communicate with the library what events happened.

=head2 MYSQL_WAIT_READ

=head2 MYSQL_WAIT_WRITE

=head2 MYSQL_WAIT_EXCEPT

=head2 MYSQL_WAIT_TIMEOUT

=head1 SUBROUTINES/METHODS

=head2 function2

=head1 AUTHOR

Brian Fraser, C<< <fraserbn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mariadb-nonblocking at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MariaDB-NonBlocking>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MariaDB::NonBlocking


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MariaDB-NonBlocking>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MariaDB-NonBlocking>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MariaDB-NonBlocking>

=item * Search CPAN

L<http://search.cpan.org/dist/MariaDB-NonBlocking/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Brian Fraser.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MariaDB::NonBlocking

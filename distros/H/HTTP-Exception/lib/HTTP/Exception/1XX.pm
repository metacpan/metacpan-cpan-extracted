package HTTP::Exception::1XX;
$HTTP::Exception::1XX::VERSION = '0.04006';
use strict;
use base 'HTTP::Exception::Base';

sub is_info         () { 1  }
sub is_success      () { '' }
sub is_redirect     () { '' }
sub is_error        () { '' }
sub is_client_error () { '' }
sub is_server_error () { '' }

1;


=head1 NAME

HTTP::Exception::1XX - Base Class for 1XX (info) Exceptions

=head1 VERSION

version 0.04006

=head1 SYNOPSIS

nothing here yet

=head1 DESCRIPTION

This package is the base class for all 1XX (info) Exceptions.
This makes adding features for a range of exceptions easier.

DON'T USE THIS PACKAGE DIRECTLY. 'use HTTP::Exception' does this for you.

=head1 ADDITIONAL FIELDS

Fields, that 1XX-Exceptions provide over HTTP::Exceptions.

=head1 AUTHOR

Thomas Mueller, C<< <tmueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-http-exception at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Exception>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Exception::Base

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Exception>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Exception>

=item * Search CPAN

L<https://metacpan.org/release/HTTP-Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Thomas Mueller.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

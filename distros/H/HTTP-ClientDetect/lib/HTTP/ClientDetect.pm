package HTTP::ClientDetect;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

HTTP::ClientDetect - Detect language and location of an HTTP request

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

  use HTTP::ClientDetect::Location;
  my $geo = HTTP::ClientDetect::Location->new(db => $dbfile);
  my $country = $geo->request_country($request_object)

  use HTTP::ClientDetect::Language;
  my $lang_detect = HTTP::ClientDetect::Language->new(server_default => "hr_HR");
  my $lang = $lang_detect->language_short($request_object);

=head1 DESCRIPTION

This module by itself doesn't do nothing. You have to load one or more
of its children, as per synopsis.

The object passed to the methods has to be an object which at least
has an C<header> method for the language detection, or C<address> or
C<remote_address> for the country detection. This should work with
L<Dancer::Request> and L<Catalyst::Request> objects.


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-interchange6-plugin-autodetect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-ClientDetect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::ClientDetect


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-ClientDetect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-ClientDetect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-ClientDetect>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-ClientDetect/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of HTTP::ClientDetect

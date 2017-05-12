#!/usr/bin/env perl

use strict;
use warnings;

use CGI;
use Carp;
use JSON;
use Try::Tiny;

use HON::Http::UrlChecker::Service qw/checkUrl/;

=head1 NAME

url-checker-service.cgi

=head1 DESCRIPTION

Check status code, response headers, redirect location and redirect chain
of a HTTP connection.

=head1 VERSION

Version 0.02

=head1 USAGE

  cgi/url-checker-service.cgi url=http://www.example.com

=head1 REQUIRED ARGUMENTS

=over 2

=item --url=http://www.example.com

a url

=back

=cut

our $VERSION = '0.02';

my $cgi = CGI->new();
my $url = $cgi->param('url') || undef;

if ( defined $url ) {
  try {
    my @listOfStatus = checkUrl($url);
    my $json = to_json( \@listOfStatus, { pretty => 1 } );
    printOutput( $json, '200 OK' );
  }
  catch {
    badRequest();
  }
}
else {
  badRequest();
}

=head1 PRIVATE SUBROUTINES/METHODS

=head2 printOutput

Print the http header et the json response.

=cut

sub printOutput {
  my ( $json, $status ) = @_;

  my $content = $cgi->header(
    -type    => 'application/json',
    -charset => 'utf-8',
    -status  => $status,
  );
  $content .= $json;
  print "$content\n" or croak "Cannot print...\n";

  return;
}

=head2 badRequest

Print a 400 Bad Request

=cut

sub badRequest {
  printOutput( '{"error": "Bad Request"}', '400 Bad Request' );

  return;
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-hon-http-urlchecker-service at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HON-Http-UrlChecker-Service>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HON::Http::UrlChecker::Service

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HON-Http-UrlChecker-Service>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HON-Http-UrlChecker-Service>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HON-Http-UrlChecker-Service>

=item * Search CPAN

L<http://search.cpan.org/dist/HON-Http-UrlChecker-Service/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 William Belle.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

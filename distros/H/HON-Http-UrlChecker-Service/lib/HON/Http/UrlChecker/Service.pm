package HON::Http::UrlChecker::Service;

use 5.006;
use strict;
use warnings;

use URI;
use Carp;
use Readonly;
use LWP::UserAgent;

=head1 NAME

HON::Http::UrlChecker::Service - HTTP Status Code Checker

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use HON::Http::UrlChecker::Service;

    my @listOfStatus = checkUrl('http://www.example.com');

=head1 DESCRIPTION

Check status code, response headers, redirect location and redirect chain
of a HTTP connection.

=cut

use base 'Exporter';
our @EXPORT_OK =
  qw/p_createUserAgent p_getUrl p_parseResponse p_isUrlAllowed checkUrl/;

Readonly::Scalar my $TIMEOUT => 1200;

Readonly::Scalar my $MAXREDIRECT => 10;

Readonly::Array my @HEADERFIELDS => qw(
  location
  server
  content-type
  title
  date
);

Readonly::Array my @RESPONSEFIELDS => qw(
  protocol
  code
  message
);

=head1 SUBROUTINES/METHODS

=head2 checkUrl( $url )

Check a url (status code, response headers, redirect location and
redirect chain).

=cut

sub checkUrl {
  my $url = shift;

  if ( p_isUrlAllowed($url) ) {
    my $ua         = p_createUserAgent();
    my $response   = p_getUrl( $ua, $url );
    my @listStatus = p_parseResponse($response);

    return @listStatus;
  }
  else {
    croak "Wrong url: $url";
  }
}

=head1 PRIVATE SUBROUTINES/METHODS

=head2 p_createUserAgent

Return a LWP::UserAgent.
LWP::UserAgent objects can be used to dispatch web requests.

=cut

sub p_createUserAgent {
  my $ua = LWP::UserAgent->new;

  $ua->timeout($TIMEOUT);
  $ua->agent('HonBot');
  $ua->env_proxy;
  $ua->max_redirect($MAXREDIRECT);

  return $ua;
}

=head2 p_getUrl

Dispatch a GET request on the given $url
The return value is a response object. See HTTP::Response for a description
of the interface it provides.

=cut

sub p_getUrl {
  my ( $ua, $url ) = @_;

  return $ua->get($url);
}

=head2 p_retrieveInfo

Retrieve desired fields from an HTTP::Response

=cut

sub p_retrieveInfo {
  my $response = shift;

  my %locationStatus = ();
  foreach my $field (@HEADERFIELDS) {
    if ( defined $response->header($field) ) {
      $locationStatus{$field} = $response->header($field);
    }
  }

  foreach my $field (@RESPONSEFIELDS) {
    if ( defined $response->$field ) {
      $locationStatus{$field} = $response->$field;

      # Put status code in integer
      if ( $field eq 'code' ) {
        $locationStatus{$field} = $locationStatus{$field} + 0;
      }

      if ( $field eq 'message' ) {
        $locationStatus{$field} = join q{ }, map { ucfirst lc } split q{ },
          $locationStatus{$field};
      }
    }
  }

  return %locationStatus;
}

=head2 p_parseResponse

Retrieve a list of Status from HTTP::Response

=cut

sub p_parseResponse {
  my $response = shift;

  my @listStatus = ();
  my @redirects  = $response->redirects;
  if ( scalar @redirects > 0 ) {
    foreach my $redirect (@redirects) {
      my %status = p_retrieveInfo($redirect);
      push @listStatus, \%status;
    }
  }
  my %status = p_retrieveInfo($response);
  push @listStatus, \%status;

  return @listStatus;
}

=head2 p_isUrlAllowed

Check if the url is formatted correctly

=cut

sub p_isUrlAllowed {
  my $url = shift;

  return unless $url;
  my $uri = URI->new($url);
  return unless $uri->scheme and $uri->opaque;

  if ( $uri->scheme eq 'http' or $uri->scheme eq 'https' ) {
    return unless $uri->authority;
  }

  return 1;
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

1;    # End of HON::Http::UrlChecker::Service

package HTTP::Size;
use strict;
use warnings;
no warnings;

=encoding utf8

=head1 NAME

HTTP::Size - Get the byte size of an internet resource

=head1 SYNOPSIS

	use HTTP::Size

	my $size = HTTP::Size::get_size( $url );

	if( defined $size ) {
		print "$url size was $size";
		}
	elsif( $HTTP::Size::ERROR == $HTTP::Size::INVALID_URL ) {
		print "$url is not a valid absolute URL";
		}
	elsif( $HTTP::Size::ERROR == $HTTP::Size::COULD_NOT_FETCH ) {
		print "Could not fetch $url\nHTTP status is $HTTP::Size::HTTP_STATUS";
		}
	elsif( $HTTP::Size::ERROR == $HTTP::Size::BAD_CONTENT_LENGTH ) {
		print "Could not determine content length of $url";
		}

=head1 DESCRIPTION

=head1 VARIABLES

The following global variables describes conditions from the last
function call:

	$ERROR
	$HTTP_STATUS

The C<$ERROR> variable may be set to any of these values:

	$INVALID_URL	    - the URL is not a valid absolute URL
	$COULD_NOT_FETCH    - the function encountered an HTTP error
	$BAD_CONTENT_LENGTH - could not determine a content type

The module does not export these variables, so you need to use
the full package specification outside of the HTTP::Size
package.

=cut

use subs qw( get_size _request );
use vars qw(
	$ERROR $HTTP_STATUS $VERSION
	$INVALID_URL $COULD_NOT_FETCH $BAD_CONTENT_LENGTH
	$CONTENT $CONTENT_TYPE
	);

use LWP::UserAgent;
use URI;
use HTTP::Request;

$VERSION = '1.151';

my $User_agent = LWP::UserAgent->new();

$INVALID_URL        = -1;
$COULD_NOT_FETCH    = -2;
$BAD_CONTENT_LENGTH = -3;

=head1 FUNCTIONS

=over 4

=item get_size( URL )

Fetch the specified absolute URL and return its content length.
The URL can be a string or an URI object.  The function tries
the HEAD HTTP method first, and on failure, tries the GET method.
In either case it sets $HTTP_STATUS to the HTTP response code.
If the response does not contain a Content-Length header, the
function takes the size of the message body.  If the HEAD method
returned a good status, but no Content-Length header, it retries
with the GET method.

On error, the function set $ERROR to one of these values:

	$INVALID_URL	    - the URL is not a valid absolute URL
	$COULD_NOT_FETCH    - the function encountered an HTTP error
	$BAD_CONTENT_LENGTH - could not determine a content type

=cut

sub get_size {
	my $url    = shift;
	my $method = shift || 0;
	_init();

	unless( ref $url eq 'URI' ) {
		$url = URI->new( $url );
		}

	unless( $url->scheme ) {
		$ERROR = $INVALID_URL;
		return;
		};

	my $response = '';
	my $size     = 0;

	unless( $method ) {
		my $request = HTTP::Request->new( HEAD => $url->as_string );

		$response    = _request( $request );
		$HTTP_STATUS = $response->code;
		$size        = $response->content_length;
		}

	unless( not $method and $response->is_success and $size ) {
		my $request  = HTTP::Request->new( GET => $url->as_string );
		$response    = _request( $request );
		$HTTP_STATUS = $response->code;
		$CONTENT     = $response->content;

		unless( $response->is_success ) {
			$ERROR = $COULD_NOT_FETCH;
			return;
			}
		elsif( not $response->content_length ) {
			$size = length $CONTENT;
			}
		elsif( $response->content_length ) {
			$size = $response->content_length;
			}

		}

	$CONTENT_TYPE = lc $response->content_type;

	return $size;
	}

=item get_sizes( URL, BASE_URL )

The get_sizes function is like get_size, although for HTML pages
it also fetches all of the images then sums the sizes of the
original page and image sizes. It returns a total download size.
In list context it returns the total download size and a hash
reference whose keys are the URLs that a browser should download
automatically (images):

	size
	ERROR
	HTTP_STATUS

The ERROR and HTTP_STATUS correspond to the values of $ERROR and
$HTTP_STATUS for that URL.

	my ( $total, $hash ) = HTTP::Size::get_sizes( $url );

	foreach my $key ( keys %$hash )
		{
		print "$key had an error" unless defined $size;
		}

The hash is always returned in list context (a change from
version 0.4).

Relative image links resolve accroding to BASE_URL, or by
a found BASE tag.  See L<HTML::SimpleLinkExtor>.

Javascript and style sheet links are unimplemented right now.

=cut

sub get_sizes {
	my $url  = shift;
	my $base = shift;

	my %hash;

	my $size = get_size( $url, 'GET' );

	@{$hash{$url}}{ qw(size ERROR HTTP_STATUS) }
		= ($size, $ERROR, $HTTP_STATUS);

	unless( $size and $CONTENT_TYPE eq 'text/html' ) {
		return wantarray ? ( $size, \%hash ) : $size;
		}

	require HTML::SimpleLinkExtor;

	my $total = $size;

	my $extor = HTML::SimpleLinkExtor->new( $url );

	$extor->parse( $CONTENT );

	foreach my $img ( $extor->img ) {
		my $size = get_size( $img ) || 0;

		@{$hash{$img}}{ qw(size ERROR HTTP_STATUS) }
			= ( $size, $ERROR, $HTTP_STATUS );

		$total += $size;
		}

	return wantarray ? ( $total, \%hash ) : $total;
	}

sub _init {
	$ERROR = $CONTENT_TYPE = $CONTENT = $HTTP_STATUS = '';
	}

sub _request {
	my $response = $User_agent->request( shift );

	$HTTP_STATUS = $response->code;

	return $response;
	}

=back

=head1 TO DO

* if i have to use GET, i should use Byte-Ranges to avoid
downloading the whole thing

* add a way to specify Basic Auth credentials

* download javascript and style sheets too.

=head1 SEE ALSO

L<HTML::SimpleLinkExtor>

=head1 SOURCE AVAILABILITY

This source is part of a GitHub project:

	https://github.com/briandfoy/http-size

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2000-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;

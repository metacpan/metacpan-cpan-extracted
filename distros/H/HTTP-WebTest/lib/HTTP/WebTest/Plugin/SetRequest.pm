# $Id: SetRequest.pm,v 1.20 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::SetRequest;

=head1 NAME

HTTP::WebTest::Plugin::SetRequest - Initializes HTTP request for web test

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin initializes the HTTP request for a web test.

=cut

use strict;
use URI;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 relative_urls

If set to C<yes> than C<HTTP-WebTest> supports relative URLs.  See
test parameter C<url> for more information.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 url

URL to test.

If test parameter C<relative_urls> is set to C<yes> than URL for each
test is treated as relative to the URL in the previous test.  URL in
the first test is treated as relative to C<http://localhost>.

If test parameter C<relative_urls> is set to C<no> than each URL is
treated as absolute.  In this case if schema part of URL is omitted
(i.e. URL doesn't start with C<http://>, C<ftp://>, etc) then
C<http://> is implied.

=head2 method

HTTP request method.

See RFC 2616 (HTTP/1.1 protocol).

=head3 Allowed values

C<GET>, C<POST>

=head3 Default value

C<GET>

=head2 http_headers

A list of HTTP header/value pairs.  Can be used to override default
HTTP headers or to add additional HTTP headers.

=head3 Example

    http_headers = ( Accept => text/plain, text/html )

=head2 params

A list of name/value pairs to be passed as parameters to the URL.
(This element is used to test pages that process input from forms.)

If the method key is set to C<GET>, these pairs are URI-escaped and
appended to the requested URL.

Example (wtscript file):

    url = http://www.hotmail.com/cgi-bin/hmhome
    params = ( curmbox
               F001 A005
               from
               HotMail )

generates the HTTP request with URI:

    http://www.hotmail.com/cgi-bin/hmhome?curmbox=F001%20A005&from=HotMail

If the method key is set to C<POST>, as long as all values are scalars
they are URI-escaped and put into content of the HTTP request.
C<application/x-www-form-urlencoded> content type is set for such HTTP
request.

If the method key is set to C<POST>, some values may be defined as
lists.  In this case L<HTTP::WebTest|HTTP::WebTest> uses
C<multipart/form-data> content type used for C<Form-based File Upload>
as specified in RFC 1867.  Each parameter with list value is treated
as file part specification with the following interpretation:

    ( FILE, FILENAME, HEADER => VALUE... )

where

=over 4

=item * FILE

The name of a file to open. This file will be read and its content
placed in the request.

=item * FILENAME

The optional filename to be reported in the request.  If it is not
specified than basename of C<FILE> is used.

=item * HEADER => VALUE

Additional optional headers for file part.

=back

Example (wtscript file):

    url = http://www.server.com/upload.pl
    method = post
    params = ( submit => ok
               file   => ( '/home/ilya/file.txt', 'myfile.txt' ) )

It generates HTTP request with C</home/ilya/file.txt> file included
and reported under name C<myfile.txt>.

=head2 auth

A list which contains two elements: userid/password pair to be used
for web page access authorization.

=head2 proxies

A list of service name/proxy URL pairs that specify proxy servers to
use for requests.

=head3 Example

    proxies = ( http => http://http_proxy.mycompany.com
                ftp  => http://ftp_proxy.mycompany.com )

=head2 pauth

A list which contains two elements: userid/password pair to be used
for proxy server access authorization.

=head2 user_agent

Set the product token that is used to identify the user agent on
the network.

=head3 Default value

C<HTTP-WebTest/NN>

where C<NN> is version number of HTTP-WebTest.

=head2 handle_redirects

If set to C<yes> then HTTP-WebTest automatically follows redirects.
It means that you never see HTTP responses with status codes 301 and
302.  This feature is disabled if this test parameter is set to C<no>.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<yes>

=head2 timeout

Set the timeout value in seconds.

=head3 Default value

C<180>

=cut

sub param_types {
    return q(url              uri
             relative_urls    yesno
	     method           scalar('^(?:GET|POST)$')
 	     params           hashlist
	     auth             list('scalar','scalar')
	     proxies          hashlist
	     pauth            list('scalar','scalar')
	     http_headers     hashlist
             user_agent       scalar
             handle_redirects yesno
             timeout          scalar);
}

sub prepare_request {
    my $self = shift;

    # get user agent object
    my $user_agent = $self->webtest->user_agent;

    # get request object
    my $request = $self->webtest->current_request;

    $self->validate_params(qw(url relative_urls method params
                              auth proxies pauth
                              http_headers user_agent
                              handle_redirects timeout));

    # get various params we handle
    my $url              = $self->test_param('url');
    my $relative_urls    = $self->yesno_test_param('relative_urls');
    my $method           = $self->test_param('method');
    my $params           = $self->test_param('params');
    my $auth             = $self->test_param('auth');
    my $proxies          = $self->test_param('proxies');
    my $pauth            = $self->test_param('pauth');
    my $headers          = $self->test_param('http_headers');
    my $ua_name          = $self->test_param('user_agent');
    my $handle_redirects = $self->yesno_test_param('handle_redirects', 1);
    my $timeout          = $self->test_param('timeout', 180);

    # set LWP's timeout
    $self->webtest->user_agent->timeout($timeout);

    # normalize uri
    if(defined $url) {
	if($relative_urls) {
	    my $current_test_num = $self->webtest->current_test_num;

	    my $prev_url = $current_test_num > 0 ?
		           $self->webtest->tests->[$current_test_num - 1]->request->uri :
			   'http://localhost/';

	    $url = URI->new_abs($url, $prev_url);
	} else {
	    # add shema part if it is missing
	    $url = "http://" . $url unless $url =~ m|^\w+://|;
	}
    }

    # set request uri
    $request->uri($url) if defined $url;

    # set request method (with default GET)
    if(defined $method) {
	if($method =~ /^POST$/i) {
	    $request->method('POST');
	    # ensure correct default value for content-type header
	    $request->header(Content_Type =>
			     'application/x-www-form-urlencoded');
	} else {
	    $request->method('GET');
	}
    } else {
	$request->method('GET');
    }

    # set request params
    if(defined $params) {
	my @params = ref($params) eq 'ARRAY' ? @$params : %$params;
	$request->params(\@params);
    }

    # pass authorization data
    if(defined $auth) {
	$request->authorization_basic(@$auth);
    }

    # set proxies
    if(defined $proxies) {
	for my $i (0 .. @$proxies / 2 - 1) {
	    $user_agent->proxy(@$proxies[2 * $i, 2 * $i + 1]);
	}
    }

    # pass proxy authorization data
    if(defined $pauth) {
	$request->proxy_authorization_basic(@$pauth);
    }

    # set http headers
    if(defined $headers) {
	$request->header(@$headers);
    }

    # set user agent name
    $ua_name = 'HTTP-WebTest/' . HTTP::WebTest->VERSION
	unless defined $ua_name;
    $user_agent->agent($ua_name);

    # define if requests are redirectable
    if($handle_redirects) {
	$user_agent->requests_redirectable([qw(GET POST)]);
    } else {
	$user_agent->requests_redirectable([]);
    }
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson.  All rights reserved.

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;

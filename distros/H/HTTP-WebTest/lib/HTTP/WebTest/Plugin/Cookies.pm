# $Id: Cookies.pm,v 1.7 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::Cookies;

=head1 NAME

HTTP::WebTest::Plugin::Cookies - Send and recieve cookies in tests

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin provides means to control sending and recieve cookies in
web test.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

use HTTP::Status;

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 accept_cookies

Option to accept cookies from the web server.

These cookies exist only while the program is executing and do not
affect subsequent runs.  These cookies do not affect your browser or
any software other than the test program.  These cookies are only
accessible to other tests executed during test sequence execution.

See also the <send_cookies> parameter.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<yes>

=head2 send_cookies

Option to send cookies to web server.  This applies to cookies
received from the web server or cookies specified using the C<cookies>
test parameter.

This does NOT give the web server(s) access to cookies created with a
browser or any user agent software other than this program.  The
cookies created while this program is running are only accessible to
other tests in the same test sequence.

See also the <accept_cookies> parameter.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<yes>

=head2 cookie

Synonym to C<cookies>.

It is deprecated parameter and may be removed in future versions of
L<HTTP::WebTest|HTTP::WebTest>.

=head2 cookies

This is a list parameter that specifies cookies to send to the web
server:

    cookies = ( cookie1_spec
                cookie2_spec
                ...
                cookieN_spec )

Currently there are two ways to specify a cookie.

=over 4

=item * Named style

A cookie is specified by a set of C<param =E<gt> value> pairs:

    (
      param => value
      ...
    )

List of all supported C<param =E<gt> value> pairs:

=over 4

=item version => VERSION

Version number of cookie spec to use, usually 0.

=item name => NAME (REQUIRED)

Name of cookie.  Cannot begin with a $ character.

=item value => VALUE (REQUIRED)

Value of cookie.

=item path => PATH (REQUIRED)

URL path name for which this cookie applies.  Must begin with a /
character.  See also path_spec.

=item domain => DOMAIN (REQUIRED)

Domain for which cookie is valid.  Must either contain two periods or
be equal to C<.local>.

=item port => PORT

List of allowed port numbers that the cookie may be returned to.  If
not specified, cookie can be returned to any port.  Must be specified
using the format C<N> or C<N, N, ..., N> where N is one or more
digits.

=item path_spec => PATH_SPEC

Ignored if version is less than 1.  Option to ignore the value of
path.  Default value is 0.

=over 4

=item * 1

Use the value of path.

=item * 0

Ignore the specified value of path.

=back

=item secure => SECURE

Option to require secure protocols for cookie transmission.  Default
value is 0.

=over 4

=item * 1

Use only secure protocols to transmit this cookie.

=item * 0

Secure protocols are not required for transmission.

=back

=item maxage => MAXAGE

Number of seconds until cookie expires.

=item discard => DISCARD

Option to discard cookie when the program finishes.  Default is 0.
(The cookie will be discarded regardless of the value of this
element.)

=over 4

=item * 1

Discard cookie when the program finishes.

=item * 0

Don't discard cookie.

=back

=item rest => NAME_VALUE_LIST

Defines additional cookie attributes.

Zero, one or several name/value pairs may be specified.  The name
parameters are words such as Comment or CommentURL and the value
parameters are strings that may contain embedded blanks.

=back

Example (wtscript file):

    cookies = ( ( name   => Cookie1
                  value  => cookie value )

                ( name   => Cookie2
                  value  => cookie value
                  path   => /
                  domain => .company.com ) )

                ( name   => Cookie2
                  value  => cookie value
                  rest   => ( Comment => this is a comment ) )

Example (Perl script):

    my $tests = [
                  ...
                  {
                    test_name => 'cookie',
                    cookies   => [ [
                                     name  => 'Cookie1',
                                     value => 'Value',
                                   ],
                                   [
                                     name  => 'Cookie2',
                                     value => 'Value',
                                     path  => '/',
                                   ] ],
                    ...
                  }
                  ...
                ]

=item * Row list style

This style of cookie specification is deprecated and may be removed in
future versions of L<HTTP::WebTest|HTTP::WebTest>.

Each cookie is specified by following list:

    ( VERSION
      NAME
      VALUE
      PATH
      DOMAIN
      PORT
      PATH_SPEC
      SECURE
      MAXAGE
      DISCARD
      NAME1
      VALUE1
      NAME2
      VALUE2
      ...
    )


Any element not marked below as REQUIRED may be defaulted by
specifying a null value or ''.

=over 4

=item * VERSION (REQUIRED)

Version number of cookie spec to use, usually 0.

=item * NAME (REQUIRED)

Name of cookie.  Cannot begin with a $ character.

=item * VALUE (REQUIRED)

Value of cookie.

=item * PATH (REQUIRED)

URL path name for which this cookie applies.  Must begin with a /
character.  See also path_spec.

=item * DOMAIN (REQUIRED)

Domain for which cookie is valid.  Must either contain two periods or
be equal to C<.local>.

=item * PORT

List of allowed port numbers that the cookie may be returned to.  If
not specified, cookie can be returned to any port.  Must be specified
using the format C<N> or C<N, N, ..., N> where N is one or more
digits.

=item * PATH_SPEC

Ignored if version is less than 1.  Option to ignore the value of
path.  Default value is 0.

=over 4

=item * 1

Use the value of path.

=item * 0

Ignore the specified value of path.

=back

=item * SECURE

Option to require secure protocols for cookie transmission.  Default
value is 0.

=over 4

=item * 1

Use only secure protocols to transmit this cookie.

=item * 0

Secure protocols are not required for transmission.

=back

=item * MAXAGE

Number of seconds until cookie expires.

=item * DISCARD

Option to discard cookie when the program finishes.  Default is 0.
(The cookie will be discarded regardless of the value of this
element.)

=over 4

=item * 1

Discard cookie when the program finishes.

=item * 0

Don't discard cookie.

=back

=item * name/value

Zero, one or several name/value pairs may be specified.  The name
parameters are words such as Comment or CommentURL and the value
parameters are strings that may contain embedded blanks.

=back

An example cookie would look like:

    cookies = ( ( 0
                  WebTest cookie #1
                  cookie value
                  /
                  .mycompany.com
                  ''
                  0
                  0
                  200
                  1
                ) )

=back

See RFC 2965 for details (ftp://ftp.isi.edu/in-notes/rfc2965.txt).

=cut

sub param_types {
    return q(accept_cookies yesno
             send_cookies   yesno
             cookie         list
             cookies        list);
}

use constant NCOOKIE_REFORMAT => 10;

sub prepare_request {
    my $self = shift;

    $self->validate_params(qw(accept_cookies send_cookies
                              cookies cookie));

    my $accept_cookies = $self->yesno_test_param('accept_cookies', 1);
    my $send_cookies   = $self->yesno_test_param('send_cookies', 1);
    my $cookies        = $self->test_param('cookies');

    $cookies ||= $self->test_param('cookie'); # alias for parameter
    $cookies = $self->transform_cookies($cookies) if defined $cookies;

    my $cookie_jar = $self->webtest->user_agent->cookie_jar;

    # configure cookie jar
    $cookie_jar->accept_cookies($accept_cookies);
    $cookie_jar->send_cookies($send_cookies);

    if(defined $cookies) {
	for my $cookie (@$cookies) {
	    $cookie_jar->set_cookie(@$cookie);
	}
    }
}

sub check_response {
    my $self = shift;

    # we don't check here anything - just some clean up
    my $cookie_jar = $self->webtest->user_agent->cookie_jar;
    delete $cookie_jar->{accept_cookies};
    delete $cookie_jar->{send_cookies};

    return ();
}

# transform cookies to some canonic representation
sub transform_cookies {
    my $self = shift;
    my $cookies = shift;

    # check if $cookies is array of arrays
    unless(ref($$cookies[0]) eq 'ARRAY') {
	return $self->transform_cookies([ $cookies ]);
    }

    my @cookies = ();

    for my $cookie (@$cookies) {
	# simple heuristic to distinguish deprecated format from new:
	# in new format $cookie->[0] cannot be a number while it is
	# expected for deprecated
	if($cookie->[0] =~ /^ \d* $/x) {
	    $cookie = $self->transform_cookie_deprecated($cookie);
	} else {
	    $cookie = $self->transform_cookie($cookie);
	}

	die "HTTP::WebTest: missing cookie name"
	    unless defined $cookie->[1];
	die "HTTP::WebTest: missing cookie path"
	    unless defined $cookie->[3];
	die "HTTP::WebTest: missing cookie domain"
	    unless defined $cookie->[4];

	push @cookies, $cookie;
    }

    return \@cookies;
}

# transform cookie to the canonic representation (a list expected by
# HTTP::Cookie::set_cookie)
sub transform_cookie {
    my $self = shift;
    my $cookie = shift;

    my %fields = ( version   => 0,
		   name      => 1,
		   value     => 2,
		   path      => 3,
		   domain    => 4,
		   port      => 5,
		   path_spec => 6,
		   secure    => 7,
		   expires   => 8,
		   discard   => 9,
		   rest      => 10 );

    my @canonic = ();
    my %cookie = @$cookie;
    while(my($field, $value) = each %cookie) {
	$canonic[$fields{$field}] = $value;
    }

    # convert rest part from array ref to hash ref
    $canonic[10] = { @{$canonic[10]} } if defined $canonic[10];

    return \@canonic;
}

# transform cookie specified using deprecated format to the canonic
# representation (a list expected by HTTP::Cookie::set_cookie)
sub transform_cookie_deprecated {
    my $self = shift;
    my $cookie = shift;

    # make a copy of cookie (missing fields are set to undef)
    my @canonic = @$cookie[0 .. NCOOKIE_REFORMAT - 1];

    # replace '' with undef
    @canonic = map +(defined($_) and $_ eq '') ? (undef) : $_,
	@canonic;

    # collect all additional attributes (name, value pairs)
    my @extra = @$cookie[ NCOOKIE_REFORMAT .. @$cookie - 1];
    push @canonic, { @extra };

    return \@canonic;
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

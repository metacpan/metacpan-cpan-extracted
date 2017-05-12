# $Id: Cookies.pm,v 1.6 2003/07/03 15:54:00 m_ilya Exp $

package HTTP::WebTest::Cookies;

=head1 NAME

HTTP::WebTest::Cookies - Cookie storage and management

=head1 SYNOPSIS

    use HTTP::WebTest::Cookies;

    $cookie_jar = HTTP::WebTest::Cookies->new;

    $cookie_jar->accept_cookies($bool);
    $cookie_jar->send_cookies($bool);

    $cookie_jar->add_cookie_header($request);
    $cookie_jar->extract_cookies($response);

=head1 DESCRIPTION

Subclass of L<HTTP::Cookies|HTTP::Cookies> which enables optional
transmission and receipt of cookies.

=head1 METHODS

=cut

use strict;

use base qw(HTTP::Cookies);

use HTTP::WebTest::Utils qw(make_access_method);

=head2 accept_cookies($optional_accept_cookies)

Returns the current setting of accept_cookies.
If optional boolean parameter C<$optional_accept_cookies> is passed,
enables or disables receipt of cookies.

=head3 Returns

True if receipt of cookies is enabled; false otherwise.

=cut

*accept_cookies = make_access_method('ACCEPT_COOKIES');

=head2 send_cookies($optional_send_cookies)

Returns the current setting of send_cookies.
If optional boolean parameter C<$optional_send_cookies> is passed,
enables or disables transmission of cookies.

=head3 Returns

True if transmission of cookies is enabled; false otherwise.

=cut

*send_cookies = make_access_method('SEND_COOKIES');

=head2 extract_cookies (...)

Overloaded method.  If receipt of cookies is enabled, passes all arguments 
to C<SUPER::extract_cookies>.  Otherwise, does nothing.

=cut

sub extract_cookies {
    my $self = shift;
    $self->SUPER::extract_cookies(@_) if $self->accept_cookies;
}

=head2 add_cookie_header (...)

Overloaded method.  If transmission of cookies is enabled,
passes all arguments to C<SUPER::add_cookie_header>.  Otherwise, does nothing.

=cut

sub add_cookie_header {
    my $self = shift;
    $self->SUPER::add_cookie_header(@_) if $self->send_cookies;
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson.  All rights reserved.

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::Cookies|HTTP::Cookies>

=cut

1;

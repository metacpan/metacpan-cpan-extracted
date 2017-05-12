package Eve::HttpResponse;

use parent qw(Eve::Class);

use strict;
use warnings;

=head1 NAME

B<Eve::HttpResponse> - an HTTP response abstract class.

=head1 SYNOPSIS

    use Eve::HttpResponse::Implementation;

    $response->set_status(code => 302);
    $response->set_header(name => 'Location', value => '/other');
    $response->set_cookie(
        name => 'cookie1',
        value => 'value',
        domain => '.example.com',
        path => '/some/',
        expires => '+1d',
        secure = >1);
    $response->set_body(text => 'Hello world!');

    print $response->get_text();

=head1 DESCRIPTION

The class is an interface defining abstraction that is required to be
used as a parent class for various HTTP response implementations.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my $self = shift;

    $self->{'_header_hash'} = {};
    $self->{'_cookie_list'} = [];
    $self->{'_code'} = 200;
    $self->{'_body'} = '';

    return;
}

=head2 B<set_header()>

Sets or overwrites an HTTP header of the response.

=head3 Arguments

=over 4

=item C<name>

=item C<value>

=back

=cut

sub set_header {
    Eve::Error::NotImplemented->throw();
}

=head2 B<set_status()>

Sets or overwrites the HTTP response status.

=head3 Arguments

=over 4

=item C<code>

=back

=cut

sub set_status {
    Eve::Error::NotImplemented->throw();
}

=head2 B<set_cookie()>

Sets an HTTP response cookie.

=head3 Arguments

=over 4

=item C<name>

=item C<value>

=item C<domain>

=item C<path>

=item C<expires>

=item C<secure>

(optional) defaults to false

=back

=cut

sub set_cookie {
    Eve::Error::NotImplemented->throw();
}

=head2 B<set_body()>

Sets or overwrites the HTTP response body.

=head3 Arguments

=over 4

=item C<text>

=back

=cut

sub set_body {
    Eve::Error::NotImplemented->throw();
}

=head2 B<get_text()>

=head3 Returns

The HTTP response as text.

=cut

sub get_text {
    Eve::Error::NotImplemented->throw();
}

=head1 SEE ALSO

=over 4

=item C<Eve::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHORS

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;

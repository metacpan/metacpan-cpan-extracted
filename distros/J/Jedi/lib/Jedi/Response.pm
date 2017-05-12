#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Response;

# ABSTRACT: response object

use Moo;

our $VERSION = '1.008';    # VERSION

use Jedi::Helpers::Hash;

has 'status' => ( is => 'rw', default => sub {404} );

has 'headers' => ( is => 'ro', default => sub { {} } );

sub set_header {
    my ( $self, $header_name, $header_value ) = @_;
    $self->headers->{$header_name} = [$header_value];
    return;
}

sub push_header {
    my ( $self, $header_name, $header_value ) = @_;
    if ( exists $self->headers->{$header_name} ) {
        push @{ $self->headers->{$header_name} }, $header_value;
    }
    else {
        $self->set_header( $header_name, $header_value );
    }
    return;
}

has 'body' => ( is => 'rw', default => sub {''} );

sub to_psgi {
    my ($self) = @_;

    $self->body('No route found !')
        if $self->status == 404 && !length( $self->body );

    return [ $self->status, $self->headers->to_arrayref, [ $self->body ] ];
}

1;
__END__
=pod

=head1 NAME

Jedi::Response - response object

=head1 VERSION

version 1.008

=head1 DESCRIPTION

This is the response you will have to fill from route to route.

=head1 ATTRIBUTES

=head2 status

Status code, by default is 404 (not found).

You can consult the L<HTTP status|http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html> but here some common :

 500: internal server error
 404: route not found
 405: access forbidden
 204: no content
 200: status ok, with content
 302: redirect
 301: permanent redirect

=head2 headers

This contain the headers you will send with your response.

You should use the method L</set_header> and L</push_header> instead of filling this attribute directly.

The attribute has this form :

 key => [val1, val2 ...],
 key2 => [val4],

=head2 body

The body is the string return to the browser.

 $response->body("Hello World !");

=head1 METHODS

=head2 set_header

Set an header to a specific value.

 $response->set_header('X-AUTH', $token);
 $response->set_header('Location', 'http://blog.celogeek.com');

=head2 push_header

Push an header to a specific value

 $response->push_header('Set-Cookie', 'myCookie=a');
 $response->push_header('Set-Cookie', 'myCookie2=b');

You will see :

 Set-Cookie: myCookie=a
 Set-Cookie: myCookie=b

=head2 to_psgi

This return the content in a psgi form.

It is use by Jedi to transform the response into a valid psgi response.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


package HTTP::Throwable::Role::TextBody;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::TextBody::VERSION = '0.027';
use Moo::Role;

sub body { $_[0]->text_body }

sub body_headers {
    my ($self, $body) = @_;

    return [
        'Content-Type'   => 'text/plain',
        'Content-Length' => length $body,
    ];
}

sub as_string { $_[0]->body }

requires 'text_body';

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::TextBody - an exception with a plaintext body

=head1 VERSION

version 0.027

=head1 OVERVIEW

This is a very simple role, implementing the required C<as_string>, C<body>,
and C<body_headers> for L<HTTP::Throwable>.  In turn, it requires that a
C<text_body> method be provided.

When an HTTP::Throwable exception uses this role, its PSGI response will have a
C<text/plain> content type and will send the result of calling its C<text_body>
method as the response body.  It will also stringify to the text body.

The role L<HTTP::Throwable::Role::BoringText> can be useful to provide a
C<text_body> method that issues the C<status_line> as the body.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: an exception with a plaintext body

#pod =head1 OVERVIEW
#pod
#pod This is a very simple role, implementing the required C<as_string>, C<body>,
#pod and C<body_headers> for L<HTTP::Throwable>.  In turn, it requires that a
#pod C<text_body> method be provided.
#pod
#pod When an HTTP::Throwable exception uses this role, its PSGI response will have a
#pod C<text/plain> content type and will send the result of calling its C<text_body>
#pod method as the response body.  It will also stringify to the text body.
#pod
#pod The role L<HTTP::Throwable::Role::BoringText> can be useful to provide a
#pod C<text_body> method that issues the C<status_line> as the body.

package Haineko::HTTPD::Response;
use parent 'Plack::Response';
use strict;
use warnings;

sub mime {
    my $class = shift;
    my $ctype = shift || 'plain';
    my $types = {
        'json'  => 'application/json',
        'html'  => 'text/html; charset=utf-8',
        'plain' => 'text/plain; charset=utf-8',
    };

    $ctype = 'plain' if $ctype eq 'text';
    $ctype = 'plain' unless exists $types->{ $ctype };
    return $types->{ $ctype };
}

sub text {
    my $self = shift;
    my $code = shift || 200;
    my $text = shift;

    $self->code( $code );
    return $self->_res( $text, 'text' );
}

sub json {
    my $self = shift;
    my $code = shift || 200;
    my $data = shift;   # (Ref->[HASH|ARRAY]) or JSON as a string
    my $json = q();

    require Haineko::JSON;
    $json = ref $data ? Haineko::JSON->dumpjson( $data ) : $data;
    $self->code( $code );
    return $self->_res( $json, 'json' );
}

sub _res {
    my $self = shift;
    my $text = shift || q();
    my $type = shift || 'json';
    my $head = [
        'Content-Type' => Haineko::HTTPD::Response->mime( $type ),
        'Content-Length' => length $text,
        'X-Content-Type-Options' => 'nosniff',
    ];

    $self->code(200) unless $self->code;
    $self->headers( $head );
    $self->body( $text );
    return $self;
}

1;
__END__
=encoding utf-8

=head1 NAME

Haineko::HTTPD::Response - Child class of Plack::Response

=head1 DESCRIPTION

Haineko::HTTPD::Response is child class of Plack::Response and contain some
wrapper methods.

=head1 SYNOPSIS

    use Haineko::HTTPD::Response;
    my $r = Haineko::HTTPD::Response->new;          # => isa 'Haineko::HTTPD::Response'
    my $v = Haineko::HTTPD::Response->mime('text'); # => is 'text/plain; charset=utf-8'

    $r->text( 200, 'Nyaaaaa' );         # returns [ 200, [ ... ], [ 'Nyaaaaa' ] ]
    $r->json( 200, { 'neko' => 1 } );   # returns [ 200, [ ... ], [ '{ "neko": 1 }' ] ]

=head1 CLASS METHODS

=head2 C<B<mime( I<Type> )>>

C<mime()> returns the value of "Content-Type" header for the argument. For example,
C<mime('json')> returns 'application/json', C<mime('text')> returns 'text/plain'.

=head1 INSTANCE METHODS

=head2 C<B<text( I<Code>, I<Content> )>>

C<text()> is a wrapper method for C<_res()> method to respond 'text/plain' content.

=head2 C<B<json( I<Code>, I<ArrayRef|HashRef> )>>

C<json()> is a wrapper method for C<_res()> method to respond 'application/json'
content. The 2nd argument will be converted to JSON as a string automatically.

=head2 C<B<_res( I<Content>, I<Type> )>>

C<_res()> is wrapper method for responding. For example C<_res( 'Nyaaa', 'text' )>
or C<_res( { 'neko': 2 }, 'json' )>.

=head1 SEE ALSO

L<Haineko::HTTPD>

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut

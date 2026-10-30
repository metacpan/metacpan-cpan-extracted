package Mail::AuthenticationResults::Token::QuotedString;
# ABSTRACT: Class for modelling AuthenticationResults Header parts detected as quoted strings

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20261029'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Token';


sub is {
    my ( $self ) = @_;
    return 'string';
}

sub parse {
    my ($self) = @_;

    my $header = $self->{ 'header' };
    my $value = q{};

    my $first = substr( $header,0,1 );
    croak 'not a quoted string' if $first ne '"';

    my $end = index( $header, '"', 1 );
    croak 'Quoted string not closed' if $end == -1;

    $value  = substr( $header, 1, $end - 1 );
    $header = substr( $header, $end + 1 );

    $self->{ 'value' } = $value;
    $self->{ 'header' } = $header;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Token::QuotedString - Class for modelling AuthenticationResults Header parts detected as quoted strings

=head1 VERSION

version 2.20261029

=head1 DESCRIPTION

Token representing a quoted string

=head1 AUTHOR

Jemma Bradshaw <jemma@nothingbutstatic.dev>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Jemma Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

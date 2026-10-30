package Mail::AuthenticationResults::Token::Comment;
# ABSTRACT: Class for modelling AuthenticationResults Header parts detected as comments

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20261029'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Token';


sub is {
    my ( $self ) = @_;
    return 'comment';
}

sub parse {
    my ($self) = @_;

    my $header = $self->{ 'header' };
    my $value = q{};
    my $depth = 0;

    my $first = substr( $header,0,1 );
    if ( $first ne '(' ) {
        croak 'Not a comment';
    }

    my $end;
    while ( $header =~ /([()])/g ) {
        if ( $1 eq '(' ) {
            $depth++;
        }
        else {
            $depth--;
            if ( $depth == 0 ) {
                $end = pos( $header );
                last;
            }
        }
    }

    if ( $depth != 0 ) {
        croak 'Mismatched parens in comment';
    }

    $value  = substr( $header, 1, $end - 2 );
    $header = substr( $header, $end );

    $self->{ 'value' } = $value;
    $self->{ 'header' } = $header;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Token::Comment - Class for modelling AuthenticationResults Header parts detected as comments

=head1 VERSION

version 2.20261029

=head1 DESCRIPTION

Token representing a comment

=head1 AUTHOR

Jemma Bradshaw <jemma@nothingbutstatic.dev>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Jemma Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

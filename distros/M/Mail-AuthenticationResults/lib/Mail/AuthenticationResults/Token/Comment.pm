package Mail::AuthenticationResults::Token::Comment;
# ABSTRACT: Class for modelling AuthenticationResults Header parts detected as comments

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
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

    while ( length $header > 0 ) {
        my $first = substr( $header,0,1 );
        $header   = substr( $header,1 );
        $value .= $first;
        if ( $first eq '(' ) {
            $depth++;
        }
        elsif ( $first eq ')' ) {
            $depth--;
            last if $depth == 0;
        }
    }

    if ( $depth != 0 ) {
        croak 'Mismatched parens in comment';
    }

    $value =~ s/^\(//;
    $value =~ s/\)$//;

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

version 2.20210915

=head1 DESCRIPTION

Token representing a comment

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

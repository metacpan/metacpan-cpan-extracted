package Mail::AuthenticationResults::Token::Comment;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
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


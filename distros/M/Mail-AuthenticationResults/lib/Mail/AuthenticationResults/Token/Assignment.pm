package Mail::AuthenticationResults::Token::Assignment;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Token';

sub is {
    my ( $self ) = @_;
    return 'assignment';
}

sub parse {
    my ($self) = @_;

    my $header = $self->{ 'header' };
    my $value = q{};

    my $first = substr( $header,0,1 );
    if ( $first ne '=' && $first ne '.' && $first ne '/' ) {
        croak 'not an assignment';
    }

    $header   = substr( $header,1 );

    $self->{ 'value' } = $first;
    $self->{ 'header' } = $header;

    return;
}

1;


package Mail::AuthenticationResults::Token::String;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
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

    while ( length $header > 0 ) {
        my $first = substr( $header,0,1 );
        last if $first =~ /\s/;
        last if $first eq '"';
        last if $first eq '(';
        last if $first eq ';';
        last if $first eq '=';
        # ToDo, can't do this yet as it is valid in values but not in keys
        #last if $first eq '/';
        #last if $first eq '.';
        $value .= $first;
        $header   = substr( $header,1 );
    }

    croak 'Not a string' if $value eq q{};

    $self->{ 'value' } = $value;
    $self->{ 'header' } = $header;

    return;
}

1;


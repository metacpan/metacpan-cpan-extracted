package Mail::AuthenticationResults::Header::Comment;
use strict;
use warnings;
our $VERSION = '1.20171226'; # VERSION
use Scalar::Util qw{ weaken };

sub HAS_VALUE{ return 1; }

use base 'Mail::AuthenticationResults::Header::Base';

sub set_value {
    my ( $self, $value ) = @_;

    my $remain = $value;
    my $depth = 0;
    while ( length $remain > 0 ) {
        my $first = substr( $remain,0,1 );
        $remain   = substr( $remain,1 );
        $depth++ if $first eq '(';
        $depth-- if $first eq ')';
        die 'Out of order parent in comment' if $depth == -1;
    }
    die 'Mismatched parens in comment' if $depth != 0;


    $self->{ 'value' } = $value;
    return $self;
}

sub as_string {
    my ( $self ) = @_;
    my $string = '(' . $self->value() . ')';
    return $string;
}

1;

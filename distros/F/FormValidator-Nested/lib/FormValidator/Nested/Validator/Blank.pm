package FormValidator::Nested::Validator::Blank;
use strict;
use warnings;
use utf8;

our $BLANK = 1;

sub not_blank {
    my ( $value, $options, $req ) = @_;

    if ( ! defined $value || $value eq '' ) {
        return 0;
    }
    return 1;
}

sub evaluation {
    my ( $value, $options, $req ) = @_;

    my $return_val;
    {
        no warnings;
        $return_val = eval($options->{code}); ## no critic
    }

    if ( !$return_val ) {
        return 0;
    }
    return 1;
}


1;


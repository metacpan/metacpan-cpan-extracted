package FormValidator::Nested::Validator::Number;
use strict;
use warnings;
use utf8;



sub number {
    my ( $value, $options, $req ) = @_;

    if ( $value =~ /[^0-9]/ ) {
        return 0;
    }
    return 1;
}

sub float {
    my ( $value, $options, $req ) = @_;

    if ( $value !~ /^[0-9]+(?:\.[0-9]+)?$/ ) {
        return 0;
    }
    return 1;
}



1;

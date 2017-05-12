package FormValidator::Nested::Validator::Bool;
use strict;
use warnings;
use utf8;


sub bool {
    my ( $value, $options, $req ) = @_;

    if ( $value ne '0' && $value ne '1' ) {
        return 0;
    }
    return 1;
}


1;

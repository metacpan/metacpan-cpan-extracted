package FormValidator::Nested::Validator::Internal;
use strict;
use warnings;
use utf8;


sub nested_hash {
    my ( $value, $options, $req ) = @_;

    if ( ref $value ne 'HASH' ) {
        return 0;
    }

    return 1;
}


1;


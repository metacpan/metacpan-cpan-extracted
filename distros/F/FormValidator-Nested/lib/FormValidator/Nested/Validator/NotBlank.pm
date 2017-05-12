package FormValidator::Nested::Validator::NotBlank;
use strict;
use warnings;
use utf8;


# blankのときは実行されないやつ

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

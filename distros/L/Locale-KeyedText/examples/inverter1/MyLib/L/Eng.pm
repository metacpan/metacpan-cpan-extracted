#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

use Readonly;
Readonly my %TEXT_STRINGS => (
    'MYLIB_MYINV_NO_ARG' => q[my_invert(): argument $number is missing],
    'MYLIB_MYINV_BAD_ARG'
        => q[my_invert(): argument $number is not a number,]
           . q[ it is "<GIVEN_VALUE>"],
    'MYLIB_MYINV_RES_INF'
        => q[my_invert(): result is infinite because]
           . q[ argument $number is zero],
);

{ package MyLib::L::Eng; # module
    sub get_text_by_key {
        my (undef, $msg_key) = @_;
        return $TEXT_STRINGS{$msg_key};
    }
} # module MyLib::L::Eng

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.

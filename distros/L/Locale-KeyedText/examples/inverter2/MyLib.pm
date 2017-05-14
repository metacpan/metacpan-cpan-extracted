#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

use Locale::KeyedText;

###########################################################################
###########################################################################

{ package MyLib; # module
    sub my_invert {
        my (undef, $number) = @_;
        die Locale::KeyedText::Message->new({
                'msg_key' => 'MYLIB_MYINV_NO_ARG' })
            if !defined $number;
        die Locale::KeyedText::Message->new({
                'msg_key'  => 'MYLIB_MYINV_BAD_ARG',
                'msg_vars' => { 'GIVEN_VALUE' => $number },
            })
            if $number !~ m/^-?(\d+\.?|\d*\.\d+)$/x; # integer or decimal
        die Locale::KeyedText::Message->new({
                'msg_key' => 'MYLIB_MYINV_RES_INF' })
            if $number == 0;
        return 1 / $number;
    }
} # module MyLib

###########################################################################
###########################################################################

use Readonly;
Readonly my %TEXT_STRINGS_E => (
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
        return $TEXT_STRINGS_E{$msg_key};
    }
} # module MyLib::L::Eng

###########################################################################
###########################################################################

use Readonly;
Readonly my %TEXT_STRINGS_F => (
    'MYLIB_MYINV_NO_ARG' => q[my_invert(): paramètre $number est manquant],
    'MYLIB_MYINV_BAD_ARG'
        => q[my_invert(): paramètre $number est ne nombre,]
           . q[ il est "<GIVEN_VALUE>"],
    'MYLIB_MYINV_RES_INF'
        => q[my_invert(): aboutir a est infini parce que]
           . q[ paramètre $number est zero],
);

{ package MyLib::L::Fre; # module
    sub get_text_by_key {
        my (undef, $msg_key) = @_;
        return $TEXT_STRINGS_F{$msg_key};
    }
} # module MyLib::L::Fre

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.

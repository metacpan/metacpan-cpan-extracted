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

1; # Magic true value required at end of a reuseable file's code.

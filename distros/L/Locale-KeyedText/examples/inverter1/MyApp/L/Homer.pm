#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

use Readonly;
Readonly my %TEXT_STRINGS => (
    'MYAPP_HELLO' => q[Light goes on!],
    'MYAPP_GOODBYE' => q[Light goes off!],
    'MYAPP_PROMPT'
        => q[Give me a county thingy, or push that big button instead.],
    'MYAPP_RESULT'
        => q[Turn "<ORIGINAL>" upside down and get "<INVERTED>",]
           . q[ not "<ORIGINAL>".],
    'MYLIB_MYINV_NO_ARG' => q[Why you little ...!],
    'MYLIB_MYINV_BAD_ARG' => q["<GIVEN_VALUE>" isn't a county thingy!],
    'MYLIB_MYINV_RES_INF' => q[Don't you give me a big donut!],
);

{ package MyApp::L::Homer; # module
    sub get_text_by_key {
        my (undef, $msg_key) = @_;
        return $TEXT_STRINGS{$msg_key};
    }
} # module MyApp::L::Homer

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.

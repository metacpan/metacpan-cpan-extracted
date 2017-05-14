#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

use Readonly;
Readonly my %TEXT_STRINGS => (
    'MYAPP_HELLO' => q[Bienvenue allé MyApp.],
    'MYAPP_GOODBYE' => q[Salut!],
    'MYAPP_PROMPT'
        => q[Fournir nombre être inverser, ou appuyer sur]
           . q[ ENTER être arrêter.],
    'MYAPP_RESULT' => q[Renversement "<ORIGINAL>" est "<INVERTED>".],
);

{ package MyApp::L::Fre; # module
    sub get_text_by_key {
        my (undef, $msg_key) = @_;
        return $TEXT_STRINGS{$msg_key};
    }
} # module MyApp::L::Fre

###########################################################################
###########################################################################

1; # Magic true value required at end of a reuseable file's code.

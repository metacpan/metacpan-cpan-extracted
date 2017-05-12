use 5.008001;
use utf8;
use strict;
use warnings;

use Locale::KeyedText::Message 2.001000;
use Locale::KeyedText::Translator 2.001000;

{ package Locale::KeyedText; # package
    BEGIN {
        our $VERSION = '2.001000';
        $VERSION = eval $VERSION;
    }
} # package Locale::KeyedText

1;

package Locales::DB::CharacterOrientation::Tiny;

use strict;
use warnings;

# Auto generated from CLDR
use if $Locales::_UNICODE_STRINGS, 'utf8';

$Locales::DB::CharacterOrientation::Tiny::VERSION = '0.09';

$Locales::DB::CharacterOrientation::Tiny::cldr_version = '2.0';

my %rtl = (
    'ur' => '',
    'ku' => '',
    'he' => '',
    'fa' => '',
    'ps' => '',
    'ar' => '',
);

sub get_orientation {
    if ( exists $rtl{ $_[0] } ) {
        return 'right-to-left';
    }
    else {
        require Locales;
        my ($l) = Locales::split_tag( $_[0] );
        if ( $l ne $_[0] ) {
            return 'right-to-left' if exists $rtl{$l};
        }
        return 'left-to-right';
    }
}

1;

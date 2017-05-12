package Email::Address::JP::Mobile::NonMobile;
use strict;
use warnings;
use base 'Email::Address::JP::Mobile::Base';

our $Encoding    = 'iso-2022-jp';
our $EncodingMap = {
    'iso-2022-jp' => {
        mime  => 'MIME-Header-ISO_2022_JP',
        send  => 'iso-2022-jp',
        parse => 'iso-2022-jp',
    },
    'utf-8' => {
        mime  => 'MIME-Header',
        send  => 'utf-8',
        parse => 'utf-8',
    },
};

sub matches {
    1;
}

sub name { 'NonMobile' }

sub carrier_letter { 'N' }

sub is_mobile { 0 }

sub mime_encoding {
    Encode::find_encoding($EncodingMap->{ lc $Encoding }{mime});
}

sub send_encoding {
    Encode::find_encoding($EncodingMap->{ lc $Encoding }{send});
}

sub parse_encoding {
    Encode::find_encoding($EncodingMap->{ lc $Encoding }{parse});
}

1;

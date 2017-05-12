package Email::Address::JP::Mobile::EZweb;
use strict;
use warnings;
use base 'Email::Address::JP::Mobile::Base';

my $regex = qr/^(?:
ezweb\.ne\.jp|
.*\.ezweb\.ne\.jp
)$/x;

sub matches {
    $_[1]->host =~ $regex;
}

sub name { 'EZweb' }

sub carrier_letter { 'E' }

sub is_mobile { 1 }

sub mime_encoding {
    Encode::find_encoding('MIME-Header-JP-Mobile-KDDI');
}

sub send_encoding {
    Encode::find_encoding('x-sjis-kddi-auto');
}

sub parse_encoding {
    Encode::find_encoding('x-iso-2022-jp-kddi-auto');
}

1;

package Email::Address::JP::Mobile::AirH;
use strict;
use warnings;
use base 'Email::Address::JP::Mobile::Base';

my $regex = qr/^(?:
pdx\.ne\.jp|
d.\.pdx\.ne\.jp|
wm\.pdx\.ne\.jp|
willcom\.com
)$/x;

sub matches {
    $_[1]->host =~ $regex;
}

sub name { 'AirH' }

sub carrier_letter { 'H' }

sub is_mobile { 1 }

sub mime_encoding {
    Encode::find_encoding('MIME-Header-JP-Mobile-AirH');
}

sub send_encoding {
    Encode::find_encoding('x-sjis-airh');
}

sub parse_encoding {
    Encode::find_encoding('x-iso-2022-jp-airh');
}

1;

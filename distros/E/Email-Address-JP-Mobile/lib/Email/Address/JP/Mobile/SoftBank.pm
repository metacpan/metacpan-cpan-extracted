package Email::Address::JP::Mobile::SoftBank;
use strict;
use warnings;
use base 'Email::Address::JP::Mobile::Base';

my $regex = qr/^(?:
jp\-[dhtckrnsq]\.ne\.jp|
[dhtckrnsq]\.vodafone\.ne\.jp|
softbank\.ne\.jp|
disney.ne.jp
)$/x;

sub matches {
    $_[1]->host =~ $regex;
}

sub name { 'SoftBank' }

sub carrier_letter { 'V' }

sub is_mobile { 1 }

sub mime_encoding {
    Encode::find_encoding('MIME-Header-JP-Mobile-SoftBank');
}

sub send_encoding {
    Encode::find_encoding('x-utf8-softbank');
}

sub parse_encoding {
    Encode::find_encoding('iso-2022-jp');
}

1;

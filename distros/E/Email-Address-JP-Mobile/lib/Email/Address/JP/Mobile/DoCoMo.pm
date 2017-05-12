package Email::Address::JP::Mobile::DoCoMo;
use strict;
use warnings;
use base 'Email::Address::JP::Mobile::Base';

my $regex = qr/^(?:
docomo\.ne\.jp
)$/x;

sub matches {
    $_[1]->host =~ $regex;
}

sub name { 'DoCoMo' }

sub carrier_letter { 'I' }

sub is_mobile { 1 }

sub mime_encoding {
    Encode::find_encoding('MIME-Header-JP-Mobile-DoCoMo');
}

sub send_encoding {
    Encode::find_encoding('x-sjis-docomo');
}

sub parse_encoding {
    Encode::find_encoding('iso-2022-jp');
}

1;

package Email::Address::JP::Mobile::Base;
use strict;
use warnings;

use Encode;
use Encode::JP::Mobile;

sub new {
    bless {}, shift;
}

sub matches { 0 }

sub name { '' }

sub carrier_letter { '' }

sub is_mobile { 0 }

sub mime_encoding { }

sub send_encoding { }

sub parse_encoding { }

1;

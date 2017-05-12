package HTML::ReplacePictogramMobileJp::AirHPhone;
use strict;
use warnings;
use HTML::ReplacePictogramMobileJp::Base;
use Encode;
use Encode::JP::Mobile;

filter utf8 => 'utf-8', sub {
    unicode_hex_cref 'I';
};

filter sjis => 'x-sjis-airh', sub {
    unicode_property 'I';

    # sjis hex cref
    s/&#x([0-9A-F]{4});/
        callback(ord(decode 'x-sjis-docomo', pack 'H*', sprintf '%X', hex $1), 'I');
    /gei;
};

1;

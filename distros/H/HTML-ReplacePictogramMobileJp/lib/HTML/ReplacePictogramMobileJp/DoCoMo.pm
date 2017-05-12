package HTML::ReplacePictogramMobileJp::DoCoMo;
use strict;
use warnings;
use HTML::ReplacePictogramMobileJp::Base;
use Encode;

filter utf8 => 'x-utf8-docomo', sub {
    unicode_property 'I';
    unicode_hex_cref 'I';
};

filter sjis => 'x-sjis-docomo', sub {
    unicode_property 'I';
    unicode_hex_cref 'I';

    s/&#([0-9]+);/
        my $original = $1;
        my $x = unpack 'U*', decode 'x-sjis-imode', pack 'H*', sprintf '%x', $original;
        callback($x, 'I')
    /gei;
};

1;

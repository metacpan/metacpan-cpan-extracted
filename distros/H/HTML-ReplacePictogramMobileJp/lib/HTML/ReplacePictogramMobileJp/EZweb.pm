package HTML::ReplacePictogramMobileJp::EZweb;
use strict;
use warnings;
use HTML::ReplacePictogramMobileJp::Base;
use Encode;
use Encode::JP::Mobile ':props';

filter utf8 => 'x-utf8-kddi', sub {
    unicode_property 'E';
    unicode_hex_cref 'E';
    img_localsrc 'E';
};

# とりあえず KDDI-Auto をつかう.どっちにするべき?
filter sjis => 'x-sjis-kddi-auto', sub {
    s/&#x([0-9A-F]{4});/
        my $original = $1;
        # hex cref でドコモの絵文字も表示できる(sjis)
        my $x = decode('cp932', pack 'H*', $original);
        if ($x =~ m{(\p{InDoCoMoPictograms})}) {
            HTML::ReplacePictogramMobileJp::Base::callback(ord decode('x-utf8-kddi', encode('x-utf8-kddi', $1)), 'E')
        } else {
            callback(hex $original, 'E')
        }
    /ge;

    img_localsrc 'E';

    unicode_property 'E';
};

1;

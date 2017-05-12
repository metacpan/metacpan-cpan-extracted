package HTML::ReplacePictogramMobileJp::Vodafone;
use strict;
use warnings;
use HTML::ReplacePictogramMobileJp::Base;

filter utf8 => 'x-utf8-softbank', sub {
    unicode_hex_cref 'V';
    unicode_property 'V';
};

filter sjis => 'x-sjis-softbank', sub {
    unicode_hex_cref 'V';
    unicode_property 'V';
};

1;

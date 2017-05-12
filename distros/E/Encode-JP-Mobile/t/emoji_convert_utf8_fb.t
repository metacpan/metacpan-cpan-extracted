use strict;
use Test::More;
use Encode;
use Encode::JP::Mobile;
use Encode qw(:fallback_all);

plan tests => 3 + 2;

is encode('x-utf8-kddi', "\x{E652}", FB_XMLCREF), '&#xe652;', 'xmlcref fallback kddi';
is encode('x-utf8-vodafone', "\x{E652}", FB_XMLCREF), '&#xe652;', 'xmlcref fallback vodafone';
is encode('x-utf8-docomo', "\x{E538}", FB_XMLCREF), '&#xe538;', 'xmlcref fallback docomo';

is encode('x-utf8-kddi', "\x{E04A}\x{E428}", sub { sprintf '<%X>', shift }), "\xEE\xBD\xA0<E428>";
is encode('x-utf8-kddi', "\x{E04A}\x{E428}", sub { '&#x3013;' }), "\xEE\xBD\xA0&#x3013;";

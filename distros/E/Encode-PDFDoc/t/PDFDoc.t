use strict;
use Test::More tests => 6;

BEGIN {
    use_ok('Encode');
    use_ok('Encode::PDFDoc');
}

is(decode('PDFDoc', 'ASCII string'), 'ASCII string', 'ASCII decode');
is(encode('PDFDoc', 'ASCII string'), 'ASCII string', 'ASCII encode');

is(decode('PDFDoc', "\222\223"), "\x{2122}\x{FB01}", 'non-ASCII decode');
is(encode('PDFDoc', "\x{2019}\x{201A}"), "\220\221", 'non-ASCII encode');

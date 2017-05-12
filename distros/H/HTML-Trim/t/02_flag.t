use strict;
use warnings;
use utf8;

use HTML::Trim;
use Test::More;

plan tests => 3;

ok utf8::is_utf8(HTML::Trim::trim('あああ', 5, '...')), 'should return utf8';
ok !utf8::is_utf8(HTML::Trim::trim('aaaaa', 5, '...')), 'unflagged';
ok utf8::is_utf8(HTML::Trim::trim('aaaaaa', 5, '…')), 'concated utf8 flagged delimiter';


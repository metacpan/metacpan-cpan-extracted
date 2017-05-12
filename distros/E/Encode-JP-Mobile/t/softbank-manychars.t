use strict;
use warnings;
use Test::More tests => 3;
use Encode::JP::Mobile;
use Encode;

# 絵文字のページがかわるごとにエスケープシーケンスによるページきりかえを発生させないといけない。

test_it( "\x{E001}",         qq{\x1B\x24G!\x0F},  'single char' );
test_it( "\x{E001}\x{E002}", qq{\x1B\x24G!"\x0F}, 'pair char in same page' );
test_it(
    "\x{E04A}\x{E20E}\x{E143}",
    ( "\x1B\x24Gj\x0F" . "\x1B\x24F.\x0F" . "\x1B\x24Ec\x0F" ),
    "three characters with different page"
);

sub test_it {
    my ($uni, $sjis, $name) = @_;
    is encode("x-sjis-softbank", $uni), $sjis, $name;
}

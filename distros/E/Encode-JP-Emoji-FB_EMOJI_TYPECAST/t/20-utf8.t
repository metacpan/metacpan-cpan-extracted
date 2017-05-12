use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;
use Encode;
use Encode::JP::Emoji;
use Encode::JP::Emoji::FB_EMOJI_TYPECAST;

plan tests => 14;

my $text;

$text = encode 'x-utf8-e4u-none-pp' => "\x{E63E}", FB_EMOJI_TYPECAST();
like $text, qr[sun.gif], 'sun docomo';
$text = encode 'x-utf8-e4u-none-pp' => "\x{EF60}", FB_EMOJI_TYPECAST();
like $text, qr[sun.gif], 'sun kddiweb';
$text = encode 'x-utf8-e4u-none-pp' => "\x{E04A}", FB_EMOJI_TYPECAST();
like $text, qr[sun.gif], 'sun softbank3g';
$text = encode 'x-utf8-e4u-none-pp' => "\x{2600}", FB_EMOJI_TYPECAST();
like $text, qr[sun.gif], 'sun unicode';

$text = encode 'x-utf8-e4u-none-pp' => "\x{E6FC}", FB_EMOJI_TYPECAST();
like $text, qr[annoy.gif], 'annoy docomo';
$text = encode 'x-utf8-e4u-none-pp' => "\x{EFBE}", FB_EMOJI_TYPECAST();
like $text, qr[annoy.gif], 'annoy kddiweb';
$text = encode 'x-utf8-e4u-none-pp' => "\x{E334}", FB_EMOJI_TYPECAST();
like $text, qr[annoy.gif], 'annoy softbank3g';

$text = encode 'x-utf8-e4u-none-pp' => "\x{E6B7}", FB_EMOJI_TYPECAST();
like $text, qr[soon.gif], 'soon docomo';
$text = encode 'x-utf8-e4u-none-pp' => "\x{FE018}", FB_EMOJI_TYPECAST();
like $text, qr[soon.gif], 'soon google';

$text = encode 'x-utf8-e4u-none-pp' => "\x{E71F}", FB_EMOJI_TYPECAST();
like $text, qr[watch.gif], 'watch docomo';
$text = encode 'x-utf8-e4u-none-pp' => "\x{FE01D}", FB_EMOJI_TYPECAST();
like $text, qr[watch.gif], 'watch google';
$text = encode 'x-utf8-e4u-none-pp' => "\x{231A}", FB_EMOJI_TYPECAST();
like $text, qr[watch.gif], 'watch unicode';

$text = encode 'x-utf8-e4u-none-pp' => "\x{E15A}", FB_EMOJI_TYPECAST();
like $text, qr[car.gif], 'car softbank3g';
$text = encode 'x-utf8-e4u-none-pp' => "\x{FE7EF}", FB_EMOJI_TYPECAST();
like $text, qr[car.gif], 'car google';

use strict;
use warnings;
use lib 't';
use Test::More;
use EncodeUpdate;
use Encode;
use Encode::JP::Emoji;
use Encode::JP::Emoji::FB_EMOJI_GMAIL;

plan tests => 14;

my $text;

$text = encode 'x-utf8-e4u-none-pp' => "\x{E63E}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/docomo_ne_jp/000], 'SUN docomo';
$text = encode 'x-utf8-e4u-none-pp' => "\x{EF60}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/ezweb_ne_jp/000], 'SUN kddiweb';
$text = encode 'x-utf8-e4u-none-pp' => "\x{E04A}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/softbank_ne_jp/000], 'SUN softbank3g';
$text = encode 'x-utf8-e4u-none-pp' => "\x{2600}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/000], 'SUN unicode';

$text = encode 'x-utf8-e4u-none-pp' => "\x{E6FC}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/docomo_ne_jp/B57], 'ANGER docomo';
$text = encode 'x-utf8-e4u-none-pp' => "\x{EFBE}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/ezweb_ne_jp/B57], 'ANGER kddiweb';
$text = encode 'x-utf8-e4u-none-pp' => "\x{E334}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/softbank_ne_jp/B57], 'ANGER softbank3g';

$text = encode 'x-utf8-e4u-none-pp' => "\x{E6B7}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/docomo_ne_jp/018], 'SOON docomo';
$text = encode 'x-utf8-e4u-none-pp' => "\x{FE018}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/018], 'SOON google';

$text = encode 'x-utf8-e4u-none-pp' => "\x{EF62}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/ezweb_ne_jp/00E], 'SNOWFLAKE kddiweb';
$text = encode 'x-utf8-e4u-none-pp' => "\x{FE00E}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/00E], 'SNOWFLAKE google';
$text = encode 'x-utf8-e4u-none-pp' => "\x{2744}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/00E], 'SNOWFLAKE unicode';

$text = encode 'x-utf8-e4u-none-pp' => "\x{E15A}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/softbank_ne_jp/7EF], 'TAXI softbank3g';
$text = encode 'x-utf8-e4u-none-pp' => "\x{FE7EF}", FB_EMOJI_GMAIL();
like $text, qr[/mail/e/7EF], 'TAXI google';

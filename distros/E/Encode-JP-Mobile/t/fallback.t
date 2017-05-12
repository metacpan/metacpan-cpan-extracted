use strict;
use warnings;
use Test::More tests => 8;
use Encode;
use Encode::JP::Mobile;

my $kao_utf8byte = "(>３<)";
my $kao_utf8char = decode('utf-8', $kao_utf8byte);
my $kao_sjisbyte = encode('shift_jis', $kao_utf8char);

is encode('x-utf8-docomo', "\x{ECA2}", Encode::JP::Mobile::FB_CHARACTER), $kao_utf8byte, 'utf8 fallback';

is encode('x-utf8-docomo', "\x{ECA2}\x{2668}", Encode::JP::Mobile::FB_CHARACTER), $kao_utf8byte.'?', 'out of cp932';

my $check = Encode::JP::Mobile::FB_CHARACTER;
my $encoding = find_encoding('x-utf8-docomo');
is $encoding->encode("\x{ECA2}", $check), $kao_utf8byte, 'utf8 $encoding->encode()';

   $encoding = find_encoding('x-sjis-docomo');
is $encoding->encode("\x{ECA2}", $check), $kao_sjisbyte, 'sjis $encoding->encode()';

is encode('x-sjis-docomo', "\x{ECA2}\x{2668}", Encode::JP::Mobile::FB_CHARACTER), 
   $kao_sjisbyte.'?', 'sjis fallback';

is encode('x-sjis-docomo', "\x{ECA2}\x{2668}", Encode::JP::Mobile::FB_CHARACTER(Encode::FB_XMLCREF) ), 
   $kao_sjisbyte.'&#x2668;', 'callback with Encode::FB_XMLCREF';

is encode('x-sjis-docomo', "\x{ECA2}\x{2668}", Encode::JP::Mobile::FB_CHARACTER(sub { "[x]" }) ), 
   $kao_sjisbyte.'[x]', 'callback with callback';

$check = Encode::JP::Mobile::FB_CHARACTER(sub {
    sprintf '<U+%04X>', shift;  
});
is encode('x-sjis-docomo', "\x{ECA2}\x{2668}", $check), 
   $kao_sjisbyte.'<U+2668>', 'callback with callback 2';

#!/usr/bin/perl -w
# $File: //member/autrijus/Encode-compat/t/1-basic.t $ $Author: autrijus $
# $Revision: #4 $ $Change: 10024 $ $DateTime: 2004/02/13 21:42:35 $

use strict;
use Test;

BEGIN { plan tests => 12 }

ok(eval { use Encode::compat; 1 });

use Encode qw(encode decode from_to is_utf8 FB_HTMLCREF);

my $text = '°®©[';

ok(!is_utf8($text));
ok(length(decode(big5 => $text)), 2);
ok(is_utf8(decode(big5 => $text)));
ok(!is_utf8(encode(big5 => decode(big5 => $text))));
ok(!is_utf8(encode(utf8 => decode(big5 => $text))));

from_to($text, 'big5eten' => 'utf8');
ok(!is_utf8($text));
ok(length($text), 6);

from_to($text, 'utf-8' => 'latin1', FB_HTMLCREF);
ok(!is_utf8($text));
ok($text, '&#20094;&#22372;');

$text = 'test1';
ok(decode('utf8', $text, 256), 'test1');
$text = 'test2';
ok(encode('utf8', $text, 256), 'test2');

__END__

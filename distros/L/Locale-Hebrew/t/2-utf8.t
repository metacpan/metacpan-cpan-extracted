# $File: //member/autrijus/Locale-Hebrew/t/2-utf8.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 11166 $ $DateTime: 2004/09/17 21:16:27 $

use Test;
BEGIN { plan tests => 1 };
BEGIN { if ($] < 5.008001) { skip(1); exit } }

use utf8;
use Locale::Hebrew;

ok(hebrewflip('ך"הדף של התנ'), scalar reverse 'ך"הדף של התנ');

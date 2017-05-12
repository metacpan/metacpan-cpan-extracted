# $File: //member/autrijus/Locale-Hebrew/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 11166 $ $DateTime: 2004/09/17 21:16:27 $

use Test;
BEGIN { plan tests => 3 };

use Locale::Hebrew;

ok(Locale::Hebrew->VERSION);
ok(defined(&hebrewflip));
ok(hebrewflip('ך"הדף של התנ'), scalar reverse 'ך"הדף של התנ');

use strict; use warnings;
use Test::More tests => 31;
use Lingua::IND::Numbers;

my $convert = Lingua::IND::Numbers->new;

while (<DATA>) {
    chomp;
    my ($number, $string) = split /\|/;
    is($convert->to_string($number), $string);
}

__DATA__
0|Shunya
100|Ek Sau
190|Ek Sau Nabbe
1000|Ek Hazaar
1101|Ek Hazaar Ek Sau Ek
1110|Ek Hazaar Ek Sau Das
1100|Ek Hazaar Ek Sau
10000|Das Hazaar
10001|Das Hazaar Ek
10101|Das Hazaar Ek Sau Ek
11001|Egyarah Hazaar Ek
12345|Barah Hazaar Teen Sau Paitalees
100000|Ek Lakh
100001|Ek Lakh Ek
105000|Ek Lakh Paanch Hazaar
1000000|Das Lakh
1100000|Egyarah Lakh
1020000|Das Lakh Bees Hazaar
9999999|Neenaanwe Lakh Neenaanwe Hazaar Nau Sau Neenaanwe
19999999|Ek Crore Neenaanwe Lakh Neenaanwe Hazaar Nau Sau Neenaanwe
110000000|Egyarah Crore
110000001|Egyarah Crore Ek
2000000000|Do Arab
12000000000|Barah Arab
212000000000|Do Kharab Barah Arab
1612000000000|Solah Kharab Barah Arab
91612000000000|Nau Neel Solah Kharab Barah Arab
191612000000000|Unnees Neel Solah Kharab Barah Arab
2191612000000000|Do Padm Unnees Neel Solah Kharab Barah Arab
12191612000000000|Barah Padm Unnees Neel Solah Kharab Barah Arab
412191612000000000|Chaar Shankh Barah Padm Unnees Neel Solah Kharab Barah Arab
use strict;
use Test::More;
use Google::UULE::Generator qw/generate_uule/;

is(generate_uule("Lezigne,Pays de la Loire,France"), "w+CAIQICIfTGV6aWduZSxQYXlzIGRlIGxhIExvaXJlLEZyYW5jZQ");
is(generate_uule("Reze,Pays de la Loire,France"), "w+CAIQICIcUmV6ZSxQYXlzIGRlIGxhIExvaXJlLEZyYW5jZQ");
is(generate_uule("West New York,New Jersey,United States"), "w+CAIQICImV2VzdCBOZXcgWW9yayxOZXcgSmVyc2V5LFVuaXRlZCBTdGF0ZXM");

done_testing;

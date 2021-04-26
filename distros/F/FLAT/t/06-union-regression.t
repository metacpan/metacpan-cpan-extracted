use strict;
use warnings;
use Test::More tests => 1;
use FLAT;
use FLAT::Regex;

# https://rt.cpan.org/Ticket/Display.html?id=115605&results=c1712880dc93375c9da670f5659df168

my $f1 = FLAT::Regex->new('a*');
my $f2 = FLAT::Regex->new('b*');
my $f3 = $f1->union($f2);
isa_ok($f3, q{FLAT::Regex});

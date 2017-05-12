#!perl 
use Test::More tests => 7;
use Font::TTF::OpenTypeLigatures;
my $x = Font::TTF::OpenTypeLigatures->new("t/Padauk.ttf", 
    script => "mymr", features => ".*");
my $y = Font::TTF::OpenTypeLigatures->new("t/Padauk.ttf", 
    script => "mymr", features => ".*");
isa_ok($x, "Font::TTF::OpenTypeLigatures");
is($x, $y, "Memoizing works");
is(join(",", $x->substitute(225,150,244)), "152", "Long substitution");
is(join(",", $x->substitute(225,150,100)), "151,100", "Non-final sub");
is(join(",", $x->substitute(225,140,100)), "141,100", "Final sub");
is(join(",", $x->substitute(225,225,140,100)), "225,141,100", "Non-initial sub");
is(join(",", $x->substitute(225,100)), "225,100", "Non-sub");

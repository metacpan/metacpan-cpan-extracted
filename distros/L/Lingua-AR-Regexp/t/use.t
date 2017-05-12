use Test::More;
use utf8;
use charnames ':full';
BEGIN {
    use_ok 'Lingua::AR::Regexp';
}

like $_, qr/^\p{Lingua::AR::Regexp::IsSplitting}$/ for qw(د ذ ر ز و ؤ آ أ إ ا);
like $_, qr/^\P{Lingua::AR::Regexp::IsSplitting}$/ for qw/ب/;
like $_, qr/^\p{Lingua::AR::Regexp::IsHamza}$/ for (
    "\N{ARABIC HAMZA ABOVE}",
    "\N{ARABIC MADDAH ABOVE}",
    "\N{ARABIC HAMZA BELOW}");
unlike $_, qr/\p{Lingua::AR::Regexp::IsHamza}/ for qw/ب/;
done_testing;

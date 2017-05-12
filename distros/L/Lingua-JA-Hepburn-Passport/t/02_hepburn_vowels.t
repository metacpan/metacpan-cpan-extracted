use strict;
use Test::Base;

use Encode;
use Lingua::JA::Hepburn::Passport;

sub hepburn {
    Lingua::JA::Hepburn::Passport->new( long_vowels_h => 1 )->romanize( decode_utf8($_[0]) );
}

filters {
    input => [ 'chomp', 'hepburn' ],
    expected => [ 'chomp' ],
};

run_is 'input' => 'expected';

__END__

===
--- input
ほっち
--- expected
HOTCHI

===
--- input
はっちょう
--- expected
HATCHOH

===
--- input
こうの
--- expected
KOHNO

===
--- input
おおの
--- expected
OHNO

===
--- input
ひゅうが
--- expected
HYUGA

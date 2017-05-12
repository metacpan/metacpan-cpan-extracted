use strict;
use Test::Base;

use Encode;
use Lingua::JA::Hepburn::Passport;

sub hepburn {
    Lingua::JA::Hepburn::Passport->new->romanize( decode_utf8($_[0]) );
}

filters {
    input => [ 'chomp', 'hepburn' ],
    expected => [ 'chomp' ],
};

run_is 'input' => 'expected';

__END__

===
--- input
なんば
--- expected
NAMBA

===
--- input
ほんま
--- expected
HOMMA

===
--- input
さんぺい
--- expected
SAMPEI

===
--- input
はっとり
--- expected
HATTORI

===
--- input
きっかわ
--- expected
KIKKAWA

===
--- input
ほっち
--- expected
HOTCHI

===
--- input
はっちょう
--- expected
HATCHO

===
--- input
こうの
--- expected
KONO

===
--- input
おおの
--- expected
ONO

===
--- input
ひゅうが
--- expected
HYUGA

===
--- input
ちゅうま
--- expected
CHUMA

===
--- input
おーの
--- expected
ONO

=== Katakana
--- input
チュウマ
--- expected
CHUMA

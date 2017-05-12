use strict;
use warnings;

use Test::More tests => 80;
use Lingua::Han::CanonicalPinYin 'canonicalize_pinyin';
use Encode;
use utf8;
my %map = (
    a  => [ 'hao', 'sa', 'sang' ],
    o  => [ 'hou', 'wo', 'wong' ],
    e  => [ 'de',  'hen' ],
    i  => [ 'ji',  'ying' ],
    iu => [ 'liu', 'qiu' ],
    u  => [ 'ju',  'gun' ],
    v  => [ 'lv' ],
    ü  => [ 'lü' ],
    ie  => [ 'jie', 'lie' ],
    uo  => [ 'guo', 'huo' ],
);

my @tones = ( undef, "\x{304}", "\x{301}", "\x{30c}", "\x{300}" );
for my $vowel ( keys %map ) {
    for my $pinyin ( @{ $map{$vowel} } ) {
        for my $tone ( 1 .. 4 ) {
            my $new = $pinyin;
            my $pinyin = $new . $tone;
            if ( $vowel eq 'v' ) {
                $new =~ s/v/u\x{308}$tones[$tone]/;
            }
            else {
                $new =~ s/$vowel/$vowel$tones[$tone]/;
            }
            is( canonicalize_pinyin($pinyin), $new, encode_utf8 $new );
        }
    }
}


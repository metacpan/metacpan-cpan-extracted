#!/usr/local/bin/perl
use v5.36.1;
use strict;
use warnings;
use lib './t';
use vars qw( $expected );
use Test::More;
use Locale::Unicode::Data;

require( "gettext-lib.pl" );

my $cldr = Locale::Unicode::Data->new;

# Locales to test
my @locales = qw(
    af ak am an ar ars as asa ast az bal be bem bez bg bho blo bm bn bo br brx bs ca ce ceb cgg chr ckb cs csw cy da de doi dsb dv dz ee el en eo es et eu fa ff fi fil fo fr fur fy ga gd gl gsw gu guw gv ha haw he hi hnj hr hsb hu hy ia id ig ii in io is it iu iw ja jbo jgo ji jmc jv jw ka kab kaj kcg kde kea kk kkj kl km kn ko ks ksb ksh ku kw ky lag lb lg lij lkt lld ln lo lt lv mas mg mgo mk ml mn mo mr ms mt my nah naq nb nd ne nl nn nnh no nqo nr nso ny nyn om or os osa pa pap pcm pl prg ps pt pt-PT rm ro rof ru rwk sah saq sat sc scn sd sdh se seh ses sg sh shi si sk sl sma smi smj smn sms sn so sq sr ss ssy st su sv sw syr ta te teo th ti tig tk tl tn to tpi tr ts tzm ug uk und ur uz ve vec vi vo vun wa wae wo xh xog yi yo yue zh zu
);

for my $locale ( sort( @locales ) )
{
    my $rule = $cldr->plural_forms( $locale );
    is( $rule => $expected->{ $locale }, "Plural form matches expected for $locale" );
    if( !defined( $rule ) )
    {
        diag( "Error getting the plural forms for locale $locale: ", $cldr->error );
    }
}

done_testing();

__END__

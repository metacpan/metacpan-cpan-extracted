use strict;
use Test::Base;
use utf8;
plan tests => 1 * blocks;

use Lingua::AIN::Romanize qw(:setregex);

SKIP:{
    eval "use Regexp::Assemble";
    skip "Regexp::Assemble is not installed", 1 * blocks if($@);

    $Ain_Roman2Kana{ca}  = 'キャ';
    $Ain_Kana2Roman{'ｸ'} = 'j';
    push( @Ain_VplusiuCase, "\\bburay'aikau" );

    ain_setregex();

    run {
        my $block = shift;
        my ($input)   = split(/\n/,$block->input);
        my ($output)  = split(/\n/,$block->expected);

        if ( $input =~ /^[a-z'\s]+$/ ) { 
            is ain_roman2kana($input), $output;
        } else {
            is ain_kana2roman($input), $output;
        }
    };
}

__END__
===
--- input
catak

--- expected
キャタㇰ

===
--- input
イタｸ

--- expected
itaj

===
--- input
イイヤイライケレ

--- expected
iiyayraykere

===
--- input
イヤイライケレレ

--- expected
iyayraykerere

===
--- input
ブライアイカウ

--- expected
buray'aikau

===
--- input
ブライアイカウサ

--- expected
buray'aikausa

===
--- input
サブライアイカウ

--- expected
saburay'aykaw

use strict;
use Test::More tests => 2;

use Lingua::JA::Regular;


    my $geta = Lingua::JA::Regular->new("\xAD\xA1\x17\xAC\xAD\xA1")->geta->to_s;
    ok $geta eq "\xA2\xAE\xA2\xAE\xA2\xAE", 'geta1';

    #
    # 未定義文字と定義されていない文字が2文字以上続くと1文字と見なされる。
    #
    my $geta2 = Lingua::JA::Regular->new("\xAD\xA1\x17\xAC\x17\xAC\xAD\xA1")->geta->to_s;
    ok $geta2 eq "\xA2\xAE\xA2\xAE\xA2\xAE", 'geta2';

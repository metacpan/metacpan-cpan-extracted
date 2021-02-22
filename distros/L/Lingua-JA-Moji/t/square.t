use FindBin '$Bin';
use lib "$Bin";
use LJMT;is (square2katakana ('㌆'), 'ウォン', "square2katakana test"); 
is (katakana2square ('アイウエオウォン'), 'アイウエオ㌆', "katakana2square test");
done_testing ();


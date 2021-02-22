use FindBin '$Bin';
use lib "$Bin";
use LJMT;

ok ('ｱ' =~ /\p{InHankakuKatakana}/, "ｱ is half-width katakana\n");
ok ('ア' !~ /\p{InHankakuKatakana}/, "ア　is not half-width katakana\n");
ok ('baby chops' !~ /\p{InHankakuKatakana}/, "baby chops is not half-width katakana\n");

done_testing ();

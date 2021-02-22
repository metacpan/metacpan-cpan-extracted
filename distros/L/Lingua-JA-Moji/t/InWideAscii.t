use FindBin '$Bin';
use lib "$Bin";
use LJMT;

ok ('ｱ' !~ /\p{InWideAscii}/, "ｱ is wide ascii\n");
ok ('ア' !~ /\p{InWideAscii}/, "ア　is not wide ascii\n");
ok ('baby chops' !~ /\p{InWideAscii}/, "baby chops is not wide ascii\n");
ok ('ｂａｂｙ　ｃｈｏｐｓ' =~ /\p{InWideAscii}/, "ｂａｂｙ　ｃｈｏｐｓ is wide ascii\n");

done_testing ();

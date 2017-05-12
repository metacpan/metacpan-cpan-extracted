use Test;
BEGIN { plan tests => 2 };
ok(1);

use Lingua::ZH::ZhuYinWen qw(bastardize);

ok(
   bastardize(
	      '俗說天地開闢，未有人民，女媧摶黃土作人，劇務力不暇供，乃引繩於泥中，舉以為人'),
   'ㄙㄕㄊㄉㄎㄆ，ㄨㄧㄖㄇ，ㄋㄨㄊㄏㄊㄗㄖ，ㄐㄨㄌㄅㄒㄍ，ㄋㄧㄕㄩㄋㄓ，ㄐㄧㄨㄖ'
   );



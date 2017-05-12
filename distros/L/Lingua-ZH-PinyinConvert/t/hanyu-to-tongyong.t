use Test;
BEGIN { plan tests => 2 };
ok(1);

$tongyong = <<YIJING;
cian, kun, tun, meng, syu, song, shih, bi,
siao chu, lu, tai, pi, tong ren, da you, cian, yu
suei, gu, lin, guan, shih ke, ben, bo, fu
wu wang, da chu, yi, da guo, kan, li, sian, heng
tun, da jhuang, jin, ming yi, jia ren, kuei, jian, jie
sun, yi, guai, hou, cuei, sheng, kun, jing, ge
ding, jhen, gen, jian, guei mei, fong, lu
syun, duei, huan, jie, jhong fu, siao guo, ji ji, wei ji
YIJING

$hanyu = <<YIJING;
qian, kun, tun, meng, xu, song, shi, bi,
xiao chu, lU, tai, pi, tong ren, da you, qian, yu
sui, gu, lin, guan, shi ke, ben, bo, fu
wu wang, da chu, yi, da guo, kan, li, xian, heng
tun, da zhuang, jin, ming yi, jia ren, kui, jian, jie
sun, yi, guai, hou, cui, sheng, kun, jing, ge
ding, zhen, gen, jian, gui mei, feng, lU
xun, dui, huan, jie, zhong fu, xiao guo, ji ji, wei ji
YIJING


use PerlIO::via::PinyinConvert from => "hanyu", to => "tongyong";
open( my $out,'>:via(PinyinConvert)', 'test.txt' );
print $out $hanyu;
close $out;

ok( `cat test.txt`, $tongyong );



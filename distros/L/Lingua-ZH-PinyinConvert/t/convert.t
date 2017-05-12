use Test;
BEGIN { plan tests => 3 };
use Lingua::ZH::PinyinConvert qw/convert/;
ok(1);

ok( convert ('tongyong', 'hanyu', <<DAODEJING)
dao ke dao fei chang dao
ming ke ming fei chang ming
wu, ming tian sia jhih shih
you, ming wan wu jhih mu
gu, chang wu, yu yi guan ci miao
chang you, yu yi guan ci jiao
cih liang jhih, tong chu er yi ming tong wei jhih syuan
syuan jhih you syuan jhong miao jhih men
DAODEJING
,
<<DAODEJING
dao ke dao fei chang dao
ming ke ming fei chang ming
wu, ming tian xia zhi shi
you, ming wan wu zhi mu
gu, chang wu, yu yi guan qi miao
chang you, yu yi guan qi jiao
ci liang zhi, tong chu er yi ming tong wei zhi xuan
xuan zhi you xuan zhong miao zhi men
DAODEJING
);

ok( convert ('hanyu', 'tongyong', <<YIJING)
qian, kun, tun, meng, xu, song, shi, bi,
xiao chu, lU, tai, pi, tong ren, da you, qian, yu
sui, gu, lin, guan, shi ke, ben, bo, fu
wu wang, da chu, yi, da guo, kan, li, xian, heng
tun, da zhuang, jin, ming yi, jia ren, kui, jian, jie
sun, yi, guai, hou, cui, sheng, kun, jing, ge
ding, zhen, gen, jian, gui mei, feng, lU
xun, dui, huan, jie, zhong fu, xiao guo, ji ji, wei ji
YIJING
,
<<YIJING
cian, kun, tun, meng, syu, song, shih, bi,
siao chu, lu, tai, pi, tong ren, da you, cian, yu
suei, gu, lin, guan, shih ke, ben, bo, fu
wu wang, da chu, yi, da guo, kan, li, sian, heng
tun, da jhuang, jin, ming yi, jia ren, kuei, jian, jie
sun, yi, guai, hou, cuei, sheng, kun, jing, ge
ding, jhen, gen, jian, guei mei, fong, lu
syun, duei, huan, jie, jhong fu, siao guo, ji ji, wei ji
YIJING
    );

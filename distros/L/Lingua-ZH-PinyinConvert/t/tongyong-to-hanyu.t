use Test;
BEGIN { plan tests => 2 };
ok(1);


$tongyong = <<DAODEJING;
dao ke dao fei chang dao
ming ke ming fei chang ming
wu, ming tian sia jhih shih
you, ming wan wu jhih mu
gu, chang wu, yu yi guan ci miao
chang you, yu yi guan ci jiao
cih liang jhih, tong chu er yi ming tong wei jhih syuan
syuan jhih you syuan jhong miao jhih men
DAODEJING

$hanyu = <<DAODEJING;
dao ke dao fei chang dao
ming ke ming fei chang ming
wu, ming tian xia zhi shi
you, ming wan wu zhi mu
gu, chang wu, yu yi guan qi miao
chang you, yu yi guan qi jiao
ci liang zhi, tong chu er yi ming tong wei zhi xuan
xuan zhi you xuan zhong miao zhi men
DAODEJING

use PerlIO::via::PinyinConvert from => "tongyong", to => "hanyu";
open( my $out,'>:via(PinyinConvert)', 'test.txt' );
print $out $tongyong;
close $out;

ok( `cat test.txt`, $hanyu );

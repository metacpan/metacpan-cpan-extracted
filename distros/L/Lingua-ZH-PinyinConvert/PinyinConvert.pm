package Lingua::ZH::PinyinConvert;

use 5.006;
use strict;
use Carp;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/convert/;
our $VERSION = '0.05';

my @PS = ( # pinyin systems
       [ qw/a a a a a/],
       [ qw/ai ai ai ai ai/],
       [ qw/an an an an an/],
       [ qw/ang ang ang ang ang/],
       [ qw/ao au ao au ao/],
       [ qw/pa ba ba ba ba/],
       [ qw/pai bai bai bai bai/],
       [ qw/pan ban ban ban ban/],
       [ qw/pang bang bang bang bang/],
       [ qw/pao bau bao bau bao/],
       [ qw/pei bei bei bei bei/],
       [ qw/pen ban ben ben ben/],
       [ qw/peng beng beng beng beng/],
       [ qw/pi bi bi bi bi/],
       [ qw/pien bian bian byan bian/],
       [ qw/piao biau biao byau biao/],
       [ qw/pieh bie bie bye bie/],
       [ qw/pin bin bin bin bin/],
       [ qw/ping bing bing bing bing/],
       [ qw/po bo bo bwo bo/],
       [ qw/pu bu bu bu bu/],
       [ qw/ts'a tsa ca tsa ca/],
[ qw/ts'ai tsai cai tsai cai/],
[ qw/ts'an tsan can tsan can/],
[ qw/ts'ang tsang cang tsang cang/],
[ qw/ts'ao tsau cao tsau cao/],
[ qw/ts'e tse ce tse ce/],
[ qw/ts'en tsen cen tsen cen/],
[ qw/ts'eng tseng ceng tseng ceng/],
[ qw/ch'a cha cha cha cha/],
[ qw/ch'ai chai chai chai chai/],
[ qw/ch'an chan chan chan chan/],
[ qw/ch'ang chang chang chang chang/],
[ qw/ch'ao chau chao chau chao/],
[ qw/ch'e che che che che/],
[ qw/ch'en chen chen chen chen/],
[ qw/ch'eng cheng cheng cheng cheng/],
[ qw/ch'ih chr chi chr chih/],
[ qw/ch'ung chung chong chung chong/],
[ qw/ch'ou chou chou chou chou/],
[ qw/ch'u chu chu chu chu/],
[ qw/chua chua chua chwa chua/],
    [ qw/ch'uai chuai chuai chwai chuai/],
[ qw/ch'uan chuan chuan chwan chuan/],
[ qw/ch'uang chuang chuang chwang chuang/],
[ qw/ch'ui chuei chui chwei chuei/],
[ qw/ch'un chuen chun chwun chun/],
[ qw/ch'o chuo chuo chwo chuo/],
[ qw/tz'u tsz ci tsz cih/],
[ qw/ts'ung tsung cong tsung cong/],
[ qw/ts'ou tsou cou tsou cou/],
[ qw/ts'u tsu cu tsu cu/],
[ qw/ts'uan tsuan cuan tswan cuan/],
[ qw/ts'ui tsuei cui tswei cuei/],
[ qw/ts'un tsuen cun tswun cun/],
[ qw/ts'o tsuo cuo tswo cuo/],
[ qw/ta da da da da/],
    [ qw/tai dai dai dai dai/],
    [ qw/tan dan dan dan dan/],
    [ qw/tang dang dang dang dang/],
    [ qw/tao dau dao dau dao/],
    [ qw/te de de de de/],
    [ qw/tei dei dei dei dei/],
    [ qw/ten den den den den/],
    [ qw/teng deng deng deng deng/],
    [ qw/ti di di di di/],
    [ qw/tien dian dian dyan dian/],
    [ qw/tiang diang diang dyang diang/],
    [ qw/tiao diau diao dyau diao/],
    [ qw/tieh die die dye die/],
    [ qw/ting ding ding ding ding/],
    [ qw/tiu diou diu dyou diou/],
    [ qw/tung dung dong dung dong/],
    [ qw/tou dou dou dou dou/],
    [ qw/tu du du du du/],
    [ qw/tuan duan duan dwan duan/],
    [ qw/tui duei dui dwei duei/],
    [ qw/tun duen dun dwun dun/],
    [ qw/to duo duo dwo duo/],
    [ qw/e e e e e/],
    [ qw/ei ei ei ei ei/],
    [ qw/en en en en en/],
    [ qw/erh er er er er/],
    [ qw/fa fa fa fa fa/],
    [ qw/fan fan fan fan fan/],
    [ qw/fang fang fang fang fang/],
    [ qw/fei fei fei fei fei/],
    [ qw/fen fen fen fen fen/],
    [ qw/feng feng feng feng fong/],
    [ qw/fo fo fo fwo fo/],
    [ qw/fou fou fou fou fou/],
    [ qw/fu fu fu fu fu/],
    [ qw/ka ga ga ga ga/],
    [ qw/kai gai gai gai gai/],
    [ qw/kan gan gan gan gan/],
    [ qw/kang gang gang gang gang/],
    [ qw/kao gau gao gau gao/],
    [ qw/ke ge ge ge ge/],
    [ qw/kei gei gei gei gei/],
    [ qw/ken gen gen gen gen/],
    [ qw/keng geng geng geng geng/],
    [ qw/kung gung gong gung gong/],
    [ qw/kou gou gou gou gou/],
    [ qw/ku gu gu gu gu/],
    [ qw/kua gua gua gwa gua/],
    [ qw/kuai guai guai gwai guai/],
    [ qw/kuan guan guan gwan guan/],
    [ qw/kuang guang guang gwang guang/],
    [ qw/kuei guei gui gwei guei/],
    [ qw/kun guen gun gwun gun/],
    [ qw/kuo guo guo gwo guo/],
    [ qw/ha ha ha ha ha/],
    [ qw/hai hai hai hai hai/],
    [ qw/han han han han han/],
    [ qw/hang hang hang hang hang/],
    [ qw/hao hau hao hau hao/],
    [ qw/he he he he he/],
    [ qw/hei hei hei hei hei/],
    [ qw/hen hen hen hen hen/],
    [ qw/heng heng heng heng heng/],
    [ qw/hung hung hong hung hong/],
    [ qw/hou hou hou hou hou/],
    [ qw/hu hu hu hu hu/],
    [ qw/hua hua hua hwa hua/],
    [ qw/huai huai huai hwai huai/],
    [ qw/huan huan huan hwan huan/],
    [ qw/huang huang huang hwang huang/],
    [ qw/hui huei hui hwei huei/],
    [ qw/hun huen hun hwun hun/],
    [ qw/huo huo huo hwo huo/],
    [ qw/chi ji ji ji ji/],
    [ qw/chia jia jia jya jia/],
    [ qw/chien jian jian jyan jian/],
    [ qw/chiang jiang jiang jyang jiang/],
    [ qw/chiao jiau jiao jyau jiao/],
    [ qw/chieh jie jie jye jie/],
    [ qw/chin jin jin jin jin/],
    [ qw/ching jing jing jing jing/],
    [ qw/chiung jiung jiong jyung jyong/],
    [ qw/chiu jiou jiu jyou jiou/],
    [ qw/chu: jiu ju jyu jyu/],
    [ qw/chuan: jiuan juan jywan juan/],
    [ qw/chueh: jiue jue jywe jue/],
    [ qw/chun: jiun jun jyun jun/],
    [ qw/k'a ka ka ka ka/],
[ qw/k'ai kai kai kai kai/],
[ qw/k'an kan kan kan kan/],
[ qw/k'ang kang kang kang kang/],
[ qw/k'ao kau kao kau kao/],
[ qw/k'e ke ke ke ke/],
[ qw/k'en ken ken ken ken/],
[ qw/k'eng keng keng keng keng/],
[ qw/k'ung kung kong kung kong/],
[ qw/k'ou kou kou kou kou/],
[ qw/k'u ku ku ku ku/],
[ qw/k'ua kua kua kwa kua/],
[ qw/k'uai kuai kuai kwai kuai/],
[ qw/k'uan kuan kuan kwan kuan/],
[ qw/k'uang kuang kuang kwang kuang/],
[ qw/k'uei kuei kui kwei kuei/],
[ qw/k'un kuen kun kwun kun/],
[ qw/k'uo kuo kuo kwo kuo/],
[ qw/la la la la la/],
    [ qw/lai lai lai lai lai/],
    [ qw/lan lan lan lan lan/],
    [ qw/lang lang lang lang lang/],
    [ qw/lao lau lao lau lao/],
    [ qw/le le le le le/],
    [ qw/lei lei lei lei lei/],
    [ qw/leng leng leng leng leng/],
    [ qw/li li li li li/],
    [ qw/lia lia lia lya lia/],
    [ qw/lien lian lian lyan lian/],
    [ qw/liang liang liang lyang liang/],
    [ qw/liao liao liao lyau liao/],
    [ qw/lieh lie lie lye lie/],
    [ qw/lin lin lin lin lin/],
    [ qw/ling ling ling ling ling/],
    [ qw/liu liou liu lyou liou/],
    [ qw/lo lo lo lo lo/],
    [ qw/lung lung long lung long/],
    [ qw/lou lou lou lou lou/],
    [ qw/lu lu lu lu lu/],
    [ qw/lu: liu lu lyu lyu/],
    [ qw/luan luan luan lwan luan/],
    [ qw/luan: liuan luan lywan lyuan/],
    [ qw/lueh: lieu lue lywe lyue/],
    [ qw/lun luen lun lwun lun/],
    [ qw/lun: liun lun lyun lyuen/],
    [ qw/luo luo luo lwo luo/],
    [ qw/ma ma ma ma ma/],
    [ qw/mai mai mai mai mai/],
    [ qw/man man man man man/],
    [ qw/mang mang mang mang mang/],
    [ qw/mao mau mao mau mao/],
    [ qw/me me me me me/],
    [ qw/mei mei mei mei mei/],
    [ qw/men men men men men/],
    [ qw/meng meng meng meng meng/],
    [ qw/mi mi mi mi mi/],
    [ qw/mien mian mian myan mian/],
    [ qw/miao miau miao myau miao/],
    [ qw/mieh mie mie mye mie/],
    [ qw/min min min min min/],
    [ qw/ming ming ming ming ming/],
    [ qw/miu miou miu myou miou/],
    [ qw/mo mo mo mwo mo/],
    [ qw/mou mou mou mou mou/],
    [ qw/mu mu mu mu mu/],
    [ qw/na na na na na/],
    [ qw/nai nai nai nai nai/],
    [ qw/nan nan nan nan nan/],
    [ qw/nang nang nang nang nang/],
    [ qw/nao nau nao nau nao/],
    [ qw/ne ne ne ne ne/],
    [ qw/nei nei nei nei nei/],
    [ qw/nen nen nen nen nen/],
    [ qw/neng neng neng neng neng/],
    [ qw/ni ni ni ni ni/],
    [ qw/nia nia nia nya nia/],
    [ qw/nien nian nian nyan nian/],
    [ qw/niang niang niang nyang niang/],
    [ qw/niao niau niao nyau niao/],
    [ qw/nieh nie nie nye nie/],
    [ qw/nin nin nin nin nin/],
    [ qw/ning ning ning ning ning/],
    [ qw/niu niou niu nyou niou/],
    [ qw/nung nung nong nung nong/],
    [ qw/nou nou nou nou nou/],
    [ qw/nu nu nu nu nu/],
    [ qw/nu: niu nu nyu nyu/],
    [ qw/nuan nuan nuan nwan nuan/],
    [ qw/nueh: niue nue nywe nyue/],
    [ qw/nuen nun nun nwen nun/],
    [ qw/no nuo nuo nwo nuo/],
    [ qw/ou ou ou ou ou/],
    [ qw/p'a pa pa pa pa/],
[ qw/p'ai pai pai pai pai/],
[ qw/p'an pan pan pan pan/],
[ qw/p'ang pang pang pang pang/],
[ qw/p'ao pau pao pau pao/],
[ qw/p'ei pei pei pei pei/],
[ qw/p'en pen pen pen pen/],
[ qw/p'eng peng peng peng peng/],
[ qw/p'i pi pi pi pi/],
[ qw/p'ien pian pian pyan pian/],
[ qw/p'iao piau piao pyau piao/],
[ qw/p'ieh pie pie pye pie/],
[ qw/p'in pin pin pin pin/],
[ qw/p'ing ping ping ping ping/],
[ qw/p'o po po pwo po/],
[ qw/p'ou pou pou pou pou/],
[ qw/p'u pu pu pu pu/],
[ qw/ch'i chi qi chi ci/],
[ qw/ch'ia chia qia chya cia/],
[ qw/ch'ien chian qian chyan cian/],
[ qw/ch'iang chiang qiang chyang ciang/],
[ qw/ch'iao chiau qiao chyau ciao/],
[ qw/ch'ieh chie qie chye cie/],
[ qw/ch'in chin qin chin cin/],
[ qw/ch'ing ching qing ching cing/],
[ qw/ch'iung chiung qiong chyung cyong/],
[ qw/ch'iu chiou qiu chyou ciou/],
[ qw/ch'u: chiu qu chyu cyu/],
[ qw/ch'uan: chiuan quan chywan cyuan/],
[ qw/ch'ueh: chiue que chywe cyue/],
[ qw/ch'un: chiun qun chyun cyun/],
[ qw/jan ran ran ran ran/],
    [ qw/jang rang rang rang rang/],
    [ qw/jao rau rao rau rao/],
    [ qw/je re re re re/],
    [ qw/jen ren ren ren ren/],
    [ qw/jeng reng reng reng reng/],
    [ qw/jih r ri r rih/],
    [ qw/jung rung rong rung rong/],
    [ qw/jou rou rou rou rou/],
    [ qw/ju ru ru ru ru/],
    [ qw/juan ruan ruan rwan ruan/],
    [ qw/jui ruei rui rwei ruei/],
    [ qw/jun run run rwun run/],
    [ qw/jo ruo ruo rwo ruo/],
    [ qw/sa sa sa sa sa/],
    [ qw/sai sai sai sai sai/],
    [ qw/san san san san san/],
    [ qw/sang sang sang sang sang/],
    [ qw/sao sau sao sau sao/],
    [ qw/se se se se se/],
    [ qw/sei sei sei sei sei/],
    [ qw/sen sen sen sen sen/],
    [ qw/seng seng seng seng seng/],
    [ qw/sha sha sha sha sha/],
    [ qw/shai shai shai shai shai/],
    [ qw/shan shan shan shan shan/],
    [ qw/shang shang shang shang shang/],
    [ qw/shao shau shao shau shao/],
    [ qw/she she she she she/],
    [ qw/shei shei shei shei shei/],
    [ qw/shen shen shen shen shen/],
    [ qw/sheng sheng sheng sheng sheng/],
    [ qw/shih shr shi shr shih/],
    [ qw/shung shung shong shung shong/],
    [ qw/shou shou shou shou shou/],
    [ qw/shu shu shu shu shu/],
    [ qw/shua shua shua shwa shua/],
    [ qw/shuai shuai shuai shwai shuai/],
    [ qw/shuan shuan shuan shwan shuan/],
    [ qw/shuang shuang shuang shwang shuang/],
    [ qw/shui shuei shui shwei shuei/],
    [ qw/shun shuen shun shwun shun/],
    [ qw/shuo shuo shuo shwo shuo/],
    [ qw/ssu sz si sz sih/],
    [ qw/sung sung song sung song/],
    [ qw/sou sou sou sou sou/],
    [ qw/su su su su su/],
    [ qw/suan suan suan swan suan/],
    [ qw/sui suei sui swei suei/],
    [ qw/sun suen sun swun sun/],
    [ qw/so suo suo swo suo/],
    [ qw/t'a ta ta ta ta/],
[ qw/t'ai tai tai tai tai/],
[ qw/t'an tan tan tan tan/],
[ qw/t'ang tang tang tang tang/],
[ qw/t'ao tau tao tau tao/],
[ qw/t'e te te te te/],
[ qw/t'eng teng teng teng teng/],
[ qw/t'i ti ti ti ti/],
[ qw/t'ien tian tian tyan tian/],
[ qw/t'iao tiau tiao tyau tiao/],
[ qw/t'ieh tie tie tye tie/],
[ qw/t'ing ting ting ting ting/],
[ qw/t'ung tung tong tung tong/],
[ qw/t'ou tou tou tou tou/],
[ qw/t'u tu tu tu tu/],
[ qw/t'uan tuan tuan twan tuan/],
[ qw/t'ui tuei tui twei tuei/],
[ qw/t'un tuen tun twun tun/],
[ qw/t'o tuo tuo two tuo/],
[ qw/wa wa wa wa wa/],
    [ qw/wai wai wai wai wai/],
    [ qw/wan wan wan wan wan/],
    [ qw/wang wang wang wang wang/],
    [ qw/wei wei wei wei wei/],
    [ qw/wen wen wen wen wun/],
    [ qw/weng weng weng weng wong/],
    [ qw/wo wo wo wo wo/],
    [ qw/wu wu wu wu wu/],
    [ qw/hsi shi xi syi si/],
    [ qw/hsia shia xia sya sia/],
    [ qw/hsien shian xian syan sian/],
    [ qw/hsiang shiang xiang syang siang/],
    [ qw/hsiao shiau xiao syau siao/],
    [ qw/hsieh shie xie sye sie/],
    [ qw/hsin shin xin syin sin/],
    [ qw/hsing shing xing sying sing/],
    [ qw/hsiung shiung xiong syung syong/],
    [ qw/hsiu shiou xiu syou siou/],
    [ qw/hsu: shiu xu syu syu/],
    [ qw/hsuan: shiuan xuan sywan syuan/],
    [ qw/hsueh: shiue xue sywe syue/],
    [ qw/hsun: shiun xun syun syun/],
    [ qw/ya ya ya ya ya/],
    [ qw/yai yai yai yai yai/],
    [ qw/yan yan yan yan yan/],
    [ qw/yang yang yang yang yang/],
    [ qw/yao yau yao yau yao/],
    [ qw/yeh ye ye ye ye/],
    [ qw/i yi yi yi yi/],
    [ qw/yin yin yin yin yin/],
    [ qw/ying ying ying ying ying/],
    [ qw/yung yung yong yung yong/],
    [ qw/yu you you you you/],
    [ qw/yu: yu yu yu yu/],
    [ qw/yuan: yuan yuan ywan yuan/],
    [ qw/yueh: yue yue ywe yue/],
    [ qw/yun: yun yun yun yun/],
    [ qw/tsa tza za dza za/],
    [ qw/tsai tzai zai dzai zai/],
    [ qw/tsan tzan zan dzan zan/],
    [ qw/tsang tzang zang dzang zang/],
    [ qw/tsao tzau zao dzau zao/],
    [ qw/tse tze ze dze ze/],
    [ qw/tsei tzei zei dzei zei/],
    [ qw/tsen tzen zen dzen zen/],
    [ qw/tseng tzeng zeng dzeng zeng/],
    [ qw/cha ja zha ja jha/],
    [ qw/chai jai zhai jai jhai/],
    [ qw/chan jan zhan jan jhan/],
    [ qw/chang jang zhang jang jhang/],
    [ qw/chao jau zhao jau jhao/],
    [ qw/che je zhe je jhe/],
    [ qw/chei jei zhei jei jhei/],
    [ qw/chen jen zhen jen jhen/],
    [ qw/cheng jeng zheng jeng jheng/],
    [ qw/chih jr zhi jr jhih/],
    [ qw/chung jung zhong jung jhong/],
    [ qw/chou jou zhou jou jhou/],
    [ qw/chu ju zhu ju jhu/],
    [ qw/chua jua zhua jwa jhua/],
    [ qw/chuai juai zhuai jwai jhuai/],
    [ qw/chuan juan zhuan jwan jhuan/],
    [ qw/chuang juang zhuang jwang jhuang/],
    [ qw/chui juei zhui jwei jhuei/],
    [ qw/chun juen zhun jwun jhun/],
    [ qw/cho juo zhuo jwo jhuo/],
    [ qw/tzu tz zi dz zih/],
    [ qw/tsung tzung zong dzung zong/],
    [ qw/tsou tzou zou dzou zou/],
    [ qw/tsu tzu zu dzu zu/],
    [ qw/tsuan tzuan zuan dzwan zuan/],
    [ qw/tsui tzuei zui dzwei zuei/],
    [ qw/tsun tzuen zun dzwun zun/],
    [ qw/tso tzuo zuo dzwo zuo/],
    );

# building index
my (%idx);
my $i = 0;
for my $p (@PS){
    for (@$p){
	$idx{lc $_}->{$i} = 1;
    }
$i++;
}

my %enum = (
    'wade-giles' => 0,
    'mps-2' => 1,
    'hanyu' => 2,
    'yale' => 3,
    'tongyong' => 4
    );

# table lookup
sub transfer($$$){
    my ($pinyin, $from, $to) = @_;
    return unless exists $idx{lc $pinyin};
    for my $line (keys %{$idx{lc $pinyin}}){
	return $PS[$line]->[$to] if($PS[$line]->[$from] eq $pinyin);
    }
}

sub convert($$$) {
    my ($from, $to, $text) = @_;
    $from = ( exists $enum{lc $from} ? $enum{lc $from} : croak "No such a system");
    $to   = ( exists $enum{lc $to}   ? $enum{lc $to} : croak "No such a system");

    my ($offset, $sslen, $ss, $matched, $rets, $targets, $SS);
    for($offset = 0; $offset < length $text; ){
	$matched = 0;
	for($sslen = 7; $sslen>0; $sslen--){
	    my $SS = substr($text, $offset, $sslen);
	    last unless $SS =~ m([':A-Za-z])o;
	    my $ss = lc $SS;
	    if( exists $idx{$ss} ){
		$targets = transfer($ss, $from, $to);
		if($targets){
                    $targets = ucfirst $targets if $SS =~ /^[A-Z]/o;
		    $offset += length $ss;
		    $matched = 1;
		    last;
		}
	    }
	}
	unless ($matched){
	    $rets .= substr($text, $offset, 1);
	    $offset++;
	}
	else{
	    $rets .= $targets;
	}
    }
    $rets;
}

1;
__END__

=head1 NAME

Lingua::ZH::PinyinConvert - Translation among various Chinese Pinyin Systems

=head1 SYNOPSIS

  use Lingua::ZH::PinyinConvert qw/convert/;
  print convert('tongyong', 'hanyu', 'ni hao ma?');
  print convert('hanyu', 'tongyong', 'wo hen hao');  # dull example

=head1 DESCRIPTION

Lingua::ZH::PinyinConvert translates Chinese Pinyin texts written in various Pinyin systems. Supported Pinyin systems are B<Wade-Giles>, B<MPS-2>, B<Hanyu>, B<Yale>, and B<Tongyong>.

See http://www.romanization.com/ for more information of these systems.

=head1 EXPORT_OK

=over 1

=item * convert($SOURCE_SYSTEM, $TARGET_SYSTEM, $TEXT);

  # converts text from Hanyu to Tongyong
  convert('hanyu', 'tongyong', 'wo hao ben');

=back

=head1 SEE ALSO

http://www.romanization.com/

L<PerlIO::via::PinyinConvert>

L<Lingua::ZH::CCDICT>

L<Lingua::ZH::CEDICT>

=head1 COPYRIGHT

xern <xern@cpan.org>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut

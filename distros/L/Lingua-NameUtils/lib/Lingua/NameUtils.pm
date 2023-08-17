# Lingua::NameUtils - Identify given/family names and capitalize correctly
#
# Copyright (C) 2023 raf <raf@raf.org>
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# 20230709 raf <raf@raf.org>

package Lingua::NameUtils;
use 5.014;
use strict;
use warnings;
use utf8;

our $VERSION = '1.003';

use Exporter;
our @ISA = ('Exporter');

our @EXPORT = ();
our @EXPORT_OK =
qw(
	namecase gnamecase fnamecase namecase_exception
	namesplit nameparts namesplit_exception namejoin
	nametrim normalize
);
our %EXPORT_TAGS =
(
	all => [@EXPORT_OK],
	case => [qw(namecase gnamecase fnamecase namecase_exception normalize)],
	split => [qw(namesplit nameparts namesplit_exception namejoin normalize)]
);

# Like fc() but "folds" apostrophe-like and hyphen-like characters as well

my $myfc = (defined eval { &CORE::fc('') }) ? \&CORE::fc : sub { lc shift }; # Downgrade to lc on perl 5.14
my $apostrophe = qr/['’ʼʻ]/; # Apostrophe, Right single quotation mark, Modifier letter apostrophe, Modifier letter turned comma
my $hyphen = qr/\p{dash punctuation}/; # Hyphen-Minus, Hyphen, En Dash, Em Dash, et al.
sub kc { return $myfc->(shift) =~ s/$apostrophe/'/gr =~ s/$hyphen/-/gr }

# Builtin namecase exceptions (Mostly gathered by Michael R. Davis (MRDVT))

my @namecase_exceptions =
(qw(
	MacAlister MacAlpin MacAlpine MacArthur MacAuley MacBain MacBean
	MacCallum MacColl MacDomhnaill MacDonald MacDonell MacDonnell MacDougall
	MacDowall MacDuff MacEvan MacEwen MacFarlane MacFie MacGill MacGillivray
	MacGregor MacInnes MacIntosh MacIntyre MacIver MacKay MacKenzie
	MacKinlay MacKinnon MacKintosh MacLachlan MacLaine MacLaren MacLaurin
	MacLea MacLean MacLeay MacLellan MacLennan MacLeod MacMillan MacNab MacNaughton
	MacNeacail MacNeil MacNeill MacNicol MacO'Shannaig MacPhee MacPherson
	MacQuarrie MacQueen MacRae MacTavish MacThomas

	MacAuliffe MacCarty MacClaine MacCauley MacClelland MacCleery MacCloud
	MacCord MacCleverty MacCredie MacCue MacCurrach MacEachern MacGilvray
	MacCray MacDuffie MacFadyen MacFarland MacKinley MacKinney MacLaughlin
	MacIvor MacKechnie MacLucas MacManus MacMartin MacNeary MacNevin
	MacMahon MacNaught MacNeal MacShane MacWhirter MacAtee MacCarthy
	MacWilliams MaDej MaGaw

	AbuArab

	DaSilva DeAnda DeAngelo DeBardelaben DeBary DeBaugh DeBeck DeBergh
	DeBerry DeBlanc DeBoe DeBoer DeBonis DeBord DeBose DeBostock DeBourge
	DeBroux DeBruhl DeBruler DeButts DeCaires DeCamp DeCarolis DeCastro
	DeCay DeConinck DeCook DeCoppens DeCorte DeCost DeCosta DeCoste DeCoster
	DeCouto DeFamio DeFazio DeFee DeFluri DeFord DeForest DeFraia DeFrancis
	DeFrange DeFree DeFrees DeGarmo DeGear DeGeare DeGnath DeGraff
	DeGraffenreid DeGrange DeGraw DeGrenier DeGroft DeGroot DeGuaincour
	DeHaan DeHaas DeHart DeHass DeHate DeHaven DeHeer DeHerrera DeJarnette
	DeJean DeLaet DelAmarre DeLancey DeLara DeLarm DelAshmutt DeLaughter
	DeLay DeLespine DelGado DelGaudio DeLong DeLony DeLorenzo DeLozier
	DelPrincipe DelRosso DeLuca DeLude DeLuke DeMaio DeMarchi DeMarco
	DeMarcus DeMarmein DeMars DeMartinis DeMay DeMello DeMonge DeMont
	DeMontigny DeMoss DeNunzio DeNure DePalma DePaola DePasquale DePauli
	DePerno DePhillips DePoty DePriest DeRatt DeRemer DeRosa DeRosier
	DeRossett DeSaegher DeSalme DeShane DeShano DeSilva DeSimencourt
	DeSimone DesJardins DeSoto DeSpain DesPlanques DeSplinter DeStefano
	DesVoigne DeTurck DeVall DeVane DeVaughan DeVaughn DeVaul DeVault
	DeVenney DeVilbiss DeVille DeVillier DeVinney DeVito DeVore DeVorss
	DeVoto DeVries DeWald DeWall DeWalt DeWilfond DeWinne DeWitt DeWolf
	DeYarmett DeYoung DiBenedetto DiBona DiCaprio DiCicco DiClaudio
	DiClemento DiFrisco DiGiacomo DiGiglio DiGraziano DiGregorio DiLiberto
	DiMarco DiMarzo DiPaolo DiPietrantonio DiStefano DoBoto DonSang DuBois
	DuBose DuBourg DuCoin DuPre DuPuy DeVaux DeVoir

	EnEarl

	Fitzell

	LaBarge LaBarr LaBelle LaBonte LaBounty LaBrue LaCaille LaCasse
	LaChapelle LaClair LaCombe LaCount LaCour LaCourse LaCroix LaFarge
	LaFeuillande LaFlamme LaFollette LaFontaine LaForge LaForme LaForte
	LaFosse LaFountain LaFoy LaFrance LaFuze LaGaisse LaGreca LaGuardia
	LaHaise LaLande LaLanne LaLiberte LaLonde LaLone LaMaitre LaMatry LaMay
	LaMere LaMont LaMotte LaMunyon LaPierre LaPlante LaPointe LaPorte
	LaPrade LaPrairie LaQue LaRoche LaRochelle LaRose LaRue LaSalle LaSance
	LaSart LaTray LaVallee LaVeau LaVenia LaVigna LeBerth LeBlond LeBoeuf
	LeBreton LeCaire LeCapitain LeCesne LeClair LeClaire LeClerc LeCompte
	LeConte LeCour LeCrone LeDow LeDuc LeFevre LeFlore LeFors LeFridge
	LeGrand LeGras LeGrove LeJeune LeMaster LeMesurier LeMieux LeMoine
	LePage LeQuire LeRoy LeStage LeSuer LeVally LeVert LiConti LoManto
	LoMastro LoRusso

	SanFillipo SanGalli SantaLucia

	TePas

	VanArsdale VanBuren VanCamp VanCleave VanDalsem VanderLey VanderNeut
	VanderTol VanderWegen VanDerWeyer VanderWilligen VanDevelde VandeWege
	VanDolah VanDusen VanDyke VanHee VanHoak VanHook VanHoose VanHouten
	VanHouwe VanHoven VanKampen VanKleck VanKleeck VanKuiken VanLanduyt
	VanLeer VanLiere VanLuven VanMeter VanOlinda VanOrmer VanPelt VanSchaick
	VanSciver VanScoy VanScoyk VanSickle VanTassel VanTuyl VanValkenburg
	VanVolkenburgh VanWinkle VanWysenberghe VanZandt VenDerWeyer VonCannon
));

my %namecase_exceptions;

# Capitalization exceptions for full names used by namecase().
# Include both forms: "given_names family_name" and "family_name, given_names".

my %namecase_exceptions_full;

# Capitalization exceptions for full names used by fnamecase().
# This must have the same keys as namecase_exceptions_full.

my %fnamecase_exceptions_full;

# Non-individual case exception replacements need a long regex that needs to
# be constructed, and can change. But probably not often. And sometimes a
# lot at once. Regex construction is cached lazily when needed for use.

my $need_case_update = 1;
my $namecase_exceptions_re;

# Name affixes that start a multi-word family name

my %split_starter;
my $split_starter_re;
my @split_starter =
(qw(
	de de’ de' del dels dela della delle dal dalla degli di da du do dos das
	le la li lo y i
	van von zu der ter den af av til
	el al ibn bin ben bat bint binti binte mibeit mimishpachat
	of o ó ni ní mac nic ua bean ui uí mhic ap ab ferch verch
	san santa santos st st. ste ste.
	ka te
));

# Data for regexes that are affected by normalization

my @irish_o = qw(O Ó);
my @irish_vowel = qw(a e i o u á é í ó ú);
my @irish_post_bean = qw(Uí Ui Mhic);

my $irish_o_re = "(?:@{[join '|', @irish_o]})";
my $irish_vowel_re = "(?:@{[join '|', @irish_vowel]})";
my $irish_post_bean_re = "(?:@{[join '|', @irish_post_bean]})";

# Family names that appear first (Chinese, Korean, Vietnamese).
# When romanized, these family names can appear first or last.
# This is only possible when there are only hundreds of names.
# For Japanese, a statistical method is used.

my %family_names_ck;
my $family_names_ck_re;
my %family_names_ck_roman;
my $family_names_ck_roman_re;
my %family_names_v_roman;
my $family_names_v_roman_re;

my @family_names_chinese =
(qw(
王 李 張 张 劉 刘 陳 陈 楊 杨 黃 黄 趙 赵 吳 吴 周 徐 孫 孙 馬 马 朱 胡 郭 何 林 高
羅 罗 鄭 郑 梁 謝 谢 宋 唐 許 许 鄧 邓 韓 韩 馮 冯 曹 彭 曾 蕭 萧 田 董 潘 袁 蔡 蔣 蒋
余 于 杜 葉 程 魏 蘇 呂 丁 任 盧 卢 苏 吕 姚 沈 鍾 钟 姜 崔 譚 谭 陸 陆 范 汪 廖 石
金 韋 韦 賈 贾 夏 傅 方 鄒 邹 熊 白 孟 秦 邱 侯 江 尹 薛 閻 阎 段 雷 龍 龙 黎 史 陶
賀 贺 毛 郝 顧 顾 龔 龚 邵 萬 万 覃 武 錢 钱 戴 嚴 严 歐 欧 莫 孔 向 常 湯 汤 康 易
喬 乔 賴 赖 文 施 洪 辛 柯 莊 庄

温 牛 樊 葛 邢 安 齐 伍 庞 颜 倪 聂 章 鲁 岳 翟 殷 詹 申 耿 关 兰 焦 俞 左 柳 甘 祝 包 宁 尚 符
舒 阮 纪 梅 童 凌 毕 单 季 裴 霍 涂 成 苗 谷 盛 曲 翁 冉 骆 蓝 路 游 靳 欧阳 管 柴 蒙 鲍 华 喻
祁 蒲 房 滕 屈 饶 解 牟 艾 尤 阳 时 穆 农 司 卓 古 吉 缪 简 车 项 连 芦 麦 褚 娄 窦 戚 岑 景 党
宫 费 卜 冷 晏 席 卫 米 柏 宗 瞿 桂 全 佟 应 臧 闵 苟 邬 边 卞 姬 师 和 仇 栾 隋 商 刁 沙 荣 巫
寇 桑 郎 甄 丛 仲 虞 敖 巩 明 佘 池 查 麻 苑 迟 邝 官 封 谈 匡 鞠 惠 荆 乐 冀 郁 胥 南 班 储 原
栗 燕 楚 鄢 劳 谌 奚 皮 粟 冼 蔺 楼 盘 满 闻 位 厉 伊 仝 区 郜 海 阚 花 权 强 帅 屠 豆 朴 盖 练
廉 禹 井 祖 漆 巴 丰 支 卿 国 狄 平 计 索 宣 晋 相 初 门 雲 容 敬 来 扈 晁 芮 都 普 阙 浦 戈 伏
鹿 薄 邸 雍 辜 羊 阿 乌 母 裘 亓 修 邰 赫 杭 况 那 宿 鲜 印 逯 隆 茹 诸 战 慕 危 玉 银 亢 嵇 公
哈 湛 宾 戎 勾 茅 利 於 呼 居 揭 干 但 尉 冶 斯 元 束 檀 衣 信 展 阴 昝 智 幸 奉 植 衡 富 尧 闭 由

習 习 隰 郤 郗
));

my @family_names_chinese_roman =
(qw(
Wáng Wang Wong Vang Ông Bong Heng Vòng Uōng Waon Whang Vương Ong Ō
Lǐ Li Lei Lee Ly Lí Lî Lý Ri Yi Rhee Dy Dee Sy
Zhāng Chang Zoeng Cheung Cheong Chong Tiuⁿ Tioⁿ Teo Teoh Tio Chông Tong Thong Tsan Tzan Zan Trương Jang Chō Tiu Tiong Sutiono Tjong
Liú Liu Lau Lao Lou Lưu Lâu Low Liù Liew Lew Lieu Lio Yu Yoo Ryū
Chén Ch'en Can Chan Chun Chean Chin Tân Tan Tang Ting Chhìn Thín Thin Zen Tchen Trần Jin Tantoco Tanteksi
Yáng Yang Joeng Yeung Yeong Ieong Young Iûⁿ Iôⁿ Yeoh Yeo Yo Nyo Yòng Yong Iōng Yan Ian Dương Yu Yung Yana Yongco Yuchengco Yō
Huáng Huang Wong Wang Vong N̂g Ûiⁿ Ng Ung Ooi Uy Wee Vòng Bong Uōng Fong Waon Whang Hoàng Huỳnh Hwang Kō
Zhào Chao Ziu Chiu Chu Chio Jiu Tiō Tiǒ Teo Teoh Chhau Chau Thèu Cheu Chew Zau Zo Triệu Jo Tio Chō
Wú Wu Ng Ung Eng Gô͘ Ngô͘ Goh Ǹg Woo Ngô Oh Go Kure Ngo Gozon Gozum Cinco Gochian Gokongwei Gosiengfiao
Zhōu Chou Zau Chow Chau Jao Chao Chiu Chew Jew Chiû Chiew Tiu Cheu Tseu Tzo Chu Châu Ju Shū Joe
Xú Hsü Ceoi Tsui Choi Chui Tsua Chhî Sîr Chee Cher Cheu Swee Ji Jee Chhì Chi Chhié Zhi Zee Zi Từ Seo Sho Dharmadjie Christiadjie
Sūn Sun Syun Suen Sng Suiⁿ Soon Sûn Sen Tôn Son Suan
Mǎ Ma Maa Mah Mar Má Bé Bey Beh Baey Mâ Mo Mu Mã Mapua Ba
Zhū Chu Zyu Chue Choo Chû Tu Tsy Tsyu Tzu Châu Ju Shu Gee
Hú Hu Wu Woo Vu Ô͘ Oh Ow Aw Fù Foo Ū Hồ Ho Ko
Guō Kuo Gwok Kwok Kuok Koeh Keh Kerh Kueh Koay Quay Kwek Quek Kwik Kok Koh Goh Koq Quách Gwak Kaku Que Cue Quezon Quison Ker Kho Kue
Hé Hê Ho Hoe Hô Hor Hou Hò Hó Wu Woo Hà Ha Ka
Lín Lin Lam Lum Lîm Lim Lìm Līm Ling Lâm Im Rim Rin Hayashi
Gāo Kao Gou Ko Kou Go Ko͘ Kor Kô Kau Koo Gau Cao Kō Caw Co Gao
Luó Lo Law Loh Lowe Lor Lô Lò Lō Lu Loo La Na Ra
Zhèng Cheng Zeng Cheang Chiang Tēⁿ Tīⁿ Tìⁿ Tēeⁿ Tay Teh Chhang Chang Thàng Zen Zung Trịnh Jeong Tei Ty Tee
Liáng Liang Loeng Leung Leong Lang Leng Niû Niô͘ Neo Liòng Liōng Lian Lương Yang Ryang Liong Niu Ryō
Xiè Hsieh Ze Tse Che Chiā Siā Sià Chia Cheah Seah Tshia Chhià Zhia Zia Tạ Sa Sha Tsia Sia Saa Sese Shie
Sòng Sung Sàng Song Soong Sūng Son Tống Sō Songco
Táng T'ang Tong Tn̂g Tông Tng Tang Thòng Thong Thóng Daon Daan Đường Dang Teng Tō
Xǔ Hsü Heoi Hui Hoi Khó͘ Koh Khoh Ko Hí Hee Hé Siu Syu Shiu Hái Hứa Heo Kyo Kho Co Kaw Cojuangco
Dèng Teng Dang Tang Theng Tēng Tèng Then Ten Thèn Den Đặng Deung Tō Deang Tengco Tangco
Hán Han Hon Hân Hang Hòn Hón Ghoe Reu Hàn Kan
Féng Feng Fung Fong Pâng Pang Fùng Phùng Foong Fūng Von Vong Pung Hō Pangco
Cáo Ts'ao Cou Cho Tso Chaw Chô Chô͘ Chow Tshò Tshàu Chhóu Zau Zo Tào Jo Sō
Péng P'eng Pang Banh Phêⁿ Phîⁿ Phêeⁿ Peh Phe Phàng Phang Pháng Ban Bành Paeng Hō Beng Pangco Pay
Zēng Tseng Zang Tsang Chang Dong Chan Tsên Chen Tsen Tzen Tsung Tăng Jeung Sō Tjan Tzeng
Xiāo Hsiao Siu Shiu Sio Siau Seow Siow Siâu Siew Siaw Sieu Shio Tiêu So Siao Syaw Shau Shao Shaw Shō
Tián T'ien Tin Chan Tiân Chang Thièn Thien Then Thién Di Dee Điền Jeon Tian Tien Ten
Dǒng Tung Dung Tong Táng Tóng Túng Tûng Ton Toong Đổng Dong Tō
Pān P'an Pun Poon Phoaⁿ Phua Phân Pan Phan Phon Phoe Poe Ban Han Pua
Yuán Yüan Jyun Yuen Wan Oân Wang Yèn Yen Iōn Yoe Yoo Yeu Viên Won En Yan
Cài Ts'ai Coi Choi Choy Tsoi Toy Chhoà Chua Chhai Chai Chhói Tsa Thái Sái Chae Sai Chuah Cua Choa Tsai Tsay
Jiǎng Chiang Zoeng Tseung Cheung Chiúⁿ Chióⁿ Cheoh Chioh Tsiòng Cheong Chiông Cian Jian Tưởng Jang Shō Chio Chiu Chung
Yú Yü Jyu Yu Yue U Yee Î Û Îr Ee Eu Yì Uī Dư Yeo Yo Ie Iman Oe
Sū Su Sou So So͘ Soh Sû Soo Tô Solon
Lǚ Lü Leoi Lui Loi Lū Lī Lǐr Lee Leu Ler Loo Lî Liê Li Lữ Lã Yeo Ryeo Ryo Lu Luy
Dīng Ting Ding Teng Tén Ten Tiang Tin Đinh Jeong Tei
Rén Jen Jam Yam Iam Yum Jîm Lîm Līm Jim Ngim Yim Nìm Nin Nying Nhiệm Nhậm Im Jin
Lú Lu Lou Lo Lô͘ Loh Lù Loo Lū Lư Lô No Ro
Yáo Yao Jiu Yiu Yeow Io Iu Iâu Yeo Yào Yow Iēu Yau Diêu Yo Yō
Shěn Shen Sam Shum Sum Sham Sím Sim Shím Sen Sung Thẩm Trầm Shim Shin
Zhōng Chung Zung Chong Chiong Cheng Chûng Tsung Tung Tson Tzon Jong Shō
Jiāng Chiang Goeng Keung Geung Keong Khiang Khiong Khiuⁿ Kiang Kiông Kiong Cian Jian Khương Kang Kyō
Cuī Ts'ui Ceoi Chui Choi Chhui Chwee Tshûi Chooi Chhoi Tsoe Tseu Thôi Sai Tseui
Tán T'an Taam Tam Tom Ham Hom Thâm Tham Thàm Thóm De Dae Đàm Dam Tan
Lù Lu Luk Lok Lio̍k Loke Lek Liu̍k Liuk Loh Loq Lục Yuk Ryuk Riku Diokno
Fàn Fan Faan Hoān Hoǎn Hwan Huang Hoan Fam Ve Vae Phạm Beom Han Juan
Wāng Wang Wong Ong Óng Vong Uong Waon Whang Uông Ō Ang
Liào Liao Liu Lew Leow Liew Lio Liāu Liàu Liau Liow Lièu Liêu Liệu Ryo Ryō
Shí Shih Sek Shek Seac Seak Chio̍h Chioh Cheoh Sha̍k Sak Shak Zah Zaq Thạch Seok Seki
Jīn Chin Gam Kam Gum Kim Kîm Cin Jin Kin
Wéi Wei Wai Vai Ûi Úi Wee Vúi Vì Wooi Uī We Vi Wi I Uy
Jiǎ Chia Gaa Ka Ga Ká Kée Kia Kâ Cia Jia Giả Go
Xià Hsia Haa Ha Hē Hā Hà Hēe Hah Hay Gho Ya Wo Hạ Ka
Fù Fu Foo Pò͘ Poh Phó Bu Po
Fāng Fang Fong Hong Png Puiⁿ Pung Fông Faon Faan Phương Bang Hō
Zōu Tsou Zau Chau Chow Jao Cho͘ Cho Che Chou Choh Tsêu Chew Chiew Chiu Tseu Tzeu Châu Chu Shū
Xióng Hsiung Hung Hong Hîm Him Yùng Yoong Hiūng Yon Hùng Ung Yū
Bái Pai Baak Pak Bahk Pe̍h Pe̍k Peh Pha̍k Phak Bah Baq Bạch Baek Haku Bo
Mèng Meng Maang Mang Bēng Bèng Men Màng Man Mạnh Maeng Mō
Qín Ch'in Ceon Chun Tseun Tseon Chon Chîn Ching Tshìn Chin Chhín Zhin Zin Tần Jin Shin
Qiū Ch'iu Jau Yau Iao Iau Khu Khoo Kho Khiû Hiû Hew Khew Khiu Chieu Khâu Gu Kyū Hiew Chiew Coo Chiou
Hóu Hou Hau Hao Hô͘ Hâu Kâu Hoh Hèu Hew Héu Gheu Roe Hầu Hu Kō Caw Ho
Jiāng Chiang Gong Kong Kang Kông Kaon Giang Gang Kō Kiang
Yǐn Yin Wan Ún Ín Un Eun Eung Yún Yoon Doãn Yun In Unson
Xuē Hsüeh Sit Sih Siet Set Siot Shih Siq Tiết Seol Setsu
Yán Yen Jim Yim Im Giâm Ngiam Ngiàm Yam Iēm Ni Gni Nyi Diêm Yeom En
Duàn Tuan Dyun Tuen Tun Toān Toàn Tng Teung Thon Ton Thòn Doe Deu Đoàn Dan
Léi Lei Leoi Lui Loi Lûi Lùi Looi Lōi Le Lae Lôi Roe Noe Rai Luy Hoisan
Lóng Lung Loong Long Lêng Liông Leng Liong Liùng Liūng Lon Yong Ryong Ryō Leong Wee
Lí Li Lai Lê Loy Loi Lì Lài Lee Lī Yeo Ryeo Rei
Shǐ Shih Si Sze Sú Sái Sír Ser Seu Sṳ́ Soo Sî Sy Sử Sa Shi
Táo T'ao Tou To Tao Tow Tô Tô͘ Thô Thàu Thò Thóu Dau Do Đào Tō
Hè Hê Ho Hō Hò Hor Fo Wu Woo Hạ Ha Ka
Máo Mao Mou Mo Mô͘ Mor Mô Mâu Mōu Mau Bō
Hǎo Hao Kok Hok Hak Khok Heh Heq Hác Kaku
Gù Ku Gu Goo Khoo Kò͘ Koh Koo Kū Cố Go Ko Coo
Gōng Kung Gung Kwong Kéng Kiong Kiûng Kong Kiung Cion Jiong Jun Cung Gong Kyō
Shào Shao Siu Shiu Shaw Sio Siō Siāu Siàu Seow Sioh Shau Sau Sèu Zau Zo Thiệu So Shō Siao Syaw
Wàn Wan Maan Man Meng Bān Bàn Buang Van Màn Vae Mae Ve Me Vạn Ban
Tán Qín T'an Taam Tam Thâm Thàm Thóm Dae De Dam Tan
Wǔ Wu Mou Mo Bú Boo Vú Moo Woo Mú Ghu Vũ Võ Mu Bu
Qián Ch'ien Cin Chin Chee Chîⁿ Tshièn Chen Chhién Zhi Zee Tiền Jeon Sen Chi
Dài Tai Daai Tè Tèr Thài Ta Da Đái Đới Dae Te
Yán Yen Jim Yim Im Giâm Ngiam Ngiàm Yam Ngiēm Ni Gni Nyi Nghiêm Eom Gen Gan
Ōu Ou Au Eu Ō
Mò Mo Mok Bo̍h Bo̍k Mo̍k Moh Moq Mạc Baku
Kǒng K'ung Hung Khóng Kong Khong Khúng Koong Khoong Khon Kung Khổng Kyō Consunji
Xiàng Hsiang Hoeng Heung Hiòng Hiàng Hiang Hióng Shian Hian Hưởng Hyang 향 Kyō
Cháng Ch'ang Soeng Sheung Siông Siâng Sioh Seoh Sòng Song Sōng Zan Thường Sang Shō Thōng
Tāng T'ang Tong Thng Tng Teung Thông Thong Thaon Thaan Thang Tō Tang
Kāng Kang Hong Khng Khang Không Khong Kong Khaon Khaan Gang Kō
Yì Yi Yik E̍k Ia̍k Ek Yit Iak I Yih Yiq Dịch Yee Eki
Qiáo Ch'iao Kiu Kiâu Keow Kiao Khiàu Kiew Khiew Khiéu Jiau Djio Jioh Kiều Kyo Kyō
Kē kʻo O Ngo Koa Kho Ko Ker Quah Kwa Khô Ko´ Khu Koo Kha Ga Ka Cua Kua Co Coson
Lài Lai Laai Lay Lōa Lòa Nai La Le Lae Lại Roe 뢰 Noe Rai
Wén Wen Man Bûn Boon Vùn Voon Mūn Ven Vung Văn Moon Bun
Shī Shih Si Xi Soa Sy Sua Sṳ̂ Sii´ Thí Shi I See Sze
Hóng Hung Huhng Âng Hông Ang Hong Fùng Fung Ghon Won Ung Hồng Hòng Kō
Xīn Hsin San Sen Sîn Sin Xin´ Sîng Shin Tân Sing Singson
Zhuāng Chuang Zong Tsong Chong Jong Chng Cheng Chông Zong´ Tsaon Tsaan Tzaon Trang Đồ Dưa Chan Chang Jang Shō Sō Ching Chung

An Ang Ao Au Au_Yeung Ba Bai Ban Bao Bau Bi Bo Bu Cai Cao Cha Chai Cham Chan Chang Chao Chau Che
Cheah Chee Chen Cheng Cheong Chern Cheung Chew Chi Chia Chiang Chiao Chien Chim Chin Ching Chiong
Chiou Chiu Cho Choi Chong Choo Chou Chow Choy Chu Chua Chuang Chui Chun Chung Cong Cui Dai Dang
Dea Deng Ding Do Dong Doo Du Duan Dung Eng Fan Fang Fei Feng Fok Fong Foo Fu Fung Gan Gang Gao
Gau Ge Geng Go Goh Gong Gu Guan Guo Ha Hai Han Hang Hao Hau He Ho Hoh Hom Hon Hong Hoo Hou Hsi
Hsia Hsiao Hsieh Hsiung Hsu Hsueh Hu Hua Huang Hui Huie Hum Hung Huo Hwang Hy Ing Ip Jan Jang
Jen Jeng Jeung Jew Jia Jian Jiang Jiao Jim Jin Jing Jo Joe Jong Joo Jou Jow Ju Jue Jung Kam Kan
Kang Kao Kau Ke Keng Kho Khoo Kiang King Ko Koh Kong Koo Kook Kou Ku Kuan Kuang Kuk Kung Kuo Kwan
Kwock Kwok Kwon Kwong Lai Lam Lan Lang Lao Lau Lee Lei Leng Leong Leung Lew Li Lian Liang Liao Liaw
Lien Liew Lim Lin Ling Liou Liu Lo Loh Lok Long Loo Lu Lua Lui Luk Lum Lung Luo Ma Mah Mai Mak Man
Mao Mar Mau Mei Meng Miao Min Ming Miu Mo Mok Mon Mou Moy Mu Mui Na Ng Ngai Ngan Ngo Ni Nie Ning Niu
On Ong Ou Ou_Yang Ow Owyang Pan Pang Pao Pau Pei Peng Pi Ping Po Pon Pong Poon Pu Pun Qi Qian Qiao
Qin Qiu Qu Quan Que Rao Ren Rong Ruan San Sang Seto Sha Sham Shan Shang Shao Shaw Shek Shen Sheng
Sheu Shi Shiau Shieh Shih Shing Shiu Shu Shum Shy Shyu Si Sieh Sin Sing Sit Situ Siu So Soh Song
Soo Soo_Hoo Soon Soong Su Suen Sui Sum Sun Sung Sze Szeto Tai Tam Tan Tang Tao Tay Te Teh Teng Teo
Tian Tien Tin Ting Tiu To Toh Tong Tsai Tsang Tsao Tsay Tse Tseng Tso Tsoi Tsou Tsu Tsui Tu Tuan
Tung Tzeng U Un Ung Wah Wai Wan Wang Wee Wei Wen Weng Wing Wong Woo Woon Wu Xi Xia Xiang Xiao Xie
Xin Xing Xiong Xu Xue Yam Yan Yang Yao Yap Yau Yaw Ye Yee Yeh Yen Yep Yeung Yi Yim Yin Ying Yip Yiu
Yong Yoon You Young Yu Yuan Yue Yuen Yun Yung Zang Zeng Zha Zhan Zhang Zhao Zhen Zheng Zhong Zhou Zhu
Zhuang Zhuo Zong Zou
));

my @family_names_korean =
(qw(
가 價 賈
간 簡 間
갈 葛
감 甘
강 姜 康 強 剛 江 㝩
견 堅 甄
경 京 慶 景 耿
계 季 桂
고 顧 高
곡 曲 谷
공 公 孔
곽 廓 槨 郭
관 管 關
교 喬 橋
구 丘 仇 具 邱
국 國 菊 鞠 鞫 麴
궁 宮 弓
궉 鴌
권 權 勸 㩲 券
근 斤
금 琴 禁 芩 金
기 奇 寄 箕 紀
길 吉
김 金
나 라 羅 蘿 邏 那
난 란 欒
남 南 男
남궁 南宫 南宮
낭 랑 浪
내 乃 奈
노 로 努 卢 盧 蘆 虜 路 魯
뇌 뢰 雷
다 多
단 單 段 端
담 譚
당 唐
대 代 大 戴
도 到 度 桃 覩 道 都 陶
독고 獨孤
돈 頓
동 東 童 董 蕫 薫
동방 東方
두 杜
등 滕 鄧
등정 藤井
라 羅 蘿 邏
란 欒
랑 浪
려 呂
로 盧 路 魯
뢰 雷
류유 㧕 劉 柳
리 李
림 林
마 馬 麻
만
망절 網切
매 梅
맹 孟
명 明
모 慕 毛 牟
목 睦 穆
묘 苗
무 武
무본 武本
묵 墨
문 文 門
미 米
민 悶 敏 旻 民 珉 閔
박 博 朴
반 潘 班
방 房 方 旁 芳 邦 防 龐
배 培 背 裵 輩 配
백 伯 柏 白 百
번 樊
범 範 范
변 卞 變 邊
보 保 寶 甫
복 卜
복호 卜扈
봉 奉 鳳
부 付 傅 夫 富
비 丕
빈 彬 濱 貧 賓 賔
빙 氷
부여 夫餘
사 史 司 沙 舍 謝
사공 司公 司空
산 山
삼 杉 森
상 商 尙 尚 常
서 俆 徐 書 緖 西
서문 西問 西門
석 席 昔 石 釋
선 善 宣 鮮
선우 蘚于 鮮于 鮮宇 鮮牛
설 偰 卨 楔 薛 辥 雪
섭 葉
성 城 宬 成 星 盛
소 卲 小 所 昭 簫 肖 蕭 蘇 邵
손 孫 損 蓀 遜
송 宋 松 送
수 水 洙 隋
순 淳 筍 舜 荀 順 旬
승 承 昇
시 施 時 柴
신 伸 信 愼 新 申 莘 辛
심 心 沁 沈 深
아 阿
안 安 案 顔
애 艾
야 夜
양 량 揚 梁 楊 樑 樣 洋 粱 陽
어 漁 魚
어금 魚金
엄 㘙 儼 嚴
여 려 余 呂 黎 予
연 련 延 涎 燕 連
염 렴 廉 簾 閻
엽 葉
영 影 榮
예 倪 禮 芮 藝
오 五 伍 吳 吾 晤
옥 玉
온 溫
옹 邕 雍
완 阮
왕 汪王
요 姚
용 룡 龍
우 于 偶 宇 寓 尤 愚 牛 禹 遇
운 芸 雲
원 元 原 圓 苑 袁 阮 院
위 偉 衛 韋 魏
유 류 兪 劉 庾 有 杻 枊 柳 楡 由 裕
육 륙 陸
윤 尹 允 潤
은 殷 恩 隱 銀 誾
음 陰
이 리 李 㛅 伊 利 怡 異
인 印
임 림 任 壬 恁 林
자 慈
장 張 場 壯 將 庄 漿 章 臧 莊 葬 蔣 藏 裝 長
전 全 戰 田 錢
점 佔
정 鄭 丁 定 情 政 桯 正 程
제 諸 齊
제갈 諸葛 諸曷 諸渴
조 趙 刁 曺 朝 調 造 曹
종 宗 鍾
좌 佐 左
주 主 周 朱 株 珠
증 增 曾
지 地 智 池 遲
진 䄅 晋 珍 眞 秦 蔯 進 陣 陳
차 車 次
창 倉 昌
채 菜 蔡 采
천 千 天 川
초 初 楚
최 催 寉 崔 最
추 秋 鄒
탁 卓
탄 彈
태 太 泰
판 判
팽 彭
편 片
평 平
포 包
표 俵 表
풍 馮
피 皮
필 弼 畢
하 何 夏 河
학 郝
한 恨 汗 漢 韓
함 咸
해 海 解
허 許
현 玄 賢
형 刑 形 邢
호 扈 湖 胡 虎 鎬
홍 㤨 䜤 哄 弘 洪 烘 紅
화 化
황 晃 潢 煌 皇 簧 荒 黃
황목 荒木
황보 皇甫 黃甫
후 侯 候 后
료
웅
));

my @family_names_korean_roman =
(qw(
Ga Ka Kar Gar Kah Gah Ca Cah Car
Gan Kan Gahn Kahn
Gal Kal Karl Garl Gahl Kahl Cahl Carl Cal
Gam Kam Kahm Gahm Cam
Gang Kang Kahng Khang
Gyeon Kyŏn Kyun Kyeon Kyoun Kyon
Gyeong Kyŏng Kyung Kyoung Kyeong Kyong
Gye Kye Kyeh Kay Kie Kae Gae
Go Ko Koh Goh Kho Gho Kor Co
Gok Kok Kog Gog Cock Gogh Cough
Gong Kong Kohng Koung Goung Khong Cong
Gwak Kwak Kwag Kwack Gwag Koak Kuark Quack Quark
Gwan Kwan Quan Kuan Guan
Gyo Kyo Kyoh Gyoh
Gu Ku Koo Goo Kou Kuh Khoo Khu
Guk Kuk Kook Gook Kug Gug Cook
Gung Kung Koong Kwoong
Gwok Kwŏk Kwog Gwog Quock
Gwon Kwŏn Kwon Kweon Kwun
Geun Kŭn Keun Kuen Guen
Geum Kŭm Keum Kum Gum Guem Kuem
Gi Ki Kee Key Gee Ky Khee Kie
Gil Kil Gill Khil Keel Kihl Kiehl Kill
Gim Kim Ghim Kym Keem Gym
Na Ra Nah La Rha Rah Law
Nan Ran Nahn Rahn Nhan Rhan Lan Lahn
Nam Nahm Nham Narm
Namgung Namkung Namgoong Namkoong Namkuhng Namguhng
Nang Rang Nahng Lang
Nae Nai Nay Nea
No Ro Noh Roh Nau Rau
Noe Roe Roi Noi
Da Ta
Dan Tan Dahn Than
Dam Tam Tham Dham Dahm Tahm
Dang Tang Dhang Thang
Dae Tae Dai Dea Day Tai Tay Tea
Do To Dho Doh Toe Doe Toh
Dokgo Tokko Dokko Toko Doko Dockko Dogko Togko Tokgo
Don Ton Dohn Tohn
Dong Tong Dhong Thong
Dongbang Tongbang Tongpang Dongpang
Du Tu Doo Do Dou Tou To Too
Deung
Deungjeong
Ra Rah
Ran Rahn
Rang
Ryeo Ryuh
Roh
Roe Roi
Ryu Ryou Rou Ryoo Yu Yoo You Yuh
Ree
Rim Leem
Ma Mah Mar
Man Mann Mahn
Mangjeol Mangjŏl Mangjul Mangjuhl Mangjoul
Mae May Mea Mai
Maeng Maing Meang
Myeong Myŏng Myung Myoung Myong
Mo Moh Moe
Mok Mock Mog Mork
Myo Myoh Mio
Mu Moo
Mubon
Muk Mook
Mun Moon Muhn
Mi Mee Mih Meeh Me
Min Minn Mihn Mean
Bak Pak Park Back Bahk Pahk
Ban Pan Bahn Pahn Bhan Van
Bang Pang Bhang Bahng Pahng Phang
Bae Pae Bai Bea Pai Bay Pay
Baek Paek Baik Back Paik Pack Beak
Beon Bun Burn
Beom Pŏm Bum Bom Peom Pum Puhm Buhm
Byeon Pyŏn Byun Byon Pyun Byoun Pyon Pyoun Pyeon
Bo Po Boh Poh
Bok Pok Pock Bog Pog Bock
Bokho Pokho Pockhoh Boghoh Poghoh Bockhoh
Bong Pong Bhong Bohng Pohng Vong
Bu Pu Boo Bou Poo Booh Buh Pou Pooh
Bi Pi Bee Pee Bih Bhi Pih Phi
Bin Pin Been Pihn Phin Bean Bihn Pean
Bing Ping
Buyeo Puyŏ
Sa Sah Sar
Sagong Sakong Sagoung Sakoung
San Sahn Sarn
Sam Sahm Sarm
Sang Sahng
Seo Sŏ Suh Surh Su Sur So Seoh
Seomun Sŏmun Suhmun Suhmoon Seomoon Somoon
Seok Sŏk Suk Sok Suck Sek Such
Seon Sŏn Sun Son Suhn Sen
Seonu Sŏnu Sunwoo Seonwoo Sonu Sunoo Sunwou Seonwu Sonwu
Seol Sŏl Sul Seul Sol Sull
Seob Sub Subb Sup Seop
Seong Sŏng Sung Soung Song Shèng
So Soh Sou Sow
Son Sohn Soun
Song Soung
Su Soo Sooh
Sun Soon
Seung Sŭng Sung
Si Shi Shie Shee Sie Sea See
Sin Shin Shinn Sheen Seen Sinn Cynn
Sim Shim Seem Sheem Sihm
A Ah Ar
An Ahn Arn Aan
Ae Ay Ai Ea
Ya Yah Yar
Yang Ryang Lyang
Eo Ŏ Uh Urh Eoh
Eogeum Ŏgŭm Eokeum Okeum Okum Ukeum Ugeum Ukum Uhgeum Uhkuem
Eom Ŏm Um Uhm Oum Ohm
Yeo Ryeo Yŏ Ryŏ Yu Yo Yeu Yuh Yoh
Yeon Ryeon Yŏn Ryŏn Youn Yun Yon Yeun Yeoun Yuhn
Yeom Ryeom Yŏm Ryŏm Yum Youm Yeum Yom Yeoum
Yeop Yŏp Yeob Youb Yub Yup Yob
Yeong Yŏng Young Yung
Ye Yeh
O Oh Oe Au Ou Awh
Ok Ock Ohk Oak Og Ohg Oag Ogh
On Ohn Ohnn
Ong Ohng Oung
Wan Warn
Wang
Yo You
Yong Ryong Lyong
U Woo Wu Ou Wo Uh
Un Woon Wun Whun Wuhn
Won Wŏn Weon Woen Wone Wun One Worn Warn
Wi Wee We Wie
Yu Ryu Yoo You
Yuk Ryuk Yook Youk Yug Yuck
Yun Yoon Youn Yune Yeun
Eun Ŭn Ehn Enn Unn En Un
Eum Ŭm Um Em Yeum Uem
I Ri Yi Lee Rhee Ree Reeh Ee Rie Rhie
In Ihn Yin Inn Lin Ean
Im Rim Lim Yim Leem Rhim Eam
Ja Cha Jar
Jang Chang Jahng Jhang Zang
Jeon Chŏn Jun Chun Chon Cheon
Jeom Chŏm Jum
Jeong Chŏng Chung Jung Joung Chong Cheong Choung
Je Che Jae Jea Jei Jhe
Jegal Chegal Jaegal Jekal Jeagal Jikal Chekal
Jo Cho Joe Joh Jou
Jong Chong
Jwa Chwa Joa Choa
Ju Chu Joo Choo Chow Jou Zoo Jew Zu
Jeung Chŭng Jung Cheung Chung
Ji Chi Jee Gi Chee Gee Jhi
Jin Chin Jeen Gin
Cha Ch'a Char Chah
Chang Ch'ang Chahng
Chae Ch'ae Chai Che Chea Chay
Cheon Ch'ŏn Chun Chon Choun
Cho Ch'o Chu Chou Choh
Choe Ch'oe Choi Che Choy Chwe Chey
Chu Ch'u Choo Chou Chyu
Tak T'ak Tark Tag Tack Tahk
Tan T'an Tahn Tann
Tae T'ae Tai Tay Tea Thae
Pan P'an Pahn Phan Parn Pann
Paeng P'aeng Pang Paing Peng Peang
Pyeon P'yŏn Pyun Pyon Pyoun Pyen
Pyeong P'yŏng Pyung Pyong Pyoung Pyeng
Po P'o Pho Poh Paul For Four
Pyo P'yo Phyo Pio Peo Pyoh Pyou
Pung P'ung Poong Puhng Poohng
Pi P'i Pee Phee Phi Phy Pih Fee
Pil P'il Phil Peel Fill Feel
Ha Hah Har
Hak Hag Hahk Hahg Hack
Han Hahn Hann Hanh
Ham Hahm Hamm Haam Harm
Hae Hay Hai Hea
Heo Hŏ Hur Huh Her Hu Ho Hoh Heoh
Hyeon Hyŏn Hyun Hyon Hyoun
Hyeong Hyŏng Hyung Hyoung Hyong Hyeung
Ho Hoh
Hong Houng Hoong Hung
Hwa Howa Hoa Wha Hua
Hwang Whang Whong
Hwangmok Whangmock Wangmok
Hwangbo Hwangpo Whangpoh
Hu Hoo Hooh Huh
));

my @family_names_vietnamese =
(qw(
Nguyễn Nguyen Trần Tran Lê Le Phạm Hoàng Hoang Huỳnh Huynh Vũ Võ Vu Vo Phan Trương Truong
Bùi Bui Đặng Dang Đỗ Do Ngô Ngo Hồ Dương Duong Đinh Dinh Ái An Ân Bạch Bành Bao Biên Biện
Cam Cảnh Cảnh Cao Cái Cát Chân Châu Chiêm Chu Chung Chử Cổ Cù Cung Cung Củng Cừu Dịch Diệp
Doãn Dũ Dung Dư Dữu Đái Đàm Đào Đậu Điền Đoàn Đồ Đồng Đổng Đường Giả Giải Gia_Cát Giản Giang
Giáp Hà Hạ Hậ Hác Hàn Hầu Hình Hoa Hoắc Hoạn Hồng Hứa Hướng Hy Kha Khâu Khổng Khuất Kiều Kim
Kỳ Kỷ La Lạc Lại Lam Lăng Lãnh Lâm Lận Lệ Liên Liêu Liễu Long Lôi Lục Lư Lữ Lương Lưu Mã Mạc
Mạch Mai Mạnh Mao Mẫn Miêu Minh Mông Ngân Nghê Nghiêm Ngư Ngưu Nhạc Nhan Nhâm Nhiếp Nhiều
Nhung Ninh Nông Ôn Ổn Ông Phí Phó Phong Phòng Phù Phùng Phương Quách Quan Quản Quang Quảng
Quế Quyền Sài Sầm Sử Tạ Tào Tăng Tân Tần Tất Tề Thạch Thai Thái Thang Thành Thảo Thân Thi Thích
Thiện Thiệu Thôi Thủy Thư Thường Tiền Tiết Tiêu Tiêu Tô Tôn Tôn_Thất Tông Tống Trác Trạch Trại
Trang Trầm Trâu Trì Triệu Trịnh Từ Tư_Mã Tưởng Úc Ứng Vạn Văn Vân Vi Vĩnh Vũ_Văn Vương Vưu Xà
Xầm Xế Yên Yến
));

# Return the supplied full/given/family name with the case fixed

sub namecase
{
	my $name = (@_) ? shift : $_;
	my $mode = (@_) ? shift : 'full';
	my $given_names = shift;

	# Without a name, do nothing
	return undef unless defined $name;

	# Uppercase at start of word (after space, apostrophe, or hyphen)
	$name = lc(nametrim($name));
	$name =~ s/\b(\w)/\U$1/g;

	# Lowercase after apostrophes that follow more than one letter (e.g. Oso'ese but not O'Brien)
	$name =~ s/(?<=\w{2}|$apostrophe\w)($apostrophe\w)/\L$1/g;
	# Lowercase after apostrophes that follow one letter that isn't O, V or D
	# (e.g. T'ang, but not O'Brien or d'Iapico or v'Rachel)
	$name =~ s/(?<=\b[^ODV])($apostrophe\w)/\L$1/g;

	# Uppercase after "Mc" and "Fitz" ("Mac" is done selectively with built-in exceptions)
	$name =~ s/\b(Mc|Fitz)(\w)/$1\U$2/g;

	# Lowercase some grammatical/aristocratic/patronymic prefixes.
	# Note: This should only be done for family names because
	# "Van" is also a Vietnamese given name which is fixed below.

	# Family name prefixes

	if ($mode ne 'given')
	{
		# French/Italian/Spanish/Portuguese: d', dall', dell', de', de, de la,
		#   del, dela, dels, della, delle, dal, dalla, degli,
		#   di, du, da, do, dos, das
		# Spanish/Catalan/Portuguese: y, i, e (conjunctions)
		# German/Dutch: von, zu, von und zu, van, der, ter, den, van de,
		#   van der, van den, van het, tot, 'sSomething, 'tSomething
		# Danish/Swedish/Norwegian: af, av, til
		# Welsh: ap, ab, ferch, verch
		# Arabic/Hebrew/Malaysian: ibn, bin, bint, binti, binte, ben[1], bat,
		#   mibeit, mimishpachat, el-, al-, ut-, ha-, v'
		# Zulu: ka
		# English/Scottish: of
		# Irish: Prefix case normal except: Ó hUiginn, Ó hAodha
		# Note1: "ben" is only detected when unambiguous

		$name =~ s/\b(d$apostrophe|(?:de(?: la|$apostrophe)?|del|dela|dels|della|delle|dal|dalla|degli|di|du|da|do|dos|das|y|i|e|von und zu|von|zu|van het|van|der|ter|den|tot|af|av|til|ap|ab|ferch|verch|ibn|bin|bint|binti|binte|bat|mibeit|mimishpachat|ka|of)\s)/\L$1/ig;
		$name =~ s/\b(dall|dell)($apostrophe)(\w)/\L$1\E$2\U$3/ig;     # Italian: dall'Agnese
		$name =~ s/((?:^|\s)${apostrophe})([st])(\w)/$1\L$2\U$3/ig;    # Dutch: 'sGravesande
		$name =~ s/\b($irish_o_re )(h)($irish_vowel_re)/$1\L$2\U$3/ig; # Irish: Ó hUiginn
		$name =~ s/\b(el|al|ut|ha)(?=$hyphen)/\L$1/ig;                 # Arabic/Hebrew: el- al- ut- ha-
		$name =~ s/\b(v)(?=$apostrophe)/\L$1/ig;                       # Hebrew: v'Rachel
		$name =~ s/^(ben\s)/\L$1/i if $mode eq 'family' || index($name, ',') != -1; # Hebrew: ben if family
		$name =~ s/(?<=\s)\b(ben)\b(?=\s)/\L$1/i if $name =~ / v$apostrophe| ha$hyphen(?:Kohein|Levi|Rav)\b/; # Hebrew: ben if v' or ha-

		if ($mode eq 'full' && %namecase_exceptions_full)
		{
			my $kcfull = kc($name);
			$name = $namecase_exceptions_full{$kcfull} if exists $namecase_exceptions_full{$kcfull};
		}

		if ($mode eq 'family' && defined $given_names && %fnamecase_exceptions_full)
		{
			my $kcfull = kc($name . ', ' . $given_names);
			$name = $fnamecase_exceptions_full{$kcfull} if exists $fnamecase_exceptions_full{$kcfull};
		}
	}

	# If this is a full name, the given name is either after a comma
	# or at the start. Fix "van" there.

	if ($mode eq 'full')
	{
		my $has_comma = (index($name, ',') != -1);
		$name =~ s/, van\b/, Van/ if $has_comma;
		$name =~ s/^van\b/Van/ if !$has_comma;
	}

	# With some exceptions (builtin ones and user-supplied ones)

	if ($need_case_update)
	{
		%namecase_exceptions = map { kc($_) => $_ } @namecase_exceptions unless %namecase_exceptions;
		$namecase_exceptions_re = join '|', keys %namecase_exceptions;
		$need_case_update = 0;
	}

	$name =~ s/\b($namecase_exceptions_re)\b/$namecase_exceptions{kc($1)}/ieg;

	return $name;
}

# Return the supplied given name(s) with the case fixed

sub gnamecase
{
	my $given_names = (@_) ? shift : $_;

	return namecase($given_names, 'given')
}

# Return the supplied family name with the case fixed

sub fnamecase
{
	my $family_name = (@_) ? shift : $_;
	my $given_names = shift;

	return namecase($family_name, 'family', $given_names);
}

# Add a case exception (family-wide or individual)

sub namecase_exception
{
	my $name = shift;
	return 0 unless defined $name;

	$name = nametrim($name);
	return 0 unless length $name;

	my $has_comma = (index($name, ',') != -1);
	my $kcname = kc($name);

	if ($has_comma) # Individual exception
	{
		my ($f, $g) = split /, /, $name;
		my $kcnatural = kc("$g $f");

		$namecase_exceptions_full{$kcname} = $name;
		$namecase_exceptions_full{$kcnatural} = $name;

		$fnamecase_exceptions_full{$kcname} = $f;
	}
	else # Family-wide exception
	{
		%namecase_exceptions = map { kc($_) => $_ } @namecase_exceptions unless %namecase_exceptions;
		$namecase_exceptions{$kcname} = $name;
	}

	$need_case_update = 1;
	return 1;
}

# Split exceptions hash. Keys are foldcase full names in
# ambiguous form ("Given Family"). Values are unambiguous.

my %namesplit_exceptions;

# Return the supplied full name as "family_name, given_names", guessing if
# necessary, which part of the supplied full name is the family name, and
# which part is the given name or names. It's reasonably good at identifying
# family names containing grammatical constructions (i.e.,
# aristocratic/patronymic) in various languages, but if that doesn't work,
# trickier names that can't be programmatically determined can be added to
# the namesplit_exceptions hash to specify the correct name splitting for
# specific individual names. Many names require this. The letter case of the
# result is also corrected via namecase().

my $ja_loaded = 0;

sub namesplit
{
	my $name = (@_) ? shift : $_;

	# Without a name, do nothing

	return undef unless defined $name;
	return '' unless length $name;

	# Prepare the name for matching (any normalization must have already been done)

	$name = nametrim($name);
	my $kcname = kc($name);

	# Lookup exceptions first

	$name = $namesplit_exceptions{$kcname} if exists $namesplit_exceptions{$kcname};

	# Accept existing commas

	return namecase($name) if index($name, ',') != -1;

	# Load hash of family name starter words

	%split_starter = map { kc($_) => 1 } @split_starter unless %split_starter;
	$split_starter_re = qr/(?:@{[join '|', keys %split_starter]})/i unless $split_starter_re;

	# Load family name hashes/regexes for Chinese, Korean, Vietnamese

	if (!scalar %family_names_ck)
	{
		%family_names_ck =
			map { $_ => 1 }
			@family_names_chinese,
			grep { /\p{Hangul}/ } @family_names_korean;
		$family_names_ck_re = qr/(?:@{[join '|', keys %family_names_ck]})/;
	}

	if (!scalar %family_names_ck_roman)
	{
		%family_names_ck_roman =
			map { (kc($_) =~ s/'/$apostrophe/r) => 1 }
			grep { !/^$split_starter_re$/ }
			@family_names_chinese_roman,
			@family_names_korean_roman;
		$family_names_ck_roman_re = qr/(?:@{[join '|', keys %family_names_ck_roman]})/i;
	}

	if (!scalar %family_names_v_roman)
	{
		%family_names_v_roman = map { kc($_) => 1 } @family_names_vietnamese;
		$family_names_v_roman_re = qr/(?:@{[join '|', keys %family_names_v_roman]})/i;
	}

	# Identify Vietnamese names (before Dutch names)

	my ($f, $g) = $name =~ /^($family_names_v_roman_re) (.+)$/;
	return namecase("$f, $g") if defined $g;

	($g, $f) = $name =~ /^(.+) ($family_names_v_roman_re)$/;
	return namecase("$f, $g") if defined $g;

	# Identify plausible multi-word family names (in Latin scripts)

	my @words = split / /, $name;
	return namecase($name) if @words < 2 && $name !~ /^[\p{Han}\p{Hangul}\p{Hiragana}\p{Katakana}]+$/;

	for my $i (1..$#words)
	{
		my $kcstarter = kc($words[$i]);
		next unless exists $split_starter{$kcstarter};
		next if $kcstarter eq 'ben' && $name !~ / v$apostrophe| ha$hyphen(?:Kohein|Levi|Rav)\b/i; # Hebrew
		next if $kcstarter eq 'bean' && $name !~ /\bbean $irish_post_bean_re\b/i; # Irish
		next if $i == $#words;

		--$i if $i > 1 && $kcstarter =~ /^[yi]$/i; # Spanish/Catalan
		return namecase(join(' ', @words[$i..$#words]) . ', ' . join(' ', @words[0..$i - 1]))
	}

	# Identify Chinese, Korean, and Vietnamese family names (and some misidentified Japanese names) :-(
	# Note: When romanized, these family names can appear first or last

	($f, $g) = $name =~ /^($family_names_ck_re)(.+)$/;
	return "$f, $g" if defined $g;

	# Note: Family names can appear first or last. Luckily, for Chinese,
	# the two given name characters are usually romanized as a single word,
	# so there's less chance of misinterpreting a given name as a family
	# name. Unfortunately, Korean names are romanized as separate names,
	# all of which might look like a family name, so it's likely that the
	# name that appears first will be recognized as a family name, even
	# if the real family name is at the end (in English-speaking places).
	# This can only be fixed with split exceptions (or by encouraging
	# Koreans to not put their family name last).

	($f, $g) = $name =~ /^($family_names_ck_roman_re) (.+)$/;
	return namecase("$f, $g") if defined $g;

	($g, $f) = $name =~ /^(.+) ($family_names_ck_roman_re)$/;
	return namecase("$f, $g") if defined $g;

	# Identify Japanese names

	if ($name =~ /^[\p{Han}\p{Hiragana}\p{Katakana}]+$/)
	{
		if (!$ja_loaded)
		{
			require Lingua::JA::Name::Splitter;
			$ja_loaded = 1;
		}

		local $SIG{__WARN__} = sub {}; # Suppress warnings
		($f, $g) = Lingua::JA::Name::Splitter::split_kanji_name($name);
		return join(', ', grep { length } $f, $g);
	}

	# Assume a single-word family name
	# Note: Non-hyphenated multi-name family names must be handled via split exceptions

	return namecase($words[-1] . ', ' . join(' ', @words[0..$#words - 1]));
}

# Add a split exception

sub namesplit_exception
{
	my $name = shift;
	return 0 unless defined $name;

	$name = nametrim($name);
	return 0 unless length $name;

	my $has_comma = (index($name, ',') != -1);
	return 0 unless $has_comma;

	my ($f, $g) = split /, ?/, $name;

	if ("$f$g" =~ /^[\p{Han}\p{Hangul}\p{Hiragana}\p{Katakana}]+$/)
	{
		my $natural = "$f$g";

		$namesplit_exceptions{$name} = $name;
		$namesplit_exceptions{$natural} = $name;
	}
	else
	{
		my $kcname = kc($name);
		my $kcnatural = kc("$g $f");

		$namesplit_exceptions{$kcname} = $name;
		$namesplit_exceptions{$kcnatural} = $name;
	}

	return 1;
}

# Like namesplit() but returns the name as a list containing
# two items: the family name followed by the given names.

sub nameparts
{
	my $name = (@_) ? shift : $_;

	return () unless defined $name and length $name;

	return split /, ?/, namesplit($name), 2;
}

# Format a full name in Eastern or Western name order as appropriate

sub namejoin
{
	my ($f, $g) = @_;

	return $f if !defined $g;
	return $g if !defined $f;

	return "$f$g" if "$f$g" =~ /^[\p{Han}\p{Hangul}\p{Hiragana}\p{Katakana}]+$/;
	return "$g $f";
}

# Trim the supplied name

sub nametrim
{
	my $name = (@_) ? shift : $_;

	return undef unless defined $name;

	return $name
		=~ s/^\s+//r            # Remove leading spaces
		=~ s/\s+$//r            # Remove trailing spaces
		=~ s/\s+/ /gr           # Squash multiple spaces
		=~ s/($hyphen) /$1/gr   # Remove space after hyphen
		=~ s/ (,|$hyphen)/$1/gr # Remove space before comma and hyphen
		=~ s/,(?! )/, /gr;      # Add space after - if missing
}

# Normalise internal hash keys and data with the supplied normalization function

sub normalize
{
	my $func = shift;

	$apostrophe = $func->($apostrophe);
	$hyphen = $func->($hyphen);
	%namecase_exceptions = map { $func->($_) => $func->($namecase_exceptions{$_}) } keys %namecase_exceptions;
	%namecase_exceptions_full = map { $func->($_) => $func->($namecase_exceptions_full{$_}) } keys %namecase_exceptions_full;
	%fnamecase_exceptions_full = map { $func->($_) => $func->($fnamecase_exceptions_full{$_}) } keys %fnamecase_exceptions_full;
	$namecase_exceptions_re = $func->($namecase_exceptions_re) if defined $namecase_exceptions_re;
	%namesplit_exceptions = map { $func->($_) => $func->($namesplit_exceptions{$_}) } keys %namesplit_exceptions;
	@split_starter = map { $func->($_) } @split_starter;
	$split_starter_re = $func->($split_starter_re) if defined $split_starter_re;
	%split_starter = map { $func->($_) => 1 } keys %split_starter;
	@irish_o = map { $func->($_) } @irish_o;
	$irish_o_re = '(?:' . join('|', @irish_o) . ')';
	@irish_vowel = map { $func->($_) } @irish_vowel;
	$irish_vowel_re = '(?:' . join('|', @irish_vowel) . ')';
	@irish_post_bean = map { $func->($_) } @irish_post_bean;
	$irish_post_bean_re = '(?:' . join('|', @irish_post_bean) . ')';

	%family_names_ck = map { $func->($_) => 1 } keys %family_names_ck;
	$family_names_ck_re = qr/(?:@{[join '|', keys %family_names_ck]})/;
	%family_names_ck_roman = map { $func->($_) => 1 } keys %family_names_ck_roman;
	$family_names_ck_roman_re = qr/(?:@{[join '|', keys %family_names_ck_roman]})/i;
	%family_names_v_roman = map { $func->($_) => 1 } keys %family_names_v_roman;
	$family_names_v_roman_re = qr/(?:@{[join '|', keys %family_names_v_roman]})/i;

	@family_names_chinese = map { $func->($_) }  @family_names_chinese;
	@family_names_chinese_roman = map { $func->($_) }  @family_names_chinese_roman;
	@family_names_korean = map { $func->($_) }  @family_names_korean;
	@family_names_korean_roman = map { $func->($_) }  @family_names_korean_roman;
	@family_names_vietnamese = map { $func->($_) }  @family_names_vietnamese;
}

# Reset internal data (for test coverage purposes)

sub _reset_data
{
	%namecase_exceptions = (); # This is the only one that matters (initialized in two places)
	%namecase_exceptions_full = ();
	%fnamecase_exceptions_full = ();
	$need_case_update = 1;
	$namecase_exceptions_re = undef;
	%split_starter = ();
	$split_starter_re = undef;
	%family_names_ck = ();
	$family_names_ck_re = undef;
	%family_names_ck_roman = ();
	$family_names_ck_roman_re = undef;
	%family_names_v_roman = ();
	$family_names_v_roman_re = undef;
}

1;

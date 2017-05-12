package Lingua::ZH::ChineseNaming;

use 5.006;
use strict;

use Carp;
our $VERSION = '0.02';
require Exporter;
our @ISA = qw/Exporter/;
my $CHARS;
my %STROKEDB;

sub is_Big5_CHAR {
    local $_=shift;
    1 if /^[\xA4-\xC5][\x40-\x7E]/o || /^[\xA4-\xC5][\xA1-\xFE]/o ||
        /^\xA3[\x40-\x7E]/o || /^[\xA4-\xC5][\x40-\x7E]/o ||
            /^[\xA4-\xC5][\xA1-\xFE]/o;
}


sub loadchar{
    my $i = 1;
    foreach my $s (split /\n/, $CHARS){
	foreach ( grep {$_} split /\s/, $s ){
	    $STROKEDB{$_} = $i;
	}
	$i++;
    }
}

sub strokes{
    [ map { $STROKEDB{$1} } $_[0]=~/(..)/og ];
}

sub analyze{
    my (%arg) = @_;
    my (%ch);
    my ($fn, $gn) = ($arg{FAMILY_NAME}, $arg{GIVEN_NAME});
    my ($stfn, $stgn) = (strokes($fn), strokes($gn));
    no strict;
    my (%handle) = (
	22 => sub {
	    %ch = (
		   heavenly => $stfn->[0] + 1,
		   personal => $stfn->[0] + $stgn->[0],
		   earthly => $stgn->[0] + 1,
		   external => 2,
		   general => $stfn->[0] + $stgn->[0] + 2
		   );
	},
	24 => sub {
	    %ch = (
		   heavenly => $stfn->[0] + 1,
		   personal => $stfn->[0] + $stgn->[0],
		   earthly => $stgn->[0] + $stgn->[1],
		   external => 1 + $stgn->[1],
		   general => $stfn->[0] + $stgn->[0] + $stgn->[1] +1
		   );

	},
	42 =>  sub {
	    %ch = (
		   heavenly => $stfn->[0] + $stfn->[1],
		   personal => $stfn->[1] + $stgn,
		   earthly => $stgn + 1,
		   external => 2,
		   general => $stfn->[0] + $stfn->[1] + $stgn->[0] + 1
		   );

	},
	44 =>  sub {
	    %ch = (
		   heavenly => $stfn->[0] + $stfn->[1],
		   personal => $stfn->[1] + $stgn->[0],
		   earthly => $stgn->[0] + $stgn->[1],
		   external => $stgn->[1] + 1,
		   general => $stfn->[0] + $stfn->[1] + $stgn->[0] + $stgn->[1],
		   );
	    
	},
    );
    (%arg, $handle{length($fn).length($gn)}->($fn, $gn));
}

sub hexagram{
    my (%arg) = @_;
    my (@ba_gua) = qw/qian dui li zhen xun kan gen kun/;
    my (@yinyang)=qw/--------- -x------- ----x---- -x--x----
	-------x- -x-----x- ----x--x- -x--x--x-/;
    my $stgn = strokes($arg{GIVEN_NAME});
    my ($upper, $lower) = ( $arg{general} % 8,  ($stgn->[0] + $stgn->[1]) % 8 );
    (%arg, ( hexagram => $ba_gua[ $upper ]." over ".$ba_gua[ $lower ],
	     diagram =>
	     join qq/\n/, map{ s/x/ /o;$_ }
	     map { $yinyang[$_] =~ /(...)(...)(...)/o; $1,$2,$3 } $upper, $lower));
}

sub new{
    my($pkg) = shift;
    my(%arg) = @_;
    my %r;
    $r{FAMILY_NAME} = $arg{FAMILY_NAME} or croak "Family name?";
    $r{GIVEN_NAME}  = $arg{GIVEN_NAME}  or croak "Given name?";
    loadchar();
    %r = analyze(%r);
    %r = hexagram(%r);
    bless \%r, $pkg;
}



1;

$CHARS=<<EOF;
¤@ ¤A
¤P ¤Q ¤N ¤C ¤G ¤R ¤K ¤D ¤I ¤M ¤F ¤L ¤S ¤E ¤B ¤O ¤H ¤J
¤e ¤y ¤| ¤} ¤q ¤b ¤s ¤g ¤r ¤] ¤j ¤Y ¤c ¤i ¤m ¤n ¤U ¤a ¤k ¤T ¤h ¤z ¤p ¤{ ¤x ¤\ ¤w ¤^ ¤V ¤f ¤` ¤_ ¤X ¤o ¤d ¤t ¤u ¤~ ¤[ ¤Z ¤v ¤W ¤l
¤é ¤£ ¤Õ ¤¤ ¤ë ¤¡ ¤í ¤ç ¤¼ ¤Ø ¤Ã ¤ï ¤ê ¤¥ ¤Ô ¤¦ ¤è ¤» ¤¸ ¤Í ¤á ¤Ì ¤« ¤¹ ¤Î ¤¶ ¤ò ¤õ ¤Ó ¤Ç ¤ý ¤÷ ¤Æ ¤Ù ¤ö ¤ô ¤Þ ¤¬ ¤ß ¤ü ¤­ ¤¢ ¤À ¤Ü ¤º ¤® ¤ú ¤È ¤× ¤Û ¤± ¤ø ¤° ¤Å ¤Ú ¤Á ¤Ò ¤Ý ¤¯ ¤ª ¤à ¤Ä ¤â ¤´ ¤¾ ¤½ ¤ù ¤ð ¤û ¤É ¤Ï ¤· ¤î ¤§ ¤ä ¤ó ¤Â ¤Ë ¤ì ¤© ¤ã ¤¨ ¤å ¤æ ¤Ð ¤Ö ¤µ ¤² ¤Ñ ¤¿ ¤³ ¤Ê ¤ñ
¥Æ ¥¸ ¥J ¥I ¥D ¥½ ¥a ¥r ¥U ¥µ ¥¦ ¥B ¥n ¥´ ¥^ ¥Þ ¥Â ¥« ¥k ¥h ¥[ ¥C ¥Á ¥s ¥¯ ¥± ¥j ¥Ý ¥Ê ¥¢ ¥_ ¥ª ¥¤ ¥} ¥Ú ¥© ¥Ã ¥Ü ¥¾ ¥° ¥§ ¥x ¥c ¥b ¥A ¥e ¥~ ¥\ ¥¶ ¥q ¥É ¥v ¥ß ¥E ¥u ¥Ô ¥Ä ¥» ¥F ¥g ¥G ¥Ó ¥f ¥Ï ¥W ¥£ ¥È ¥¿ ¥Õ ¥Ò ¥Í ¥· ¥¡ ¥À ¥` ¥l ¥Ë ¥× ¥Q ¥m ¥{ ¥p ¥H ¥X ¥Ð ¥Z ¥y ¥Ö ¥® ¥M ¥¼ ¥Ñ ¥¥ ¥N ¥¬ ¥O ¥] ¥Ç ¥º ¥@ ¥t ¥i ¥R ¥Å ¥Û ¥d ¥w ¥T ¥o ¥Ì ¥² ¥S ¥Î ¥Y ¥V ¥K ¥z ¥Ù ¥P ¥| ¥Ø ¥¹ ¥­ ¥¨ ¤þ ¥L ¥³
¦¸ ¦b ¦E ¦´ ¦O ¦Q ¦` ¦Y ¦Ì ¦à ¦ä ¦Î ¦¬ ¦¦ ¦Ê ¦u ¥ú ¦C ¦V ¥í ¦Ç ¦È ¦x ¥õ ¦Ò ¥è ¥á ¦z ¦® ¦Ã ¦U ¦¡ ¦¶ ¦¼ ¦â ¦£ ¥î ¦\ ¦K ¦Å ¦Ü ¦Z ¥æ ¦Ð ¦f ¦¯ ¦R ¥ò ¦@ ¥ï ¦Þ ¦À ¦é ¦¨ ¦r ¦g ¦Â ¦³ ¦e ¥ë ¦p ¥ü ¦^ ¥÷ ¦» ¦j ¦Ä ¦¾ ¦M ¦a ¦l ¦I ¦± ¦F ¥ù ¦Ú ¦h ¦¤ ¦ª ¥ð ¦Ø ¦ç ¦B ¦á ¦n ¦× ¦Í ¦} ¥à ¥þ ¦Ï ¦° ¦Ë ¦v ¥â ¥ì ¦P ¦t ¥é ¦Ó ¥ä ¦Õ ¦] ¦X ¦ã ¦µ ¦{ ¦É ¦D ¦¹ ¦ß ¦W ¦c ¦Ý ¥û ¥ç ¦å ¥ô ¦_ ¦N ¦­ ¦è ¦T ¦y ¦¢ ¦Ñ ¦Æ ¦[ ¥ó ¦½ ¦S ¦Ù ¥ý ¦· ¦« ¦Á ¦q ¦d ¥ö ¦© ¦L ¦G ¦J ¥ø ¦~ ¦Ô ¦m ¦² ¦o ¦§ ¦º ¦æ ¦k ¥ê ¦A ¦i ¥ñ ¦¥ ¥å ¦w ¦H ¦| ¦Ö ¦Û ¥ã ¦¿ ¦s
§Ç ¨r ¨· §b §@ ¨_ §N §¤ §a ¨H §¡ §Ö ¦ë ¨E ¨» §Ú §Ñ ¨b §÷ ¨° ¨N §Þ §Õ ¦ï §Ü ¨f ¨y §e ¨t ¨z ¨d §ì ¨½ ¨K §¹ ¨X §Ë ¨¾ §G §h §þ §á §§ ¨R §â §^ §] §³ §R §V §Y §æ ¨¡ ¨m §û ¨q §O §ê §E §K ¨¸ ¦û §ñ §ò §¼ ¨C ¨­ ¨j ¨T §å §r ¨w §q ¨L §F §L §S ¨¢ §ß §î §À §Ä §é §m ¨c ¨¬ §p §C ¨i ¦ø ¦î ¨e §ø ¦ñ §Ð ¦õ §Ô ¨u §± ¨« ¨D §W §º ¨[ §í ¨Á §Ï §~ ¨¯ ¨s ¨Â §j ¨U §½ §¶ §c §¿ ¨v ¨W §° ¨¼ ¨\ §} §Ã ¨S §J §Ý §i ¨B ¨¹ §x §È ¦þ §D ¨³ ¨` §Ó §ª §Ù §P ¨n §X §u §« §ó §à §£ §T ¨§ §´ ¨ª ¨A §¦ §{ ¨o §ä ¨h §ô §Í §o §ï ¨F ¨Z ¨¦ ¦ô ¨À ¨J ¦ð §[ §è ¨M §Î §ù ¦÷ ¨{ §Å ¨P §® ¨£ §f §_ §É §» ¨O §l §· ¨¤ ¨µ §w ¨} ¨² §t §¬ ¨I §M ¨© ¦ù §| ¦ý ¨a ¨~ §µ ¦í §I §Ø §Q §© §ý §A ¦ó §Ò §¥ §ë ¨@ §ã ¨¶ §n §¾ §ð §U §y §Z ¦ê §z ¨º §× §­ §õ §s ¨V §¯ §Æ §ö ¨g §\ ¦ö §Û §ç ¨G §` §d §¢ §Â ¨] ¨® §k ¨± §² §ü §¸ §B ¨p ¨¨ ¨¥ ¨´ ¨l ¨Q §ú ¨x §v ¨Y ¦ò ¨k §Á §Ê ¨¿ §Ì ¦ì ¦ú ¦ü §g §¨ ¨^ ¨| §H 
ªÕ ª} ªz ªÚ ª® ©P ªf ªö ªi ªI ©ó ©ª ©ì ªb ©Y ©Ò ªÑ ªÂ ©G ©L ©¶ ©Ç ©¦ ªm ©[ ªò ©b ©_ ¨Ó ªP ¨Ë ª§ ©ð ¨ï ª¸ ¨Ì ªä ªÆ ª³ ©q ªþ ©Ë ªJ ©Ä ©³ ¨ú «A ªu ªú ¨ó ª´ ©e ©´ ©¥ ¨æ ªí ©M ©© ªÏ ©Á ªé ©s ©û ©{ ¨Ù ªB ©h ª] ªT ©\ ©¡ ªY ©÷ ¨ð ª¿ ¨È ©n ¨Ï ªF ¨Å ª· ¨ä ¨ê ¨ô ª£ ©¢ ªS ©Ø ©ï ªß ©ë ªË ©¯ ªp ©K ©â ©g ¨à ©ñ ¨Ô ¨Í ©µ ªµ ªá ©¹ ¨þ ©T ©m ªÁ ªõ ¨Ð ª~ ¨û ©` ©U ªÅ ©Õ ªL ªû ©H ©x ©ö ©D ªñ ªH ©õ ªt ªl ªÌ ¨ý ¨ò ªc ©Ù ©« ª» ¨Ø ©¾ ©° «@ ¨î ©O ªQ ªÝ ª© ªø ªç ªÒ ªK ©Î ¨÷ ©Â ©è ªG ¨ç ªâ ©¸ ª­ ªî ªU ©ô ©z ©r ª\ ©~ ©w ©í ªh ¨ß «D ªÈ ªX ©é ©Æ ªo ªÙ ¨Ç ©c ª° ªq ©Ê ©J ©å ©V ª¼ ©Ý ©} ªÞ ªÖ ªg ªê ¨ë ©a ©á ©C ªV ¨É ©d ©ã ©ê ©þ ¨ã ªR ¨í ªD ¨Ñ ©¨ ªü ©A ªO ª« ©£ ¨Õ ª± «C ¨è ¨ñ ¨ø ªC ©­ ª` ª¡ ©Ô ©v ªÜ ©E ©ú ªÀ ªk ©Ì ©k ªx ©Ð ©ù ©ý ¨× ªº ©N ªæ ª¤ ©l ©¼ ¨Û ª¨ ª[ ©] ¨Ê ©Ö ©W ©· ©Þ ªÉ ªô ©¿ ©Q ªã ©Ñ ©» ªÓ ªÄ ¨Ü ªØ ª¬ ¨Æ ª_ ©Ú ©Z ªd ©S ª@ ªr ©¬ ©§ ªë ©Ã ©ç ©p ª{ ©Í ª× ©± ©É ©I ©¤ ©f ©Å ª½ ªÛ ª¯ ªn ©Ó ©^ ªÃ ©j ªó ©X ©à «B ¨â ªE ©i ©B ¨é ªª ªj ªy ©@ ªÊ ªå ¨ì ª÷ ¨Ö ªï ª² ©Ü ªW ¨ö ªN ª¹ ªÐ ¨Ú ©F ©È ©× ªÇ ªv ªù ªè ªa ªw ©Ï ©² ª¦ ¨Þ ªý ©t ªs ©y ¨Ã ¨å ªÍ ¨ü ¨ù ª^ ©ü ©u ¨õ ª¶ ©½ ©ä ªð ©æ ¨Î ©ß ªÔ ©Û ©ø ªe ªì ªÎ ©º ª¾ ©o ©| ©î ¨Ò ©R ª| ª¢ ªà ©® ¨á ªA ¨Ý ªM ¨Ä ©ò ©À ªZ ª¥
­z «¥ ¬_ ­X ¬´ ¬æ ¬b ¬C «O ­T ¬é «ð ­w ¬î «Ò «Æ ¬m «û ­~ ¬Ü «u ¬÷ ¬N ¬® «Ö ¬q ¬j ­s ¬Ù ¬` «N ¬ª ­² ¬V ­D «| «H «h «S ­» ¬g ­­ ¬H ¬¸ ¬K «Û «ä ­j «¹ «w ­± «P ¬Í «Ã ­m ­^ «È «l «° «X ­Q ¬Õ ­· ¬à «v «i ¬r «ã ¬\ ­W ­C «ô ­G «× «t ­d «E ¬Å «ß ¬â ­n ¬ö ¬} ¬n «ì ¬É ¬Ã ¬Ñ «n ¬[ «Ú ¬¿ «´ ­i ­Z «¡ ¬w «è «b «x «® ­L ¬D ¬{ ¬p ¬A ¬ø ¬Î ¬i «Ä ­y ­P ¬F ­a «c «Ü ¬ò «M ¬­ «Õ ¬í «© ¬l «í «¢ ¬õ «I ¬Ø ¬À «F ­o ¬¡ ¬f «q ¬W ­k ­_ ¬ß ¬¼ «ñ ¬I «\ ¬Ö «Ì «¾ ­e «Ç ­v «_ «r ¬a ¬è «Ø ­¢ «Y ­¸ ¬S «¯ ¬ã ¬× ¬± ¬X ­® ¬] «£ «ú ¬P ­U «k ­[ ¬¥ «R «] «³ ¬s «é ­r ¬Â ¬© ¬ñ ¬O «­ ­B «Ñ «{ «Q «Á «à «½ «Ë «J «ª ­¦ ¬v ­E ¬å ­ª ¬| ­A ¬ù ¬ó ¬z ­l «ç «` ¬E ¬u ¬ü «j ­K «Ù «f ¬Ð ­] ­R «Ô «¦ ­´ ­F ¬ô ­p ­Y «y ¬½ «² ¬Ï ¬Ó ¬ë ¬ú «· «ê ¬@ ­V ­| «p «å «î «ý ¬y ¬² ¬¢ ¬Þ ¬Û ¬§ «ù «U «õ «Å «ò ¬° «g «Þ ­« ­b «Ï ¬Q «Z ¬R «¼ ¬Y ­q ¬T ¬ð ¬¤ «á «¬ ¬Ê ¬Æ ­u ¬Ý «¤ ¬L «æ «Ð ¬c ¬ä «¨ ­{ ¬¨ ­x «z «d ¬· ­§ ¬¬ ­\ ­O ¬e ­£ ­f «a ¬Z ­} «À ¬B ¬» ­J ­t «ø ­¹ ¬t ¬ê ¬ï «Î ¬¯ ­¥ ¬J «ó «} ¬Ò ­³ ­¬ ­¨ ­¯ «^ ­I ¬û «K «º ­` «o ¬µ ­S «« «ö ­º «â ­c ¬^ ¬¦ ­µ ¬£ ­¶ ¬« ­h «Ê ¬x ¬ý ¬Ú ­g «É «V ­© «µ ¬Ì «± ¬Ë ­¤ «Í ­° ¬Ô «ü ¬³ ¬d «T ¬¹ «¿ ¬U «Ó ¬h «¸ «÷ ¬¶ «[ «þ ¬o ­¡ «G «~ ¬ç «¶ ¬Ç «Â «ï ¬º ­@ ¬k ¬Ä «W ¬ì ¬Á ¬¾ «Ý ¬~ ­N ­M ¬á «» «e ¬G «§ ¬È «m ¬M «s ­H «L «ë
°P ®ð ¯Å °l ®ä ¯± ®{ ®C ­â ¯¸ °I ®¦ ¯Ý ¯E ®b ­Î ¯F ¯Ð °W ®À ¯Þ ®¬ ¯^ ®´ ­Ü ®Ç °] ®P °ª ­¿ °Z °F ®³ °¡ ¯û ®ë °u ­ß ¯n ®© ®v ®Ó °¦ °M ®ö ¯s ¯O °f ®Ï ®Ë ¯£ ®M ®q °m ¯· ­Ê ¯R ¯m ®ï ¯X ¯| ­Ö °b ¯[ ­ï ­Ó ®ú ¯ä ¯É ®× ­Û ¯t ®½ ­ô ®ì ®X ®V ®| ®¹ ®d °g °S ­Ç ¯© °¬ ¯A ®° ®Ø °B ¯µ ¯Á ¯ç ­Â ¯y ¯r ¯q ¯ï ¯Ø ®â ¯i ®G °r ¯½ ¯S °x ¯ì ¯Ü ¯­ ®p ®å ­Ì ­à °w ®N ®Þ ®g ¯{ ®¨ ®z °p ®¿ ®ù °© ®m ®¢ ®B ®U °E ®D °V ­Ø °H ¯« ­Ñ ¯j °O ®Æ °^ ­ð ®c ¯\ ¯M ®ê ®» ®w °{ ®Z ¯¾ °§ ­÷ ­À ­í ®§ °¢ ¯Ö ¯§ °X ¯Ï ­¼ ¯Â ®Ð ­æ ®Ö ®ó °Y ­ü ¯Ë ®] ¯ö °¥ ®÷ ®² ¯Ó ®¼ °­ ®Ã ¯Ì ¯@ ¯ð ¯h °R ¯º °\ ¯x ®n ¯´ ¯Ù ¯~ °c ¯Ú ®¯ ¯í ­ö °q ¯d ®þ ®á °n ¯è ¯² ¯T °¨ ­Ô ¯¡ ¯Ä ®¤ ¯¦ ®j ®ô ®Ý ­Í ®Q °¤ ¯â °h ¯È ¯å ¯ú ­ó ¯N ¯® ®Y ­Å °t ¯á ­å ­Æ ®µ ­× ­ñ ¯_ ®^ ¯ª ®¸ ®A ¯H ®f ®æ ¯Û ¯] ®Ù ¯Ã ®¾ ®ò ®ø °_ ­ì ¯³ °z ­Ë ¯é ¯¨ ®K ®Ñ ¯¶ ®O ¯ê °| ­ù ®E ®y ®È °i ­Õ ®é ¯Z °A ­û ®h °~ ¯u ®¡ ¯L ¯¤ ¯l ®ý ®R °U ¯õ ­Ð ®t ®Â ¯Ç ¯Y ®î ®Ä ¯¯ ¯C ®Ì ¯Ô ­á ¯U ®s °G ®« ®à ¯ý ­ò ®® °K ¯V °d ­é ¯G ¯¢ ­½ ­ë ­Ý ¯k ®Ú ¯g ®_ ¯Æ ®~ ­Ä ¯¿ ®õ ®Õ ¯÷ ¯à ¯w ¯K ¯Q ¯Ò ¯z ¯c ¯o ­Á ®¶ ­ä °s ®H ®` °D ¯Ê ­þ °N ¯` ®Ü ­É °£ ®k °k ¯¹ ¯Î ®T ¯I ¯ë ¯b °` °@ ®Á ®¥ ¯f ®ñ ¯ô ®L ­ý ®Î ¯ò ®ç °e °y ­õ ¯¥ ®S ®x ®É °J ¯a ®J ¯» ¯þ °« ®} ¯Í ¯e ­î ®i ­ú ­Ï °j ®ª ®ü ¯ñ °} ­Þ ®è °Q ­¾ °[ ¯v °T °L ®Å ®í ®o ®Ê ¯Ñ ­ã ¯J ¯} ®u ¯D ¯Õ ­è ­Ò ®· ¯ù °a ¯ø ®û ¯î ®\ ­ø ®e °v ®[ ®­ ¯W ­È ¯ß ®º ®Ò ¯¬ ®± ¯ü ¯À ®r ­Ú ®Í ®Ô ¯P ®ß ¯ã ¯p ­Ã ¬þ ¯¼ ®W ¯° ­ê ¯ó ¯æ ­Ù ¯× ®a ­ç ¯B ®Û ®£ ®ã °o °C ®F ®l ®@ ®I 
±Ô ±õ ±^ ³G ²Ë ±K °Ó ±á °Û ³u ²Æ ±Ë °Å ³³ ²¨ ±Ï ³R ³B ²l ±X °ç ²ì ³A °þ ³½ ²ã ³L °÷ ²Â ²¾ °É ±N °² ²è ±® ±h ³O ²û °µ ²ø ²A ³c °¸ ³ª ³§ ²| ±Ä ³¼ ²× ²Õ ±¬ ±[ ²­ ²ß ±A ²´ °ô ²ö ³¤ ²H °à ±t °ò ³i ±Ø ±¹ ±F ³{ ³r ±½ ²e ±} °Ë ³\ ²º ±a ³m °ï °æ °Ö ²¤ ³Á ²· ³· ²D ³| ±Õ ±¼ ±k °Ú ²Ñ ±E ²ó ²i ³_ ²b °ë °Î ³~ °´ °¹ ²O ±í ±Ù °® ±Q ±è ²» ²X ±à ±ü ±ô ±´ ±Ñ °À ³d ³¯ °Ü ²² ²q ²S ±Å °ý ²³ ²W ±¶ ²õ ²© ²ò ±¦ ±O °× ³y ²Å ±ê ±å ±© °± ²y °Ô ³¦ ±d ³H ²Ü °» °ú ²È ²ä ²Á ±Ê ±] ±ó ³V ²à ²þ ³´ ²r ³U ±ø ³M °Æ °Þ ³» ²½ ²° ±Ü °û ³] ³o ³@ ±p ³£ ±Ð ±| ²{ ²K ±Y ±G ±L ²c ²¹ °ó ²¯ ²ç °Ò ±­ ³b ±¢ ±² ²Ö ±þ ³l ²Ý ²@ ±q ³© ³h ±g ²f ²G ²ï ²Ò ±j °³ ²® ±³ ³¶ ±R ³z ³v ±` ³® ²x ±¾ ±~ ±· ³¢ °Ï ±ð °ü ³s ³g ²÷ ³Â ±U °å ²u ±\ ±Ò ³° ±B ²m ±v °î ³Y ±È ³D ³} ±û ²R ²Ç ²N ±â °¿ °ê ²Ø ²¸ ³± ²ª ²V ³J ³I ±ò ±÷ °ä ±ª ²î ±Í ³p ³Q °Ý ±¥ °Õ ±m ±É ±S ²ñ °â °Ã ³k °¼ ²À °Ç ±æ ²± °ö ±C ²ô ²[ ±° ±¡ °¾ ±{ ²á ±µ ³Z ²ý ²¡ ²d ³n ±± ²¥ ±ë ²« ±Ý ²ú °ì ²É ±Â ±M ±w ²J ²Ó ±Ö °Ø ²s ³¬ ²¼ ±c ²\ ²ê ³¥ ²Q ²w ²j ±Z ±r ±Û ±H °º ²Ù ²I ²v °Í ³X ²ù ²` ²n ±V ²å ±Ã °Ð ±¨ ³¿ ³a ²M ²C ±ú ²Ï ²Î °· °° ±f ²~ ²Ä ³º ±¤ ±z ²U ±¿ ²¶ °é ±Þ ²_ ³w ³f °È ³­ ³µ °ù °¶ °í ²ë ±Ç °ñ ²g °Â ²í ±Ó ±ï ±ã °á ±ç °Ù ³E ²é ²§ ²Ì ³² ²t ±ö ²ð ³C °Ê ±J ²Z ³[ ±T ±s ³S ±n ³¾ °è °ß ±Î ³F °Ä ±u ±Ì ³j ³N ²F ²â ±i ²Þ ³` ²k ²¢ ±¸ ²P ³¡ ±× ±Á °¯ ±x ³K ²¬ ³t ³P ²¦ ±ý ³¨ ±ì ±_ °ð ±D ²] ²µ ²Ê ±I ³e ±@ ±b ²£ ²Y ²o ±º ±À ±o ±§ ³¸ ²æ ²Ô ³« °õ ±î ³À °½ ±£ ±« ²T ±Ú ²Û ²} ²Ð ²L ±¯ ±ä ³x ²¿ °Ñ ±ß ²Í ²h ²B ±é ²Ã ±y ±Æ ³T ³¹ °ø ±ù ²p ²^ ²E °Á ²ü ³q ±e ±» ³^ ²Ú ²z ±l ²a ±W ³W ±ñ °ã °Ì ±P 
µÆ ´f ¶F ¶b ´k ³ç ´ô ´y µå ´o µ] µÊ µ{ µH µº ¶{ ´® µr ´¡ µT ´ø ´Ï ¶¨ ´u µ§ µ\ ´Ò ¶µ ¶² ´_ ³à ³ý µÇ ´Z µÙ µi ´ý ´¥ ¶N ´ñ ´ú ´E ³ò µ´ ´K µû µá µ© ¶G ´T µø ´~ µ½ ³Ó ¶­ ´ù ´Ê ¶Q µô ´È ´Ó ³Õ ¶m µX ´P µÒ ¶¡ µb ³ø ´» ³Þ ³Ï ³ä µü µA ´x µm µì µÖ µÝ ´@ ¶i µµ µY ¶Á ¶| ³Ç ¶u ´í ¶] ´¤ ¶A µð µÄ ´Ë ´Î ´¹ ´æ ¶c ³Ë ´ç ´N µl ³ì ¶» µK ´© ´R ´z ´[ ¶¥ µæ ¶E ´r ³è µ¯ ´Ú ´G ¶_ µÔ ´á ´n µÎ ´Ã µâ ³É µª µú µ¨ ¶@ µÚ ´W µS µc µÞ ´þ ´Ð µó ¶M µE ´Ý ´Y ´¼ ´° ³Å µp µw ¶H µö µÅ ´U µ± ´÷ ³û µ¡ ¶± ¶n µÕ ´± ´F ¶¾ ´¦ µz ¶P ´å ³ß ¶X ´Ø ¶Â µU ³Ù ³ñ µë ³ã ³Ð ¶h ´C µ¹ ´{ ³ú ¶¤ ´t µ` ¶¸ µÑ ³Ô ¶¬ ´b ´c ´ê ´­ ¶w ¶I ´Ì ´Æ µv ´â ³÷ µ~ ³È ³Î ´ò ´À ¶Y µO ´û ´¶ µ÷ µ¶ ´Þ µÉ µg ¶© ¶t ¶d µÁ ³í µJ ¶´ µs µï ´Ô µ¤ µ® ¶p ´ó ¶^ ³Ì ³é ¶z ´Ç µ° ´H ´ä µ¢ ³Ê µo ¶` µÓ ¶k µî µx ´è µk ³Ã ³å µê ³× µ« µt ¶ª ´½ µç µÛ ´ö ³Û ¶v ¶S ¶¿ ´M ³â µß ¶s µã ´m ´î ¶W ´¯ ´´ ´j ´Í ´Q ´· µF µý µy µd µÀ ³ô ¶° ³ö ¶L ¶j ´^ ´h ´Ü ´Ù µe µÌ µÈ µB ¶x ³Ñ µÍ ³Ö ´§ ´Å ´ë µV ´a ´à ¶O ¶À ´ï ´B ´g ¶~ ¶y ¶D ¶¹ ¶V µI ¶o µ² µ¥ ´¿ ¶[ ´| ¶J µ[ µ} ³ð ´³ µh ³Ú ´Õ ´d ³Í ´l µ£ ´q µ_ µ· ´J µC ´é µØ µ¼ ´Ñ µQ ¶g µÐ µò ¶e ³î ´¬ ¶q ¶£ ´V µN ´Á ´S ´e ³Ò ´º ´ü ³ê µÜ µu ´I µ­ ¶· ¶§ µ^ ¶Z ´i ´² ´Û µÂ ³õ µP ´¸ µè ´L ¶¼ µþ ¶« ´` ¶R ´O ´ß µË ´ã µä µ| µ@ µ³ ¶® ³æ ³ù ´p ´õ ¶K µ¬ ´D ³ó µ¦ µf ´Ö ¶T µq ´] ¶³ µj ´µ µà ³þ ³Ý µ¿ ´¨ ´¢ ´¾ ´× ¶¢ ¶} µD ¶C µa ³ï µõ ´} ´A ¶f ´ì µn µL ³Ü ¶¦ ´v µÏ µé ´s ´É ¶\ µñ ¶r ³ü µÃ ´£ µW ¶½ ¶¶ ³Æ ¶¯ µí µ¾ ³á µM µ¸ ´w ´\ ³Ä ´X µ» ¶U ´Â ´« µù ³ë µ× µR ¶l µG µZ ´ª ¶B ³Ø ¶a ´Ä ¶º ´ð 
¶× ¸¥ ·E ¸L ¹A ·ª ·@ ¸Ç ·{ ¸Ü ¸º ·X ¸¾ ¶Ê ¹C ·î ¸õ ·ü ·ú ¹S ·õ ¸á ¸E ¹} ¹w ·r ¹N ·ó ¶ã ¹X ·Ã ¸Í ¹^ ·± ¶Ü ¸Ê ¹¥ ¹Z ¸Ô ¸ª ¶ç ·O ¶ü ¹s ¸\ ·¬ ¸î ·Ý ·S ·ä ·Û ·Ï ¸® ¸P ¸x ·¶ ·Ö ¹F ¸Ö ·i ¸@ ¶â ¸² ·À ¶ê ¸p ¸Y ·¢ ¶ä ¶ô ¸J ¸U ¸© ·C ¹D ¸Ñ ¸ù ¸· ·þ ¸Ä ·n ¹g ·Ê ¸K ·× ¶ú ·~ ¸S ¹© ¹a ¶û ¸h ·Ì ¹I ¸Á ·s ¸û ¸¢ ¸­ ¶Ô ·R ·d ·ë ¸F ·¦ ¸c ·H ¹c ·] ¶Ñ ¶ë ·Ô ¹K ¸Î ¸¹ ¸A ¶Ì ·` ¸n ¸k ·° ¸Û ¶Ý ·á ¹T ·» ¸g ·§ ¶Ú ·è ¹G ·ù ·í ¶ï ¶æ ·Ð ¹O ¶Õ ¸¡ ¶É ·v ¹r ¹l ¸r ¸Æ ·´ ¸| ·A ¶ó ¸ä ·q ¸q ¸_ ¶î ¸« ¹¤ ·D ¸m ¸O ·F ¹] ·ò ·| ·« ¸Z ·e ·Þ ·T ¹p ¸é ¹i ¶è ¸Ð ¸Â ·É ¹@ ¸ï ¸± ¸I ¶ö ·z ¹k ¸V ·Æ ·· ·h ¸{ ¹W ·ý ¶ò ¸í ¸Å ¸w ·I ·­ ¶á ·Ø ¶Í ¸à ¸ø ·c ¶Æ ·o ·â ¸¬ ¸T ¸× ¶ù ¸¤ ·N ·t ¶ý ¹L ¹¦ ¸å ¶È ¹` ·º ¹b ¸¦ ·å ¸è ¶Ò ·Y ·£ ¹o ¸ü ¹x ·¿ ¸` ¶Ù ¶þ ¸Ã ¸Ï ¸ó ·k ¸d ¸µ ·L ¹£ ¸b ¸} ¶Ï ·Q ¶í ·u ¹P ¸ì ¸ê ·È ·Ë ¶ø ·¯ ¸N ¹\ ¶Þ ¶é ·¸ ¹{ ¹V ¸° ¶Å ¸R ·ß ¸j ¸¸ ¸s ·³ ·µ ¶Ö ¸Ù ¹u ¸[ ·J ·¾ ¹H ¶å ·ñ ¸É ¶ñ ¸B ¶Ø ¸æ ·y ¶à ¸Ì ¸z ¸¯ ¸¼ ·p ·é ·U ·Ñ ¸ð ¸W ¸v ¹z ¸÷ ¸Þ ¸» ·Í ¸H ¶Î ·¹ ¹ª ¸Ó ·ø ¹h ·Ù ¹y ¸Ø ·_ ¸ý ¸a ·Â ¹e ¸D ·Å ¸ß ¸t ·\ ¸¿ ·Z ·¤ ¸§ ¹B ·b ¹~ ¶Ç ¹j ¸o ·x ·¨ ·ð ¹J ·W ¹¢ ¹t ·ï ·© ¸Õ ·Ó ·Ü ¸y ¶Û ·ô ·^ ¶Ã ¹| ¸ö ¸â ·ã ¹§ ·æ ¹E ·K ¸£ ¹[ ¸ç ·l ·² ¸´ ¸e ·M ·½ ¹v ¹_ ¸ñ ¸] ¸È ¸½ ¶Ó ¹M ¸Ë ¸~ ·Õ ¹f ·j ·g ¸Ú ¹R ¶ß ¹n ·Ç ·® ·ö ¸Q ¹Y ¸ô ·m ·P ¸ë ¸¶ ¶õ ¶ì ¸ò ·V ¸³ ·¡ ¶Ë ¸¨ ¹¨ ¹m ¸ú ¸À ¸l ¶ð ¸G ¹U ¸X ·a ¶÷ ¸i ·Ä ·Î ¶Ð ¹q ¸Ò ·à ·ì ·f ·G ·Ò ¸Ý ¹d ·ç ¸M ¸f ¹Q ¸C ·B ·û ·÷ ¸ã ·} ·ê ¸^ ¹« ¸þ ·Á ·[ ·Ú ¹¡ ·¼ ·w ¸u ¶Ä ·¥ 
»ä ¹º ºÀ ¹ò »J ºá ¹É ºL ºh ¹¿ ºZ »¼ »\ ºP »¾ ¹Ä ºF »Ã »· »é ºl º÷ ºU »ß ¹û »´ ºì »y »W ¹â ºð ºÓ º° ºc ¹ß »Ô ºÚ ºÇ ºK »u º] ¹Ø ºw »Í ºô ºz »n ºÌ º¹ ¹® º³ ¹µ ºC ºû ºÈ »G º¢ »e º` ¹è »ð »D »Ñ »ó ¹¬ »[ ºè ºÙ ¹Ï »Ö º¯ º~ »l »j ¹ó »ì ¹Æ ºä º× »© ¹é ºs »q »R ¹ø ¹þ º¿ ¹Ü »} ºª »Ý ¹î »à »° »ª º¥ ¹Õ º´ ºg ºT ºp »¸ ºº »z »Û ºt ºé »Ä ºö ¹å »Ï ºË ¹È ¹Å ºS »Þ ºk ºç »­ »~ ¹° ¹ï º^ »¥ »¿ »` »v º¡ »t ºà ºÄ »P ¹¶ ºJ »E »S ¹± ¹Þ ºú ¹Ð »g »Ø º¦ ¹Ó ºf º² º® º} »³ ºy »Ü ºï ¹ô »Z ºÔ º· ¹Û ºG ºo »@ »¤ º© »_ »ê »d ¹ü »¡ ¹Ì »Ó ºò ºN »p ºÝ ¹À »É »¶ »í »ã ¹õ ¹­ ºã »O º[ »ô »× »Ð »¯ ¹» ¹´ ¹ê »Æ º¾ »À »¨ »T º¤ º_ ºþ ¹· »k »º »Å ¹ä ºÊ »f ¹Ñ »Ú »¬ ¹Ý ¹ð ºW »Y ºÂ »ñ »¦ ºn ºù ¹ë ºõ ¹Â ºÛ »¹ ºÅ ¹Ú »Ë »s »Q ºI º» ¹ç ¹¼ ºÕ ºæ »w º@ ¹× »Ò º§ »Ì ºe »ë ºí ¹Ê ¹Ô ¹¸ º| º­ ºD º\ »A »h »B »ç º½ ¹³ ºu ºb »â »È ºx ¹ù ºX »H ¹á º¨ º± »K ¹Á ºq ºÏ »½ ºÁ »{ »î ºO ºâ »c ºÞ ºi ¹ö »£ ¹æ º¶ »^ ºÐ ºê »å »o »Ç »U ¹Í ºå »µ ºÃ »| »Á »b ºM ¹ñ ºë »Â ºQ ºÜ ºY »x »M »± ºø ¹ì ¹ý ¹¾ ¹Ã »§ ºñ »² ºA ºó ¹Ò ¹¯ ¹Ù »F ºv »® ºÆ »» »« »] »Ê ºV º¸ »N ºH »i ºÒ »ò ¹ã ¹Ë ¹½ ºm ºý »a ¹à º« ºÑ ºü »Ù ¹ú »ï º¬ ºµ ¾R ºÍ º{ »æ ºa º£ ¹÷ ¹¹ »Õ ºE ºÉ ºd ºß »V ºR ¹Ç ºÖ »I »X ºB »m ¹Ö ºî ºÎ »è »L »C ºj ¹í ºØ »¢ ¹² ¹Î º¼ »á »Î »r ºr 
½Q ¼ô ¼{ ½W ¾v »ö ½ª ¼ý ½¯ ¼@ ¾d ¼« ½Ü ½Ë ¼Õ ¼m ½¶ ¾b ¼¤ ¾¡ ½v ¼É ¼¢ ½à ¼Ù ¼º ½{ ¼Å ¼¿ ¾D ½G ½¡ ¾U ¼ñ ¼_ ¼µ ¼X ¼Q ¼~ ½Ö ¾n ¼» ½Ð ¼ì ½ì ½M ¼ø ¼æ ½N ¼x ½¥ ½ç ¼F ½² ¾p ¾B ¼g ½Ò ¼H ¼G ¼¾ ½ñ ½A ¼t ¾u ½Ý ¾i ¾Y ½Ç ¼ò ¾o ¼ê ¼n ½d ½« ½` ¼M ¼¯ ¼Ô ¼s ½õ ¼Þ ¾z ¼c ¾H ¼ð »ú ½u ¼Ë ¼§ ½í ½z ½n ¼U ½Â ½û ¼i ½R ¾} ¾c ¾Q ½½ ½g ¾] ½· ½è ½Û ¼Â ¼ó ¼é ¾_ ¼R ½° ¾[ ½ß ¾{ ¼Ú ¼þ ¼® ¾g ½S ½L ¼å ½Ê ½ä ¼À ¼A ¼[ ½º ½Ô ¼O ½y ¼¶ ½¦ ¾F ½Õ ¼á ¼P ¼÷ ½Ï ¾l ½l ½¢ ½@ ½X ¼· ¼Ì ¾\ ½» ¼² ½ö ¾K ¼ï ¼Ò ½o ¼ª ¼L ¾C ¾O ¼ë ¼f ¼ä ½e »ø ½¬ ¼| ½k ¼Ó ¾h ½¾ ½ò ½a ½ë ½Ñ ½Æ ½E ½F ¾X ½± ¾V ½P ¼u ½\ ¼° ½h ½I ½§ ¾~ ¾¦ ¾P ¼o ¼K ¼Ð ½Á ¼T ¼Ý ½ü ½t ¼£ ¾q ¼] ¼p ½á ¾M ¾^ ¾f ¾Z »û ½Z ¼r ¼¸ ½T ¾I ¼Ã »ý ½¸ ½ê ¼W ¼Ü ¼­ ½} ½¿ ¼v ½É ¾£ ¼Ç ¼à ½î ¾x ½_ ½Ä ¼ú ½ý ¼û ½~ ½Ú ½÷ ½¨ ¾¤ ¼S ¼y ¼³ ¼Z ¼e ¼î ½x ½Î ½È ¼E ½Y ¼â ½s ¾t ½ï ¼è ¼± ¼Í ¾G ¼j ¼Ê ¼Æ ¼× ¼k ¾k ¾@ ½B ¼¼ ¾m ½O ¾a ½Å »÷ ¼J ½­ ¼} »õ ½K ½´ ½b ¾N ¼^ ¾S ½¼ ¾r ½] ¼Á ¼ß ½Ø ¾W ¾J ½£ ½p ½w ¼¬ ½å ¼a ½ó ½ù ¼Ñ ¼¦ ½i ¾¥ ½D ½© ½V ½r ¾e ½[ ¾¢ ¾E ½^ ½| ½¤ ¼¹ ½µ ¼Î ¼Y ¼l »ü ½U ¼Ö ¼q ¼õ ½Ã ¼© ½â ½é ¼\ ½Í ¼B ¼Ä ¾L ¼d ½þ ½Ù ¾y ¾w ¼ù ½c ¼Û ¼Ï ¼D ½j ½H ¾` ¾T ¼¡ ½Ì ¼´ ¼w ¼¨ ¼I ½m ¼Ø ½¹ ½J ½f ½ô ¼C ½q ½Þ ¼¥ ½× ½ø »ù ¼ã ½® ¾j ¼ü ¼½ ½Ó ¼V ¾s ¼N ½³ ½ð ¼` ½æ ¼ç ¼ö ½ã ¼b ¼í ¾| ¼È ½C ½ú ¼h »þ ¾A ¼z ½À 
¿~ ¿ý ¾Ý ¿R ¾¶ ¿k ¿x ÀO ¿µ ¾Á Àh ¿È ¾Ð ¾¼ ¿L ¿} ¿T ¿ð ¾ò Àe ¿\ ¾ú Àr À@ ¿à ¾· ÀG ¿X ¿¦ ¾ª ¿A ¿ú ¾ó ¿Ù ¿¿ ¿q ¿Ã ¿H ÀS ¿Ö ¿G ¾À ¿£ ¾è ¾Ö ÀA ¾ä ¿W ¿ì ¾ì ¾Ì ¿Ý ÀD ¿­ ¿d ¿Ñ ¾ô ¾Ø ¿¹ ÀP ¿K ¿E ¿´ ÀK ¿¯ ¿u ¿¼ ÀX ¾­ ¿[ ¾É ¾Å ¾Ñ ¿í ¾µ ¿ç Ào ¿a ¿É ¿N ÀN ¿þ ¾© ¿÷ ¿z ¾Ü ¿Ç ¾° ¾Ï ¿À ¿p ¾ý ¿² ¿½ ¾Ê ¾ë ¾ñ ¾î ¿f ÀU ¿O ¾¸ ¿ó ¾Ä ¿¶ ¿M À^ ¿Ü ¿§ ¾á ¾Â ÀY ¿Õ ¿@ ¿S ¿¢ Àb ¿m ¾´ Ài ¿Ô ¿é ¿ù ¿V ¿« ¿¤ ¾½ ¿i ÀC ¿Ì ÀJ ÀF ¿Ò ¿j ÀT ¾Í ¿Í ¾õ ¿è ¾ê Àp ¾ç ¿Z ¿` ¾× ¿ã ¾þ ¾å ¿y ¾Ó ¿î ¾¬ ¿P ¾æ ¿® ¿ø ¿ü ÀL Àf ¿Ê ÀQ ¿J ¿¡ ¿v ¿Û À_ ¾Ã ¾¯ ¾ø ¿F ¿å À[ ¾Û ¿{ ¿o ¿Ï ¿Þ ¿º ¾Ú ¾ð ¿_ Àc ¾¾ ¿c ¿s ¿ô ¾ü ¿â Àt ¿C ¿Ø ¾² ¿¨ ¾Î ¾é ¿ß ¿Ë ¾³ ¿I ¾à ¿¾ À` ¿· À\ ¿Ó ¾¹ ¿± ¿õ ¾Ç ¾ö ¾¨ ¿h ¿Î ÀI ÀV ¾ù ¿Ð ¿Á ¿ò Àj ¿ä ÀE ÀB ¿Æ ¿ê ¾Ô ¿ª ÀH ¿ï ¿û À] ¿» ¾® ¿| ¾÷ ¿Y Às ¿b ¾« ¿Â ¿á Àl ¾ã Àq ¿× ÀW ¿^ ¾û ¿l ¿] ¾Ù ÀZ ¿e ÀR ¾» ¿¥ ¿Ä ¿Ú Àg ¾È ¿r ¿¬ ¾Þ ¾¿ ¿³ ¾ï ¿Å ÀM ¿B ¾â ¾Õ ¿¸ ¾§ Àm ¿t ¾ß ¾º ¾í ¾Æ ¿D ¿ñ ¾± ¿ö ¿U ¾Ë ¿Q Àn ¿n ¿° ¿æ ¾Ò ¿g ¿w Àk ¿ë Àa ¿© Àd 
ÀÏ Áª ÁZ Á² ÁÔ ÁÓ Áù ÁÛ Áq Áõ ÁÝ Á_ ÁÌ À¡ Á~ Àº ÁÏ Á` ÀÒ Á¶ Áñ Àµ Áë Áß Ád ÀÅ ÀÀ Áà ÁÈ ÂC Á® ÁS ÀÊ Á× Ái Àë À½ Áw ÂF ÁÀ ÂË ÁO Àê ÂM Át Àâ Àö Àw À¦ Àõ ÂB Á] ÁJ Áï Àü Àï ÀÉ Ác À¯ Àæ ÀÐ Áº ÁÄ ÁE À× À´ Á­ ÁF Áã Á§ Àå À{ ÂI Á½ Àì Áì Á¹ À¤ Àª Á¦ Áþ Áô À¸ Á± Ág ÁT À¨ Áø ÁÕ ÁM ÁW Àû ÁÇ Àù ÁR Á[ Áá Àé ÀÓ Àñ Áh ÀØ Àô Á÷ ÀÁ Áò Á¥ ÁA Ál ÁQ ÀÆ Á{ Àá À¾ ÁÃ Áv ÁË Á¡ À§ Áo À£ Àã Áè ÁN ÀÝ ÀÚ Áî À® ÁK Áû ÁÅ Àv Áí Àî Áç Á^ Àu ÂL ÁØ Áp Àí Á¿ ÁG Àz À³ Áb À¼ Àó ÂH ÀÔ Àø Á° À© ÂA ÀÍ Ày Á¢ ÂN ÀÌ À} Áf Àð ÀÜ ÀÑ Àç ÁH Áy ÀÕ Áµ Á} À~ ÁÆ ÀÄ Á\ Án Àß Áö ÀÇ Ám À· Àè Àà Áå À¿ ÀÛ ÁX À± ÁB Á¾ ÁÖ Áó ÁÙ ÂK ÁÊ Áü ÂE À­ ÁÐ Áz Ák Á| Áú ÀÎ Ás ÂG ÁP ÁU ÀÃ Á¸ ÀÙ Àä À² À« Áæ Á³ ÁÜ Á© À° ÂD À¶ Á¬ ÂJ ÀË Á£ Á· ÀÖ ÁÍ À¥ Á» Áê ÁI Á« Áx Áé À¢ Áa Á¯ À¬ Á´ ÁÒ ÀÞ Áð ÁÂ ÁÉ Á¤ Á@ ÁÁ ÁÑ Áj ÀÈ Áâ ÁC Áý Áe Àú ÁÚ ÁÞ Àx ÁD À» Áä ÁÎ ÁY ÀÂ ÁL Á¼ Á¨ Àý Àò Àþ ÁV À¹ Áu À| À÷ Ár Â@ 
ÂÏ Âk Ã@ Âä ÂÍ ÂÖ Â¼ ÃS ÃB Â¸ Âc ÂÓ ÂS ÂÁ Ã^ Âó Âh ÂU Â} Â² Âý ÂX ÂÆ ÂÎ Â× Âø Âá Âw ÂÕ Âs Âô Âß ÂP ÃX ÂÞ ÃD Âp Â\ ÂÂ Âû Â° ÃT Ã] ÂÝ Â¾ Âo Â¿ Âe ÃP ÃN Âb Â¢ Â¬ Âò Â« ÂZ ÃL Âa ÂY Â¤ Âè Âü Âë ÃF Â· ÃH Âv Â| Âñ Â¦ Âî Â§ Ây ÂÅ ÃZ Ââ Â© ÂÒ Âº Âu ÃV ÃJ ÂÑ ÂÛ Â^ Â³ ÃW Â[ Â± Â÷ Âg Â_ Âl Â] Âï Ât ÂÈ Âù ÂÀ Â½ ÃA Â® Âö Âf Âz ÂÔ Âí Âi Âj Â¹ Âú Âd Â» ÂØ ÃE ÃU ÂÐ ÂÚ ÂT Âq ÂR ÂÃ ÃR ÂQ ÂÌ Âà ÃY Â­ Â¶ Ân ÂW Âµ Âç Ã\ Â£ Â¡ Âð Â{ ÂÊ Âê ÂO Âª Âþ Â¨ Âõ Âæ Â~ ÂÇ Âx ÂÙ ÃM Â¥ ÃQ Ã[ ÃG ÂÜ Âì ÂÄ Âã Âé ÃI Â´ Âr Â¯ Â` ÃC ÃK ÂÉ Âm ÃO ÂV Âå 
ÃÙ ÃÎ Ãk Ã° Ãa Ãò ÃÂ ÄQ ÃÛ ÃÔ Ã´ Ã÷ Ãð ÃÞ Ã¸ Ãé ÄC Ãâ Ã¯ ÄM Ã¡ Ã¶ Ãà Ãp Ãø Ãl ÃÜ Ãë ÄP Ã² Ãy Ã¥ ÃÀ Ãá Ã× Ãf Ã~ Ã§ Ãì ÄJ Ã¬ Ãõ ÄL Ã| ÄN Ã£ Ãb ÄS ÃÌ Ã¾ ÃÉ Ãå Ãi Ãµ Ã¨ Ãç Ãú Ãª ÃÒ Ãü ÃÆ Ã{ Ã¼ Ãw ÃË ÄH Ãu ÄE Ãö Ãe ÄF Ã¹ ÃÏ ÄT Ãæ Ãó ÃÃ ÃÝ Ãh ÃØ ÄO Ãù Ã` ÃÐ Ão ÃÚ Ã½ Ãm ÄB Ä@ Ãî Ãñ Ãj ÃÕ Ãq Ãô Ã· Ã_ Ãº ÄD Ãß Ã® Ãþ Ãã Ã± ÃÄ Ãg Ã» ÄV Ãr ÃÁ Ã¤ Ãx Ãs Ãè Ãv ÃÅ ÄI Ã¢ ÃÍ ÃÈ Ã} Ã­ Ãz Ã³ Ã¦ ÃÖ Ãt Ã« Ãû Ãd ÄR Ãä Ãê Ã¿ Ã© Ãc Ãn ÃÇ ÄA ÃÑ Ãï Ãý ÄG ÃÊ ÄK Ãí ÃÓ 
Ä° Ä§ Ä^ Ä¯ Ä~ ÄÄ ÄY Äs Ä_ Äv ÄÐ Ä¾ Ä¸ Ä| Ä¥ Ä¡ Ä® Äy Ä· ÄÃ Äh ÄÈ Ä¼ Ä[ ÄÇ ÄZ ÄÌ Äº Ä{ Ä\ Äj Äa ÄÅ ÄÀ Ä© ÄU ÄÕ Äe ÄÆ Ä´ Ä¬ ÄÒ Äp Äw ÄX Ät Ä² Ä¿ ÄÁ ÄÉ Ä³ Äc ÄÊ ÄÑ Äb Äl ÄË Ä± ÄW Äk ÄÎ ÄÓ Äg ÄÍ Ä« Äo Äª ÄÏ Ä¤ Äx Äm Ä¦ Ä¹ Äµ Ä¨ Äq Ä` Ä] Äu Ä¶ Äz Ä» Är Äi Äf Ä£ Ä¢ ÄÔ Än ÄÂ Ä­ ÄÖ Ä½ Äd Ä} 
ÅF Äï ÄÜ Å` Äî ÅZ Åc ÅE Äâ ÅW Ä÷ Äá Å] Å_ Å\ ÄÙ Äà Äõ Åa Äó ÅO ÅC ÅI Äð ÅX Äý ÄØ ÄÝ Å[ ÅY ÅG Äì Äü Åf Äæ Åd Äþ Äê Äñ Äë Äè Åb Äã Äù ÅP Åe Äô ÅK Ä× ÅQ Äé ÅL Äß Äç ÅA ÅB Åj Åi ÅM Å@ Åg ÄÞ Äò ÄÛ ÅD ÅS Äú ÅR ÅN ÄÚ Äö Äû Å^ ÅH Ää ÅU Äå Äø ÅT Äí ÅJ ÅV Åh 
Å¡ Å¦ Åv Åz Åt Å½ Åk Å¸ Å³ Å¬ Å¯ Å¢ ÅÄ ÅÆ Åp Å· Å® Åy Ås ÅÃ Å¶ Åq Å{ Å¹ Å° Å² Å£ Å| Å´ ÅÁ Åm Å« ÅÀ Ål Å~ Åu Å¿ Å} Åº Å± Åw Ån Å¨ Åµ Å© Å­ ÅÅ Å§ ÅÂ År Å¼ Å¾ Å¤ ÅÇ Åª Åo Å¥ Å» Åx 
Åâ Åê ÅÜ Å× ÅÖ ÅÉ ÅÛ ÅÒ Åä ÅÐ ÅÍ ÅÊ Åï ÅË ÅÚ Åè ÅÏ Åæ ÅØ ÅÎ Åã Åð ÅÔ ÅÈ Åå Åî Åí ÅÞ ÅÙ Åì Åá Åà Åç ÅÑ Åß ÅÝ ÅÌ ÅÕ Åé Åë ÅÓ 
Åü Åö Åõ Åú Åñ Åø Åó Åý Åô Å÷ Åþ Åû Åù Åò 
EOF

__END__

=head1 NAME

Lingua::ZH::ChineseNaming - Analyzing Chinese Names

=head1 SYNOPSIS

  use Lingua::ZH::ChineseNaming;
  my $n = new Lingua::ZH::ChineseNaming( # Chen Yuan-yuan
                                      FAMILY_NAME => '³¯',
                                      GIVEN_NAME => '¶ê¶ê'
				      );

  print Dumper $n;


=head1 DESCRIPTION

 Naming is an art and choosing an auspicious one is a
 long-standing tradition in Chinese communities. Many
 people hold firmly that to have a good name is to have
 an auspicious life.

 Analyzing and choosing a good name always uses several
 patterns, e.g. stroke-counting, Chinese-horoscope, 
 hexagrams, but there is never a scientific foundation
 for these patterns.

 Lingua::ZH::ChineseNaming avoids to be a fortune-teller,
 but only extracts the computable part of this tradition
 and tries not to be confined to any specific school of
 interpreters.

=head1 METHODS


=over 1

=item *
 new Lingua::ZH::ChineseNaming(FAMILY_NAME => HERE, GIVEN_NAME => HERE) starts analysis

    my $n = new Lingua::ZH::ChineseNaming( # Chen Yuan-yuan
                                      FAMILY_NAME => '³¯',
                                      GIVEN_NAME => '¶ê¶ê'
					    );

    then, it gives statistics like this.

      FAMILY_NAME => '³¯',    # Chen
      GIVEN_NAME  => '¶ê¶ê',  # Yuan-yuan
      heavenly    => 12,
      personal    => 24
      earthly     => 26,
      external    => 14,
      general     => 38,
      hexagram    => 'gen over li',
      chart       => '---
                      - -
                      - -
                      ---
                      - -
                      ---'

=back


=head1 ILLUSTRATIONS

=over 8

=item * FAMILY NAME

Chinese family names are mostly a single character.

=item * GIVEN NAME

comes in one or two characters.

=item * HEAVENLY CHARACTER

implies the influence of ancestry on a person.

=item * PERSONAL CHARACTER

implies one's disposition or inner attributes.

=item * EARTHLY CHARACTER

implies the relation between the environment and
person

=item * EXTERNAL CHARACTER

is combined with one's heavenly character and earthly
character, representing the external factors of one 
person.

=item * GENERAL CHARACTER

is addition of one's heavenly, personal, and earthly
characters.

=item * HEXAGRAM

is formally introduced to history in I-CHING thousand 
years ago, and is given for your own interpretation.

=back

=head1 CAVEAT

=over 2

=item * It is only for casual amusement. No practical use

=item * Characters are all encoded in Big5 for now.

=back

=head1 REFERENCE

Almost every kind of book on Chinese naming is 
written in Chinese. I list two books in English
for you reference.

=over 2

=item * Choosing Auspicious Chinese Name by Evelyn Lip

=item * I CHING, The Oracle by Kerson Huang

=back

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.


=cut

package Lingua::JA::Numbers;

use 5.008001;
use strict;
use warnings;
use utf8;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.5 $ =~ /(\d+)/g;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	ja2num num2ja num2ja_ordinal ja_to_number number_to_ja number_to_ja_ordinal
);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT, qw(to_string) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use overload 
    q("") => \&stringify,
    q(0+) => \&numify,
    fallback => 1,
    ;

sub new{
    my $class = shift;
    my ($str, $opt) = @_;
    my $val = $str ? ja2num($str, $opt) : '';
    return bless {
        val => $val,
        opt => $opt || { style => 'kanji' },
    }, $class;
}

sub parse{
    my $self = shift;
    my ($str, $opt) = @_;
    $opt ||= $self->{opt};
    $self->{val} = ja2num($str, $opt);
    $self->{opt} = $opt;
    $self    
}

sub opt{
    my $self = shift;
    $self->{opt} = {
      %{ $self->{opt} },
      @_,
    };
    # use Data::Dumper;
    # print Dumper $self;
    return $self;
}

sub numify    { $_[0]->{val} };
*as_number = \&numify;
sub get_string { num2ja($_[0]->{val}, $_[0]->{opt}) };
*stringify = *as_string = \&get_string;
sub ordinal { num2ja_ordinal($_[0]->{val}, $_[0]->{opt}) };

our $Zero = {
	kanji    => '零',
	daiji    => '零',
	romaji   => 'Zero',
	katakana => 'ゼロ',
	hiragana => 'ぜろ',
};
our $Point = {
	kanji    => '点',
	daiji    => '点',
	romaji   => 'Ten',
	katakana => 'テン',
	hiragana => 'てん',
};
our $Sign = {
	kanji     =>  {'+' => q(), '-' => '−'},
	daiji     =>  {'+' => q(), '-' => '−'},
	romaji    =>  {'+' => '+', '-' => '-'},
	katakana  =>  {'+' => 'プラス', '-' => 'マイナス'},
    hiragana  =>  {'+' => 'ぷらす', '-' => 'まいなす'},
};
our $Zero2Nine = {
	kanji    => [qw(〇 一 二 三 四 五 六 七 八 九)],
	daiji    => [qw(零 壱 弐 参 四 伍 六 七 八 九)],
	daiji_h  => [qw(零 壱 弐 参 肆 伍 陸 漆 捌 玖)],
	romaji   => [qw(Zero Ichi Ni San Yon Go Roku Nana Hachi Kyuu)],
	katakana => [qw(ゼロ イチ ニ サン ヨン ゴ ロク ナナ ハチ キュウ)],
	hiragana => [qw(ぜろ いち に さん よん ご ろく なな はち きゅう)],
};
our $Ten2Thou = { 
	kanji     => [q(), qw(十 百 千)],
	daiji     => [q(), qw(拾 佰 阡)],
	romaji    => [q(), qw(Juu Hyaku Sen)],
	katakana  => [q(), qw(ジュウ ヒャク セン)],
	hiragana  => [q(), qw(じゅう ひゃく せん)],
};
our $Hugenums = {
    kanji    => [qw(極 恒河沙 阿僧祇 那由他 不可思議 無量大数)],  # manman-shin
    daiji    => [qw(極 恒河沙 阿僧祇 那由他 不可思議 無量大数)],  # manman-shin
    romaji   => [qw(Goku Kougasha Asougi Nayuta Fukashigi Muryoutaisuu) ],
    katakana => [qw(ゴク コウガシャ アソウギ ナユタ フカシギ ムリョウタイスウ)],
    hiragana => [qw(ごく こうがしゃ あそうぎ なゆた ふかしぎ むりょうたいすう)],
},

our $Suffices = {
	kanji    => [q(), qw(万 億 兆 京 垓 禾予 穣 溝 澗 正 載), 
	             @{ $Hugenums->{kanji} }],
	daiji    => [q(), qw(萬 億 兆 京 垓 禾予 穣 溝 澗 正 載), 
	             @{ $Hugenums->{kanji} }],
	romaji   => [q(), qw(Man Oku Chou Kei Gai Jo Jou Kou Kan Sei Sai Goku),
	             @{ $Hugenums->{romaji} }],
	katakana => [q(), qw(マン オク チョウ ケイ ガイ ジョ ジョウ コウ ジュン セイ サイ),
	             @{ $Hugenums->{katakana} }],
	hiragana => [q(), qw(まん おく ちょう けい がい じょ じょう こう じゅん せい さい),
	             @{ $Hugenums->{hiragana} }],
};

our %RE_Kana_Fix = (
    SanHyaku   => 'Sanbyaku', 'さんひゃく' => 'さんびゃく', 'サンヒャク' => 'サンビャク',
    RokuHyaku  => 'Roppyaku', 'ろくひゃく' => 'ろっぴゃく', 'ロクヒャク' => 'ロッピャク',
    HachiHyaku => 'Happyaku', 'はちひゃく' => 'はっぴゃく', 'ハチヒャク' => 'ハッピャク',
    SanSen     => 'Sanzen',   'さんせん'   => 'さんぜん',   'サンセン'   => 'サンゼン',
    HachiSen   => 'Hassen',   'はちせん'   => 'はっせん',   'ハチセン'   => 'ハッセン',
);
our $RE_Kana_Fix = join("|", keys %RE_Kana_Fix);

sub num2ja{	
    no warnings 'uninitialized';
    # use bignum;
    my ($num, $opt) = @_;
    # warn $num;
    my $style       = $opt->{style} || 'kanji';

    my $zero = $opt->{zero}     ? $opt->{zero}
	         : $Zero->{$style} ;
    return $zero unless $num;
    my ($sig, $int, $fract, $exp) 
	    = ($num =~ /([+-])?(\d+)(?:\.(\d+))?(?:[eE]([+-]?\d+))?/io);
    # warn join ",", ($num, $sig, $int, $fract, $exp);
    my $scientific = sub {
        my $first = substr($int, 0, 1, '');
        $exp += length($int);
        return num2ja("$sig$first.$int$fract" . "e$exp", $opt);
    };
    my $manman = '';
    if (length($int) > 48 and $opt->{manman}) {
        if (length($int) > 96) { # Resort to Scientific Notation
            return $scientific->()
        }
        $int =~ s/(.*)(.{48})\z/$2/o;
        my $huge = $1;
        my @shins;
        push @shins, $1 while $huge =~ s/(\d{8})$//g; # idea from commify hack
        push @shins, $huge if $huge;
        my $suffix = 0;
        for my $shin (@shins) {
            if ($shin eq '00000000') {
                $suffix++;
                next;
            }
            $manman = num2ja($shin, $opt) . $Hugenums->{$style}[$suffix++] . $manman;
        }
    } else {
        if (length($int) > 72) { # Resort to Scientific Notation
            return $scientific->();
        }
    }
    my $sign        = $opt->{sign}     ? $opt->{sign} : $Sign->{$style};
    my $zero2nine   = $opt->{zero2nine}  ? $opt->{zero2nine}
		            : $opt->{daiji} >= 2 ? $Zero2Nine->{daiji_h}
	                : $opt->{daiji} == 1 ? $Zero2Nine->{daiji}
	                : $Zero2Nine->{$style};
    my $ten2thou    = $opt->{ten2thou} ? $opt->{ten2thou}
		            : $opt->{daiji} || $opt->{daiji_h} ? $Ten2Thou->{daiji} 
	                : $Ten2Thou->{$style} ;
    my $suffices = $opt->{suffices} ? $opt->{suffices}
	                : $opt->{daiji} || $opt->{daiji_h} ? $Suffices->{daiji}
	                : $Suffices->{$style} ;
    my ($seisuu, $shousuu, $beki) = ();
    my @shins;
    push @shins, $1 while $int =~ s/(\d{4})$//g; # idea from commify hack
    push @shins, $int if $int;
    my $suffix = 0;
    for my $shin (@shins) {
	if ($shin eq '0000') {
	    $suffix++;
	    next;
	}
	my $sens    = '';
	my $keta    = 0;
	# warn $man;
	for my $digit (reverse split //, $shin) {
	    if ($opt->{fixed4} or $opt->{with_arabic}) {
            $sens = 
                ($opt->{with_arabic} ? $digit : $zero2nine->[$digit])
                . $sens;
	    } else {
            my $suuji = 
                ($digit == 1 
                 and !$opt->{p_one} 
                 and $keta > 0) ? ''
                 :  $zero2nine->[$digit];
            $sens = $suuji . $ten2thou->[$keta] . $sens
                if $digit != 0;
	    }
	    $keta++;
	}
	# $sens or next;
	$seisuu = $sens . $suffices->[$suffix++] . $seisuu;
    }
    my $result =  $sign->{$sig} . $manman . $seisuu;
    $result ||= $zero;
    if ($fract) {
        while ($fract =~ /(\d)/g) {
            $shousuu .= $zero2nine->[$1];
        }
        my $point = $opt->{point} ? $opt->{point}
                  : $Point->{$style};
        $result .=  $point . $shousuu;
    }
    if ($exp) {
        $result .= 
            $opt->{romaji}   ? 'KakeruJuNo'       . num2ja($exp, $opt) .'Jou'
            : $opt->{katakana} ? 'カケルジュウノ' . num2ja($exp, $opt) .'ジョウ'
            : $opt->{hiragana} ? 'かけるじゅうの' . num2ja($exp, $opt) .'じょう'
            :                    '掛ける十の'     . num2ja($exp, $opt) . '乗';
    }
    if ($style =~ /(?:romaji|[k|g]ana)$/){
        $result =~ s/($RE_Kana_Fix)/$RE_Kana_Fix{$1}/ig;
    }
    return $result;
}

*number_to_ja = \&num2ja;

our $Ordinal = {
    kanji    => '番',
    romaji   => 'Ban',
    hiragana => 'ばん',
    katakana => 'バン',
};

sub num2ja_ordinal{
    my ($num, $opt) =  @_;
    my $style    = $opt->{style} || 'kanji';
    my $ordinal = $opt->{ordinal} || $Ordinal->{$style};
    return num2ja(@_) . $ordinal;
}
*number_to_ja_ordinal = \&num2ja_ordinal;


our %RE_Points  = (
		   '．'   => '.',
		   '点'   => '.',
		   'てん' => '.',
		  );
our $RE_Points = join ('|', keys %RE_Points);

our %RE_Zero2Nine = (
    '零' => 0, '〇' => 0, 'ぜろ' => 0, 'れい' => 0, Zero  => 0,
    '一' => 1, '壱' => 1, 'いち' => 1,              Ichi  => 1,
    '二' => 2, '弐' => 2, 'に'   => 2,              Ni    => 2,
    '三' => 3, '参' => 3, 'さん' => 3,              San   => 3,
    '四' => 4, '肆' => 4, 'し'   => 4, 'よん' => 4, Shi   => 4, Yon => 4,
    '五' => 5, '伍' => 5, 'ご'   => 5,              Go    => 5,
    '六' => 6, '陸' => 6, 'ろく' => 6,              Roku  => 6,
    '七' => 7, '漆' => 7, 'なな' => 7, 'しち' => 7, Nana  => 7, Shichi => 7,
    '八' => 8, '捌' => 8, 'はち' => 8,              Hachi => 8,
    '九' => 9, '玖' => 9, 'きゅう' => 9,            Kyuu  => 9, 
);
our $RE_Zero2Nine = join ('|', keys %RE_Zero2Nine);

our %RE_Ten2Thou = ( 
    '十' => 1, '拾' => 1, 'じゅう' => 1,  Juu   => 1,
    '百' => 2, '佰' => 2, 'ひゃく' => 2,  Hyaku => 2,
    '千' => 3, '阡' => 3, 'せん'   => 3,  Sen   => 3,
);
our $RE_Ten2Thou = join ('|', keys %RE_Ten2Thou);

our %RE_Suffices = (
    '万'   => 4, '萬' => 4, 'まん'   => 4,  Man  => 4,
    '億'   => 8,            'おく'   => 8,  Oku  => 8,
    '兆'   => 12,           'ちょう' => 12, Chou => 12,
    '京'   => 16,           'けい'   => 16, Kei =>  16,
    '垓'   => 20,           'がい'   => 20, Gai  => 20,
    '禾予' => 24,           'じょ'   => 24, Jo   => 24,
    '穣'   => 28,           'じょう' => 28, Jou  => 28,
    '溝'   => 32,           'こう'   => 32, Kou  => 32,
    '澗'   => 36,           'かん'   => 36, Kan  => 36,
    '正'   => 40,           'せい'   => 40, Sei  => 40,
    '載'   => 44,           'さい'   => 44, Sai  => 44,
    '極'   => 48,           'ごく'   => 48, Goku => 48,
    '恒河沙' => 52,         'こうがしゃ' => 52, Kougasha     => 52,
    '阿僧祇' => 56,         'あそうぎ'   => 56, Asougi       => 56,
    '那由他' => 60,         'なゆた'     => 60, Nayuta       => 60,
    '不可思議' => 64,       'ふかしぎ'   => 64, Fukashigi    => 64,
    '無量大数' => 68,       'むりょうたいすう' => 68, Muryoutaisuu => 68,    
);
our $RE_Suffices = join ('|', keys %RE_Suffices);

our %RE_Hugenums = (
    '極'       => 48, 'ごく'             => 48, Goku => 48,
    '恒河沙'   => 56, 'こうがしゃ'       => 56, Kougasha     => 56,
    '阿僧祇'   => 64, 'あそうぎ'         => 64, Asougi       => 64,
    '那由他'   => 72, 'なゆた'           => 72, Nayuta       => 72,
    '不可思議' => 80, 'ふかしぎ'         => 80, Fukashigi    => 80,
    '無量大数' => 88, 'むりょうたいすう' => 88, Muryoutaisuu => 88,
);
our $RE_Hugenums = join ('|', keys %RE_Hugenums);

our %RE_Fraction = (
    '割' => 1,  'わり' => 1,
    '分' => 2,  'ぶ'   => 2,
    '厘' => 3,  'りん' => 3,
    '毛' => 4,  'もう' => 4,
    '糸' => 4,  'し'   => 4, '絲' => 4,
    '忽' => 5,  'こつ' => 5,
    '微' => 6,  'び'   => 6,
    '繊' => 7,  'せん' => 7,
    '沙' => 8,  'しゃ' => 8,
    '塵' => 9,  'じん' => 9,
    '埃' => 10, 'あい' => 10,
    '渺' => 11, 'びょう' => 11,
    '漠' => 12, 'ばく' => 12,
    '模糊' => 13, 'もこ' => 13,
    '逡巡' => 14, 'しゅんじゅん' => 14,
    '須臾' => 15, 'しゅゆ' => 15,
    '瞬息' => 16, 'しゅんそく' => 16,
    '弾指' => 17, 'だんし'     => 17,
    '刹那' => 18, 'せつな'     => 18,
    '六徳' => 19, 'りっとく'   => 19,
    '空虚' => 20, 'くうきょ'   => 20, 
    '清浄' => 21,  'せいじょう' => 21, '空' => 21, 'くう' => 21,
    '清'   => 22,  'せい'       => 22,
    '浄'   => 23,  'じょう'     => 23,
    '阿頼耶' => 24, 'あらや'    => 24,
    '阿摩羅' => 25,  'あまら'    => 25,
    '涅槃寂靜' =>26,  'ねはんじゃくじょう' => 26,
);
our $RE_Fraction = join ('|', keys %RE_Fraction);

our %RE_Op = (
    '掛ける' => '*', 'かける' => '*', Kakeru => '*',
    '割る'   => '/', 'わる'   => '/', Waru   => '/',  
    '足す'   => '+', 'たす'   => '+', Tasu   => '+', 'ぷらす'   => '+',
    'と'     => '+', 
    '引く'   => '-', 'ひく'   => '-', Hiku   => '-', 'まいなす' => '-',
);
our $RE_Op = join('|' => map { quotemeta($_) } keys %RE_Op);
our $RE_Numerals =
    qr{(?:\d
         |$RE_Zero2Nine|$RE_Ten2Thou|$RE_Suffices|$RE_Fraction|$RE_Points)+}ixo;
our %RE_Fix_Kana = reverse %RE_Kana_Fix;
our $RE_Fix_Kana = join("|", keys  %RE_Fix_Kana);

sub ja2num{
    no warnings 'uninitialized';
    my ($ja, $opt) = @_;
    # https://twitter.com/Nyaboo/status/575196780993761280
    if ($ja !~ /[+\-\.\deE]/) {
        no warnings 'numeric';
        my $num = $ja + 0;
        return $num if $num;
    }
    $ja or return; # or it croaks under -T @ eval
    $ja =~ s/[\s\x{3000}]//g;
    $ja =~ tr[０-９][0-9];
    $ja =~ tr[ァ-ン][ぁ-ん];
    $ja =~ s/($RE_Fix_Kana)/$RE_Fix_Kana{ucfirst $1}/igx;
    $ja =~ s{ (?:の|ノ|No)($RE_Numerals)(?:乗|じょう|ジョウ|Jou) }
            { "**" . $1 }iegx;
    $ja =~ s{ ($RE_Numerals)  }{ _ja2num($1, $opt) }iegx;	        
    $ja =~ s{ ($RE_Op) }{ $RE_Op{ucfirst $1} }igx;
    $ja =~ tr[（）＋−×÷][\(\)\+\-\*\/];
    # to be secure;  that way no dangerous ops are passed
    $ja =~ tr/[G-Z]//d; 
    my $result = eval qq{ use bignum; $ja};
    $@ and $opt->{debug} and warn "$ja => $@";
    $opt->{debug} and warn qq{ja2num("$ja") == $result};
    return qq($result);
}
*ja_to_number = \&ja2num;

sub _ja2num{
    no warnings 'uninitialized';
    my ($ja, $opt) = @_;
    $ja or return;
    my $manman = '';
    if ($opt->{manman}){ # wierd hack
        $ja =~ s{ \G(.*?)($RE_Hugenums) }
                { my ($p, $q) = ($1, $2);
                  $p ||= 1;
                  $manman .= _ja2num($p, $opt) . "e" . $RE_Hugenums{$q} . '+';
                  q();
                }iegx;
    }
    $ja =~ s{ ($RE_Zero2Nine) }{$RE_Zero2Nine{ucfirst $1}}igx;
    $ja =~ s{ (\d*)($RE_Ten2Thou)  }
	        { my $n = $1 || 1;
	          $n.'e'.$RE_Ten2Thou{ucfirst $2}.'+' }iegx;
    $ja =~ s{ ([\d\+\-e]+)($RE_Fraction)  }
	        { qq{($1)} . '*1e-' . $RE_Fraction{ucfirst $2} . '+'}iegx;
    $ja =~ s{ \G(.*?)\+?($RE_Suffices) }
            { my $p = $1 || 1;
              "($p)*1e" . $RE_Suffices{ucfirst $2} . '+' 
             }iegx;
    $ja =~ s{ ($RE_Points) }{ '.' }iegx;
    # warn $ja;
    $ja = $manman . $ja;
    $ja =~ s{ \+\s*(\)|\z) }{$1}gx;
    # warn $ja;
    my $result = eval qq{ use bignum; $ja };
    $@ and $opt->{debug} and warn "$ja =>\n $@";
    $opt->{debug} and warn qq{_ja2num("$ja") == $result};
    return qq($result);
}

our %RE_TO_STRING_EXCP = (
    Sanbyaku => 'san-byaku',
    Roppyaku => 'ro-p-pyaku',
    Happyaku => 'ha-p-pyaku',
    Sanzen   => 'san-zen',
    Hassen   => 'ha-s-sen',
);
our $RE_TO_STRING_EXCP = join("|", keys %RE_TO_STRING_EXCP);

sub to_string{
    my ($str,$opt) = @_;
    $opt ||= {};
    $opt->{style} = "romaji";
    delete $opt->{daiji};
    delete $opt->{daiji_h};
    my $ja = __PACKAGE__->new($str, $opt);
    my @words = 
      map { s/($RE_TO_STRING_EXCP)/$RE_TO_STRING_EXCP{$1}/i; lc $_ }
          ($ja->get_string =~ /([A-Z][a-z]*)/g);
    return @words;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::JA::Numbers - Converts numeric values into their Japanese string equivalents and vice versa

=head1 VERSION

$Revision: 0.5 $ $Date: 2015/03/10 11:04:45 $

=head1 SYNOPSIS

  use Lingua::JA::Numbers;

  # OO Style
  my $ja = Lingua::JA::Numbers->new(1234567890, {style=>'romaji'});
  # JuuNiOkuSanzenYonHyakuGoJuuRokuManNanaSenHappyakuKyuuJuu
  # $ja->get_string is implictly called
  print "$ja\n"; 
  print $ja+0, "\n";
  # 1234567890
  # $ja->number is implicitly called.
  # 1234567890

  # Functional Style
  my $str = ja2num(1234567890, {style=>'romaji'});
  print "$str\n";
  # JuuNiOkuSanzenYonHyakuGoJuuRokuManNanaSenHappyakuKyuuJuu
  print num2ja($str), "\n";
  # 1234567890

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires perl 5.8.1 or better.  It also uses L<bignum> internally (that comes with perl core).

=head1 DESCRIPTION

This module converts Japanese text in UTF-8 (or romaji in ascii) to number, AND vice versa.  Though this pod is in English and all examples are in romaji to make L<http://search.cpan.org/> happy, this module does accept Japanese in UTF-8.  Try the code below to see it.

  perl -MLingua::JA::Numbers \
    -e '$y="\x{4e8c}\x{5343}\x{4e94}"; printf "(C) %d Dan Kogai\n", ja2num($y)'

=head2 CAVEAT

DO NOT BE CONFUSED WITH L<Lingua::JA::Number> by Mike Schilli.  This module is far more comprehensive.  As of 0.03, it even does its to_string() upon request.

=head2 METHODS

This module supports the following methods.  They are compliant with L<Lingua::En::Numbers> and others.

=over 2

=item -E<gt>new($str [, {key=>var ...} ])

Constructs an object via C<$str>.  String can either be number or a string in Japanese that represents a number. Optionally take options.  See L</Functions> for options.

=item -E<gt>parse($str, [, {key=>var ...} ])

Parses C<$str>.

=item -E<gt>opt(key => var)

Changes internal options.

=item -E<gt>get_string
=item -E<gt>stringify
=item -E<gt>as_string

Stringifies the object accordingly to the options.  The object auto-stringifies via L<overload> so you don't usally need this.

=item -E<gt>as_number
=item -E<gt>numify

Numifies the object. The object auto-numifies via L<overload> so you don't usally need this UNLESS YOU USE THIS MODULE with L<bignum>.  See L</bignum vs. Lingua::JA::Numbers> below.

=back

=head2 Functions

This module supports the funcitons below;

=over 2

=item num2ja($num, [{key => value ... }]);
=item number_to_ja()

Converts the number to Japanese accordingly to the options. C<number_to_ja()> is just an alias to C<num2ja()>.

  # \x{767e}\x{4e8c}\x{5341}\x{4e09}
  num2ja(123)
  # HyakuNijuuSan
  num2ja(123, {style=>"romaji"})

This function supports the options as follows;

=over 2

=item style =E<gt> (kanji|romaji|hiragana|katakana)

Sets which style (well, script but the word "script" is confusing).
You can choose "kanji" (default), romaji, hiragana and katakana.

=item daiji =E<gt> (0|1|2)

When 1, I<daiji> is used. When 2 or larger, even those that are not represented as daiji will be in daiji.  See 
L<http://ja.wikipedia.org/wiki/%E5%A4%A7%E5%AD%97_%28%E6%95%B0%E5%AD%97%29>
for details.

When this option is set to non-zero, C<style> is ignored (kanji).

=item p_one

Forciblly prefix one even when not needed.

  print num2ja(1110, {style=>"romaji"}), "\n";
  # SenHyakuJuu
  print num2ja(1110, {style=>"romaji", p_one=>1}), "\n";
  # IchiSenIchiHyakuIchiJuu

=item fixed4

Just stack numbers for thousands.

  print num2ja(2005, {style=>"romaji"}), "\n";
  NiSenGo
  print num2ja(2005, {style=>"romaji", fixed4=>1}), "\n";
  NiZeroZeroGo

=item with_arabic

Like C<fixed4> but stack these numbers with arabic.

  print num2ja(20050831, {style=>"romaji"}), "\n";
  # NiSenGoManHappyakuSanJuuIchi
  print num2ja(20050831, {style=>"romaji" with_arabic=>1}), "\n";
  # 2005Man0831

=item manman

Depreciated.  When set to non-zero, it 8-digit (4x2) denomination for
'Goku' (10**48) and above.

  print num2ja(10**60, {style=>"romaji"}), "\n";
  # IchiAsougi
  print num2ja(10**60, {style=>"romaji" manman=>1}), "\n";
  # IchiManKougasha

=back

=item ja2num($str, [{key => value ... }]);
=item ja_to_number()

Converts Japanese number to number.  Unlike C<num2ja()>, its counterpart, it supports only one option, C<manman => (0|1)> which toggles 8-digit denomination.

It is pretty liberal on what it takes.  For instance they all return 20050831.

  ja2num("NisenGoManHappyakuSanjuIchi")
  ja2num("NiZeroZeroGoZeroHachiSanIchi")
  ja2num("2005Man0831")

=back

=head2 ja2num() hacks

ja2num() acts like a calculator -- the easiest way to support scientific notation was just that.  Try

  ja2num("6.0225Kakeru10No23Jou")

=head2 to_string() of Lingua::JA::Number

Though not exported by default, This module comes with to_string()
that is (upper-)compatibile with L<Lingua::JA::Number>.

 my @words = Lingua::JA::Numbers::to_string(1234);
 print join('-', @words), "\n";   
 # "sen-ni-hyaku-san-ju-yon"

=head2 EXPORT

ja2num(), num2ja(), num2ja_ordinal(), ja_to_number(), number_to_ja(), number_to_ja_ordinal()

=head1 BUGS

=over 2

=item bignum vs. Lingua::JA::Numbers

Because of L<overload>, The OO approach does not go well with L<bignum>,
despite the fact this module uses it internally.

  use bignum;
  $j = Lingua::JA::Numbers->new("SanTenIchiYon");
  $b = 1 + $ja          # bang! does not work;
  $b = 1 + $ja->numify; # OK

=item Jo, or 10**24

The chacracter Jo (U+25771) which represents ten to twenty-four does not
have a code point in BMP so it is represented in two letters that 
look like one (U+79be U+x4e88)

=back

=head1 SEE ALSO

L<Lingua::En::Numbers>
L<Lingua::En::Number>
L<http://ja.wikipedia.org/wiki/%E6%BC%A2%E6%95%B0%E5%AD%97>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

package Lingua::JA::Romaji;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::JA::Romaji ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	&romajitokana &kanatoromaji %hiragana %katakana
) ] );

our @EXPORT_OK = (	qw( &kanatoromaji %hiragana %katakana ));

our @EXPORT = qw(
	&romajitokana
);
our $VERSION = '0.03';


# Preloaded methods go here.

#romajitokana ( romaji, kanatype)
#kanatype == ``hira'' or ``kana''.  
sub romajitokana {
    #let's ignore case
    my $romaji = lc $_[0];
    my $kanatype;
    return unless $romaji;
    if((defined $_[1]) && ($_[1] =~ m/kata/i)) {
        $kanatype = "kata";
    } else {
        $kanatype = "hira";
    }
    #handle goofy stuff with solitary and doubled n
    $romaji =~ s/[nm]([nm])/q$1/gi;
    $romaji =~ s/n\'/q/gi;
    $romaji =~ s/n$/q/gi;
    #handle regular stuff with singular n.  Is first regex necessary?
    $romaji =~ s/[nm]([bcdfghjkmnprstvz])/q$1/gi;
    #handle double consonants, perhaps ineffectually
    if ($romaji =~ m/([bcdfghjkmnprstvz])\1/i){
        $romaji=~ s/([bcdfghjkmnprstvz])$1/\*$1/gi;
    }
    my @roma = split(//,$romaji);
    my $curst = $roma[0];
    my $i=0;
    my $next = " ";
    my $output = "";
    while ((defined $next)&&($roma[$i] =~ m/[a-z\-\*]/i)) {
        $next = $roma[$i+1];
        unless ($next){
            if ($Lingua::JA::Romaji::roma{$curst}->{$kanatype}) {
                $output.=$Lingua::JA::Romaji::roma{$curst}->{$kanatype};
                $curst = "";
            }
        }
        next unless $next;
        unless ($Lingua::JA::Romaji::roma{$curst . $next}) {
            #we've gone too far, so print out what we've got, if anything
            if ($Lingua::JA::Romaji::roma{$curst}->{$kanatype}) {
                $output.=$Lingua::JA::Romaji::roma{$curst}->{$kanatype};
                $curst = "";

            } 
        } else {
            #if we're here, then curst.next is valid...
            unless ($roma[$i+2]){
                #...and there's nothing else
                $output.=$Lingua::JA::Romaji::roma{$curst . $next}->{$kanatype};
                $curst ="";
                $next = "";
            }
        } 
        $i++;
        $curst = $curst . $next;
    }
    return $output;
}

#kanatoromaji(kana)
sub kanatoromaji {
    my $kana = $_[0];
    my $rawb = unpack("H32", $kana);
#    print "$rawb\n";
    my $scratchkana = $kana;
    my $hirabegin = chr(0xA4);
    my $katabegin = chr(0xA5);
    my @skb = split(//,$scratchkana);
    my $newroma="";
    my $kanatype;
    if ($skb[0] eq $katabegin) {
        $kanatype = 1;
    } else {
        $kanatype = 0;
    }
    while (my $thisbyte = shift @skb) {
        if (($thisbyte eq $hirabegin) || ($thisbyte eq $katabegin)) {
            my $nextbyte = shift @skb;
            if ($Lingua::JA::Romaji::allkana{$thisbyte . $nextbyte}) {
                    $newroma .=  $Lingua::JA::Romaji::allkana{$thisbyte . $nextbyte};
            } else {
                $newroma .= $thisbyte . $nextbyte;
            }
        } else {
            $newroma .= $thisbyte;
        }
    }

    $newroma =~ s/\'$//;
    $newroma =~ s/n\'([^aeiouy])/n$1/gi;
    $newroma =~ s/\*(.)/$1$1/g;
    $newroma =~ s/ixy(.)/$1/ig;
    $newroma =~ s/ix(.)/y$1/ig;
    $newroma =~ s/ux(.)/$1/ig;
    if ($kanatype) {
        return uc $newroma;
    }
    return $newroma;
}

%Lingua::JA::Romaji::hiragana = (
               '・' => '.',
               'ー' => '-',
               'きゃ' => 'kya',
               'きゅ' => 'kyu',
               'じぇ' => 'jye',
               'きょ' => 'kyo',
               'でゃ' => 'dya',
               'でゅ' => 'dyu',
               'ひぇ' => 'hye',
               'でょ' => 'dyo',
               'ぴゃ' => 'pya',
               'ぴゅ' => 'pyu',
               'みぇ' => 'mye',
               'ぴょ' => 'pyo',
               'ぢゃ' => 'dja',
               'ぢゅ' => 'dju',
               'ぢょ' => 'djo',
               'ぎぇ' => 'gye',
               'ふぁ' => 'fa',
               'ふぃ' => 'fi',
               'ふぇ' => 'fye',
               'ふぉ' => 'fo',
               'じゃ' => 'jya',
               'じゅ' => 'jyu',
               'じょ' => 'jyo',
               'ぁ' => 'xa',
               'あ' => 'a',
               'ぃ' => 'xi',
               'い' => 'i',
               'ぅ' => 'xu',
               'ひゃ' => 'hya',
               'う' => 'u',
               'ぇ' => 'xe',
               'ひゅ' => 'hyu',
               'え' => 'ye',
               'ぉ' => 'xo',
               'お' => 'o',
               'ひょ' => 'hyo',
               'か' => 'ka',
               'が' => 'ga',
               'き' => 'ki',
               'みゃ' => 'mya',
               'ぎ' => 'gi',
               'く' => 'ku',
               'みゅ' => 'myu',
               'ぐ' => 'gu',
               'りぇ' => 'rye',
               'け' => 'ke',
               'みょ' => 'myo',
               'げ' => 'ge',
               'にぇ' => 'nye',
               'こ' => 'ko',
               'ご' => 'go',
               'さ' => 'sa',
               'ざ' => 'za',
               'っち' => 'tchi',
               'し' => 'syi',
               'っちぇ' => 'tche',
               'じ' => 'jyi',
               'ぎゃ' => 'gya',
               'す' => 'su',
               'ず' => 'zu',
               'ぎゅ' => 'gyu',
               'せ' => 'se',
               'ぎょ' => 'gyo',
               'ぜ' => 'ze',
               'そ' => 'so',
               'ぞ' => 'zo',
               'た' => 'ta',
               'だ' => 'da',
               'ち' => 'tyi',
               'ぢ' => 'dji',
               'っ' => 't-',
               'つ' => 'tu',
               'づ' => 'dzu',
               'て' => 'te',
               'で' => 'de',
               'と' => 'to',
               'ど' => 'do',
               'な' => 'na',
               'に' => 'ni',
               'びぇ' => 'bye',
               'ぬ' => 'nu',
               'ね' => 'ne',
               'の' => 'no',
               'は' => 'ha',
               'ふゃ' => 'fya',
               'ば' => 'ba',
               'ぱ' => 'pa',
               'ふゅ' => 'fyu',
               'ひ' => 'hi',
               'び' => 'bi',
               'ふょ' => 'fyo',
               'ちぇ' => 'tye',
               'ぴ' => 'pi',
               'ふ' => 'hu',
               'ぶ' => 'bu',
               'ぷ' => 'pu',
               'へ' => 'he',
               'べ' => 'be',
               'ぺ' => 'pe',
               'ほ' => 'ho',
               'ぼ' => 'bo',
               'ぽ' => 'po',
               'ま' => 'ma',
               'み' => 'mi',
               'む' => 'mu',
               'め' => 'me',
               'も' => 'mo',
               'ゃ' => 'xya',
               'や' => 'ya',
               'ゅ' => 'xyu',
               'ゆ' => 'yu',
               'ょ' => 'xyo',
               'よ' => 'yo',
               'ら' => 'ra',
               'どぅ' => 'du',
               'り' => 'ri',
               'る' => 'ru',
               'れ' => 're',
               'ろ' => 'ro',
               'りゃ' => 'rya',
               'ゎ' => 'xwa',
               'わ' => 'wa',
               'りゅ' => 'ryu',
               'にゃ' => 'nya',
               'ゐ' => 'wi',
               'ゑ' => 'we',
               'りょ' => 'ryo',
               'にゅ' => 'nyu',
               'を' => 'wo',
               'ん' => 'q',
               'っちゃ' => 'tcha',
               'にょ' => 'nyo',
               'しぇ' => 'sye',
               'っちゅ' => 'tchu',
               'つぁ' => 'tsa',
               'っちょ' => 'tcho',
               'つぇ' => 'tse',
               'つぉ' => 'tso',
               'びゃ' => 'bya',
               'びゅ' => 'byu',
               'びょ' => 'byo',
               'ちゃ' => 'tya',
               'ちゅ' => 'tyu',
               'ちょ' => 'tyo',
               'きぇ' => 'kye',
               'でぃ' => 'di',
               'でぇ' => 'dye',
               'ぴぇ' => 'pye',
               'しゃ' => 'sya',
               'しゅ' => 'syu',
               'ぢぇ' => 'dje',
               'しょ' => 'syo'
             );
%Lingua::JA::Romaji::katakana = (
               'キュ' => 'kyu',
               'ジェ' => 'jye',
               'キョ' => 'kyo',
               '・' => '.',
               'デャ' => 'dya',
               'デュ' => 'dyu',
               'ヒェ' => 'hye',
               'デョ' => 'dyo',
               'ピャ' => 'pya',
               'ピュ' => 'pyu',
               'ミェ' => 'mye',
               'ー' => '-',
               'ピョ' => 'pyo',
               'ヂャ' => 'dja',
               'ヂュ' => 'dju',
               'ヂョ' => 'djo',
               'ギェ' => 'gye',
               'ヴァ' => 'va',
               'ヴィ' => 'vi',
               'ファ' => 'fa',
               'フィ' => 'fi',
               'ヴェ' => 've',
               'ヴォ' => 'vo',
               'フェ' => 'fye',
               'フォ' => 'fo',
               'ジャ' => 'jya',
               'ジュ' => 'jyu',
               'ジョ' => 'jyo',
               'ッチェ' => 'tche',
               'ヒャ' => 'hya',
               'ヒュ' => 'hyu',
               'ヒョ' => 'hyo',
               'ミャ' => 'mya',
               'ミュ' => 'myu',
               'リェ' => 'rye',
               'ミョ' => 'myo',
               'ニェ' => 'nye',
               'ッチ' => 'tchi',
               'ギャ' => 'gya',
               'ギュ' => 'gyu',
               'ギョ' => 'gyo',
               'ビェ' => 'bye',
               'フャ' => 'fya',
               'フュ' => 'fyu',
               'フョ' => 'fyo',
               'チェ' => 'tye',
               'ッチャ' => 'tcha',
               'ァ' => 'xa',
               'ッチュ' => 'tchu',
               'ア' => 'a',
               'ィ' => 'xi',
               'ッチョ' => 'tcho',
               'イ' => 'i',
               'ゥ' => 'xu',
               'ウ' => 'u',
               'ェ' => 'xe',
               'エ' => 'ye',
               'ォ' => 'xo',
               'オ' => 'o',
               'カ' => 'ka',
               'ガ' => 'ga',
               'キ' => 'ki',
               'ギ' => 'gi',
               'ク' => 'ku',
               'ドゥ' => 'du',
               'グ' => 'gu',
               'ケ' => 'ke',
               'ゲ' => 'ge',
               'リャ' => 'rya',
               'コ' => 'ko',
               'ゴ' => 'go',
               'リュ' => 'ryu',
               'サ' => 'sa',
               'ニャ' => 'nya',
               'ザ' => 'za',
               'リョ' => 'ryo',
               'シ' => 'syi',
               'ニュ' => 'nyu',
               'ジ' => 'jyi',
               'ス' => 'su',
               'ニョ' => 'nyo',
               'ズ' => 'zu',
               'シェ' => 'sye',
               'セ' => 'se',
               'ツァ' => 'tsa',
               'ゼ' => 'ze',
               'ソ' => 'so',
               'ゾ' => 'zo',
               'タ' => 'ta',
               'ダ' => 'da',
               'チ' => 'tyi',
               'ツェ' => 'tse',
               'ヂ' => 'dji',
               'ッ' => 't-',
               'ツォ' => 'tso',
               'ツ' => 'tu',
               'ヅ' => 'dzu',
               'テ' => 'te',
               'デ' => 'de',
               'ト' => 'to',
               'ド' => 'do',
               'ナ' => 'na',
               'ニ' => 'ni',
               'ヌ' => 'nu',
               'ネ' => 'ne',
               'ビャ' => 'bya',
               'ノ' => 'no',
               'ハ' => 'ha',
               'ビュ' => 'byu',
               'バ' => 'ba',
               'パ' => 'pa',
               'ビョ' => 'byo',
               'ヒ' => 'hi',
               'ビ' => 'bi',
               'ピ' => 'pi',
               'フ' => 'hu',
               'チャ' => 'tya',
               'ブ' => 'bu',
               'プ' => 'pu',
               'チュ' => 'tyu',
               'ヘ' => 'he',
               'ベ' => 'be',
               'チョ' => 'tyo',
               'ペ' => 'pe',
               'キェ' => 'kye',
               'ホ' => 'ho',
               'ボ' => 'bo',
               'ポ' => 'po',
               'マ' => 'ma',
               'ミ' => 'mi',
               'ム' => 'mu',
               'メ' => 'me',
               'モ' => 'mo',
               'ャ' => 'xya',
               'ヤ' => 'ya',
               'ュ' => 'xyu',
               'ディ' => 'di',
               'ユ' => 'yu',
               'ョ' => 'xyo',
               'ヨ' => 'yo',
               'ラ' => 'ra',
               'デェ' => 'dye',
               'リ' => 'ri',
               'ル' => 'ru',
               'レ' => 're',
               'ロ' => 'ro',
               'ヮ' => 'xwa',
               'ワ' => 'wa',
               'ヰ' => 'wi',
               'ヱ' => 'we',
               'ピェ' => 'pye',
               'ヲ' => 'wo',
               'ン' => 'q',
               'ヴ' => 'vu',
               'ヵ' => 'xka',
               'ヶ' => 'xke',
               'シャ' => 'sya',
               'シュ' => 'syu',
               'ヂェ' => 'dje',
               'ショ' => 'syo',
               'キャ' => 'kya'
             );
%Lingua::JA::Romaji::roma = (
           'fo' => {
                     'kata' => 'フォ',
                     'hira' => 'ふぉ'
                   },
           'fyu' => {
                      'kata' => 'フュ',
                      'hira' => 'ふゅ'
                    },
           'na' => {
                     'kata' => 'ナ',
                     'hira' => 'な'
                   },
           'syo' => {
                      'kata' => 'ショ',
                      'hira' => 'しょ'
                    },
           'fu' => {
                     'kata' => 'フ',
                     'hira' => 'ふ'
                   },
           'ne' => {
                     'kata' => 'ネ',
                     'hira' => 'ね'
                   },
           'nya' => {
                      'kata' => 'ニャ',
                      'hira' => 'にゃ'
                    },
           'xka' => {
                      'kata' => 'ヵ'
                    },
           'nye' => {
                      'kata' => 'ニェ',
                      'hira' => 'にぇ'
                    },
           'ni' => {
                     'kata' => 'ニ',
                     'hira' => 'に'
                   },
           'syu' => {
                      'kata' => 'シュ',
                      'hira' => 'しゅ'
                    },
           'xke' => {
                      'kata' => 'ヶ'
                    },
           'no' => {
                     'kata' => 'ノ',
                     'hira' => 'の'
                   },
           'va' => {
                     'kata' => 'ヴァ',
                     'hira' => 'ヴぁ'
                   },
           'nyo' => {
                      'kata' => 'ニョ',
                      'hira' => 'にょ'
                    },
           'ga' => {
                     'kata' => 'ガ',
                     'hira' => 'が'
                   },
           've' => {
                     'kata' => 'ヴェ',
                     'hira' => 'ヴぇ'
                   },
           'nu' => {
                     'kata' => 'ヌ',
                     'hira' => 'ぬ'
                   },
           'ge' => {
                     'kata' => 'ゲ',
                     'hira' => 'げ'
                   },
           'vi' => {
                     'kata' => 'ヴィ',
                     'hira' => 'ヴぃ'
                   },
           'nyu' => {
                      'kata' => 'ニュ',
                      'hira' => 'にゅ'
                    },
           'gi' => {
                     'kata' => 'ギ',
                     'hira' => 'ぎ'
                   },
           'vo' => {
                     'kata' => 'ヴォ',
                     'hira' => 'ヴぉ    '
                   },
           'go' => {
                     'kata' => 'ゴ',
                     'hira' => 'ご'
                   },
           'vu' => {
                     'kata' => 'ヴ',
                     'hira' => 'ヴ'
                   },
           'dya' => {
                      'kata' => 'デャ',
                      'hira' => 'でゃ'
                    },
           'gu' => {
                     'kata' => 'グ',
                     'hira' => 'ぐ'
                   },
           'dja' => {
                      'kata' => 'ヂャ',
                      'hira' => 'ぢゃ'
                    },
           '*' => {
                    'kata' => 'ッ',
                    'hira' => 'っ'
                  },
           'dye' => {
                      'kata' => 'デェ',
                      'hira' => 'でぇ'
                    },
           'dje' => {
                      'kata' => 'ヂェ',
                      'hira' => 'ぢぇ'
                    },
           '-' => {
                    'kata' => 'ー',
                    'hira' => 'ー'
                  },
           '.' => {
                    'kata' => '・',
                    'hira' => '・'
                  },
           'dji' => {
                      'kata' => 'ヂ',
                      'hira' => 'ぢ'
                    },
           'wa' => {
                     'kata' => 'ワ',
                     'hira' => 'わ'
                   },
           'ha' => {
                     'kata' => 'ハ',
                     'hira' => 'は'
                   },
           'dyo' => {
                      'kata' => 'デョ',
                      'hira' => 'でょ'
                    },
           'djo' => {
                      'kata' => 'ヂョ',
                      'hira' => 'ぢょ'
                    },
           'we' => {
                     'kata' => 'ヱ',
                     'hira' => 'ゑ'
                   },
           'he' => {
                     'kata' => 'ヘ',
                     'hira' => 'へ'
                   },
           'dyu' => {
                      'kata' => 'デュ',
                      'hira' => 'でゅ'
                    },
           'wi' => {
                     'kata' => 'ヰ',
                     'hira' => 'ゐ'
                   },
           'hi' => {
                     'kata' => 'ヒ',
                     'hira' => 'ひ'
                   },
           'dju' => {
                      'kata' => 'ヂュ',
                      'hira' => 'ぢゅ'
                    },
           'wo' => {
                     'kata' => 'ヲ',
                     'hira' => 'を'
                   },
           'ho' => {
                     'kata' => 'ホ',
                     'hira' => 'ほ'
                   },
           'pa' => {
                     'kata' => 'パ',
                     'hira' => 'ぱ'
                   },
           'dza' => {
                      'kata' => 'ヂャ',
                      'hira' => 'ぢゃ'
                    },
           'pe' => {
                     'kata' => 'ペ',
                     'hira' => 'ぺ'
                   },
           'hu' => {
                     'kata' => 'フ',
                     'hira' => 'ふ'
                   },
           'pi' => {
                     'kata' => 'ピ',
                     'hira' => 'ぴ'
                   },
           'dze' => {
                      'kata' => 'ヂェ',
                      'hira' => 'ぢぇ'
                    },
           'gya' => {
                      'kata' => 'ギャ',
                      'hira' => 'ぎゃ'
                    },
           'dzi' => {
                      'kata' => 'ヂ',
                      'hira' => 'ぢ'
                    },
           'po' => {
                     'kata' => 'ポ',
                     'hira' => 'ぽ'
                   },
           'gye' => {
                      'kata' => 'ギェ',
                      'hira' => 'ぎぇ'
                    },
           'tcha' => {
                       'kata' => 'ッチャ',
                       'hira' => 'っちゃ'
                     },
           'xa' => {
                     'kata' => 'ァ',
                     'hira' => 'ぁ'
                   },
           'dzo' => {
                      'kata' => 'ヂョ',
                      'hira' => 'ぢょ'
                    },
           'tya' => {
                      'kata' => 'チャ',
                      'hira' => 'ちゃ'
                    },
           'tche' => {
                       'kata' => 'ッチェ',
                       'hira' => 'っちぇ'
                     },
           'xe' => {
                     'kata' => 'ェ',
                     'hira' => 'ぇ'
                   },
           'pu' => {
                     'kata' => 'プ',
                     'hira' => 'ぷ'
                   },
           'tye' => {
                      'kata' => 'チェ',
                      'hira' => 'ちぇ'
                    },
           'dzu' => {
                      'kata' => 'ヅ',
                      'hira' => 'づ'
                    },
           'tchi' => {
                       'kata' => 'ッチ',
                       'hira' => 'っち'
                     },
           'gyo' => {
                      'kata' => 'ギョ',
                      'hira' => 'ぎょ'
                    },
           'xi' => {
                     'kata' => 'ィ',
                     'hira' => 'ぃ'
                   },
           'tyi' => {
                      'kata' => 'チ',
                      'hira' => 'ち'
                    },
           'bya' => {
                      'kata' => 'ビャ',
                      'hira' => 'びゃ'
                    },
           'a' => {
                    'kata' => 'ア',
                    'hira' => 'あ'
                  },
           'tcho' => {
                       'kata' => 'ッチョ',
                       'hira' => 'っちょ'
                     },
           'gyu' => {
                      'kata' => 'ギュ',
                      'hira' => 'ぎゅ'
                    },
           'xo' => {
                     'kata' => 'ォ',
                     'hira' => 'ぉ'
                   },
           'bye' => {
                      'kata' => 'ビェ',
                      'hira' => 'びぇ'
                    },
           'tyo' => {
                      'kata' => 'チョ',
                      'hira' => 'ちょ'
                    },
           'e' => {
                    'kata' => 'エ',
                    'hira' => 'え'
                  },
           'ba' => {
                     'kata' => 'バ',
                     'hira' => 'ば'
                   },
           'tchu' => {
                       'kata' => 'ッチュ',
                       'hira' => 'っちゅ'
                     },
           'i' => {
                    'kata' => 'イ',
                    'hira' => 'い'
                  },
           'xu' => {
                     'kata' => 'ゥ',
                     'hira' => 'ぅ'
                   },
           'tyu' => {
                      'kata' => 'チュ',
                      'hira' => 'ちゅ'
                    },
           'be' => {
                     'kata' => 'ベ',
                     'hira' => 'べ'
                   },
           'byo' => {
                      'kata' => 'ビョ',
                      'hira' => 'びょ'
                    },
           'o' => {
                    'kata' => 'オ',
                    'hira' => 'お'
                  },
           'bi' => {
                     'kata' => 'ビ',
                     'hira' => 'び'
                   },
           'q' => {
                    'kata' => 'ン',
                    'hira' => 'ん'
                  },
           'byu' => {
                      'kata' => 'ビュ',
                      'hira' => 'びゅ'
                    },
           'u' => {
                    'kata' => 'ウ',
                    'hira' => 'う'
                  },
           'ya' => {
                     'kata' => 'ヤ',
                     'hira' => 'や'
                   },
           'bo' => {
                     'kata' => 'ボ',
                     'hira' => 'ぼ'
                   },
           'ja' => {
                     'kata' => 'ジャ',
                     'hira' => 'じゃ'
                   },
           'jya' => {
                      'kata' => 'ジャ',
                      'hira' => 'じゃ'
                    },
           'ye' => {
                     'kata' => 'エ',
                     'hira' => 'え'
                   },
           'bu' => {
                     'kata' => 'ブ',
                     'hira' => 'ぶ'
                   },
           'je' => {
                     'kata' => 'ジェ',
                     'hira' => 'じぇ'
                   },
           'jye' => {
                      'kata' => 'ジェ',
                      'hira' => 'じぇ'
                    },
           'ji' => {
                     'kata' => 'ジ',
                     'hira' => 'じ'
                   },
           'jyi' => {
                      'kata' => 'ジ',
                      'hira' => 'じ'
                    },
           'cha' => {
                      'kata' => 'チャ',
                      'hira' => 'ちゃ'
                    },
           'che' => {
                      'kata' => 'チェ',
                      'hira' => 'ちぇ'
                    },
           'yo' => {
                     'kata' => 'ヨ',
                     'hira' => 'よ'
                   },
           'jo' => {
                     'kata' => 'ジョ',
                     'hira' => 'じょ'
                   },
           'jyo' => {
                      'kata' => 'ジョ',
                      'hira' => 'じょ'
                    },
           'ra' => {
                     'kata' => 'ラ',
                     'hira' => 'ら'
                   },
           'chi' => {
                      'kata' => 'チ',
                      'hira' => 'ち'
                    },
           'tsa' => {
                      'kata' => 'ツァ',
                      'hira' => 'つぁ'
                    },
           'yu' => {
                     'kata' => 'ユ',
                     'hira' => 'ゆ'
                   },
           're' => {
                     'kata' => 'レ',
                     'hira' => 'れ'
                   },
           'ju' => {
                     'kata' => 'ジュ',
                     'hira' => 'じゅ'
                   },
           'jyu' => {
                      'kata' => 'ジュ',
                      'hira' => 'じゅ'
                    },
           'cho' => {
                      'kata' => 'チョ',
                      'hira' => 'ちょ'
                    },
           'tse' => {
                      'kata' => 'ツェ',
                      'hira' => 'つぇ'
                    },
           'rya' => {
                      'kata' => 'リャ',
                      'hira' => 'りゃ'
                    },
           'ri' => {
                     'kata' => 'リ',
                     'hira' => 'り'
                   },
           'rye' => {
                      'kata' => 'リェ',
                      'hira' => 'りぇ'
                    },
           'chu' => {
                      'kata' => 'チュ',
                      'hira' => 'ちゅ'
                    },
           'ro' => {
                     'kata' => 'ロ',
                     'hira' => 'ろ'
                   },
           't-' => {
                     'kata' => 'ッ',
                     'hira' => 'っ'
                   },
           'za' => {
                     'kata' => 'ザ',
                     'hira' => 'ざ'
                   },
           'tso' => {
                      'kata' => 'ツォ',
                      'hira' => 'つぉ'
                    },
           'ka' => {
                     'kata' => 'カ',
                     'hira' => 'か'
                   },
           'ze' => {
                     'kata' => 'ゼ',
                     'hira' => 'ぜ'
                   },
           'ru' => {
                     'kata' => 'ル',
                     'hira' => 'る'
                   },
           'xwa' => {
                      'kata' => 'ヮ',
                      'hira' => 'ゎ'
                    },
           'ryo' => {
                      'kata' => 'リョ',
                      'hira' => 'りょ'
                    },
           'ke' => {
                     'kata' => 'ケ',
                     'hira' => 'け'
                   },
           'tsu' => {
                      'kata' => 'ツ',
                      'hira' => 'つ'
                    },
           'mya' => {
                      'kata' => 'ミャ',
                      'hira' => 'みゃ'
                    },
           'zi' => {
                     'kata' => 'ジ',
                     'hira' => 'じ'
                   },
           'ki' => {
                     'kata' => 'キ',
                     'hira' => 'き'
                   },
           'ryu' => {
                      'kata' => 'リュ',
                      'hira' => 'りゅ'
                    },
           'mye' => {
                      'kata' => 'ミェ',
                      'hira' => 'みぇ'
                    },
           'zo' => {
                     'kata' => 'ゾ',
                     'hira' => 'ぞ'
                   },
           'ko' => {
                     'kata' => 'コ',
                     'hira' => 'こ'
                   },
           'sa' => {
                     'kata' => 'サ',
                     'hira' => 'さ'
                   },
           'da' => {
                     'kata' => 'ダ',
                     'hira' => 'だ'
                   },
           'zu' => {
                     'kata' => 'ズ',
                     'hira' => 'ず'
                   },
           'se' => {
                     'kata' => 'セ',
                     'hira' => 'せ'
                   },
           'myo' => {
                      'kata' => 'ミョ',
                      'hira' => 'みょ'
                    },
           'ku' => {
                     'kata' => 'ク',
                     'hira' => 'く'
                   },
           'sha' => {
                      'kata' => 'シャ',
                      'hira' => 'しゃ'
                    },
           'de' => {
                     'kata' => 'デ',
                     'hira' => 'で'
                   },
           'si' => {
                     'kata' => 'シ',
                     'hira' => 'し'
                   },
           'hya' => {
                      'kata' => 'ヒャ',
                      'hira' => 'ひゃ'
                    },
           'di' => {
                     'kata' => 'ディ',
                     'hira' => 'でぃ'
                   },
           'myu' => {
                      'kata' => 'ミュ',
                      'hira' => 'みゅ'
                    },
           'she' => {
                      'kata' => 'シェ',
                      'hira' => 'しぇ'
                    },
           'hye' => {
                      'kata' => 'ヒェ',
                      'hira' => 'ひぇ'
                    },
           'shi' => {
                      'kata' => 'シ',
                      'hira' => 'し'
                    },
           'so' => {
                     'kata' => 'ソ',
                     'hira' => 'そ'
                   },
           'do' => {
                     'kata' => 'ド',
                     'hira' => 'ど'
                   },
           'su' => {
                     'kata' => 'ス',
                     'hira' => 'す'
                   },
           'sho' => {
                      'kata' => 'ショ',
                      'hira' => 'しょ'
                    },
           'du' => {
                     'kata' => 'ドゥ',
                     'hira' => 'どぅ'
                   },
           'hyo' => {
                      'kata' => 'ヒョ',
                      'hira' => 'ひょ'
                    },
           'cya' => {
                      'kata' => 'チャ',
                      'hira' => 'ちゃ'
                    },
           'n\'' => {
                      'kata' => 'ン',
                      'hira' => 'ん'
                    },
           'shu' => {
                      'kata' => 'シュ',
                      'hira' => 'しゅ'
                    },
           'hyu' => {
                      'kata' => 'ヒュ',
                      'hira' => 'ひゅ'
                    },
           'cye' => {
                      'kata' => 'チェ',
                      'hira' => 'ちぇ'
                    },
           'pya' => {
                      'kata' => 'ピャ',
                      'hira' => 'ぴゃ'
                    },
           'cyi' => {
                      'kata' => 'チ',
                      'hira' => 'ち'
                    },
           'ta' => {
                     'kata' => 'タ',
                     'hira' => 'た'
                   },
           'pye' => {
                      'kata' => 'ピェ',
                      'hira' => 'ぴぇ'
                    },
           'te' => {
                     'kata' => 'テ',
                     'hira' => 'て'
                   },
           'cyo' => {
                      'kata' => 'チョ',
                      'hira' => 'ちょ'
                    },
           'ti' => {
                     'kata' => 'チ',
                     'hira' => 'ち'
                   },
           'cyu' => {
                      'kata' => 'チュ',
                      'hira' => 'ちゅ'
                    },
           'pyo' => {
                      'kata' => 'ピョ',
                      'hira' => 'ぴょ'
                    },
           'kya' => {
                      'kata' => 'キャ',
                      'hira' => 'きゃ'
                    },
           'to' => {
                     'kata' => 'ト',
                     'hira' => 'と'
                   },
           'ma' => {
                     'kata' => 'マ',
                     'hira' => 'ま'
                   },
           'pyu' => {
                      'kata' => 'ピュ',
                      'hira' => 'ぴゅ'
                    },
           'kye' => {
                      'kata' => 'キェ',
                      'hira' => 'きぇ'
                    },
           'tu' => {
                     'kata' => 'ツ',
                     'hira' => 'つ'
                   },
           'xya' => {
                      'kata' => 'ャ',
                      'hira' => 'ゃ'
                    },
           'me' => {
                     'kata' => 'メ',
                     'hira' => 'め'
                   },
           'mi' => {
                     'kata' => 'ミ',
                     'hira' => 'み'
                   },
           'kyo' => {
                      'kata' => 'キョ',
                      'hira' => 'きょ'
                    },
           'mo' => {
                     'kata' => 'モ',
                     'hira' => 'も'
                   },
           'fya' => {
                      'kata' => 'フャ',
                      'hira' => 'ふゃ'
                    },
           'kyu' => {
                      'kata' => 'キュ',
                      'hira' => 'きゅ'
                    },
           'fye' => {
                      'kata' => 'フェ',
                      'hira' => 'ふぇ'
                    },
           'fa' => {
                     'kata' => 'ファ',
                     'hira' => 'ふぁ'
                   },
           'xyo' => {
                      'kata' => 'ョ',
                      'hira' => 'ょ'
                    },
           'mu' => {
                     'kata' => 'ム',
                     'hira' => 'む'
                   },
           'sya' => {
                      'kata' => 'シャ',
                      'hira' => 'しゃ'
                    },
           'fe' => {
                     'kata' => 'フェ',
                     'hira' => 'ふぇ'
                   },
           'xyu' => {
                      'kata' => 'ュ',
                      'hira' => 'ゅ'
                    },
           'sye' => {
                      'kata' => 'シェ',
                      'hira' => 'しぇ'
                    },
           'fi' => {
                     'kata' => 'フィ',
                     'hira' => 'ふぃ'
                   },
           'fyo' => {
                      'kata' => 'フョ',
                      'hira' => 'ふょ'
                    },
           'syi' => {
                      'kata' => 'シ',
                      'hira' => 'し'
                    }
         );
%Lingua::JA::Romaji::allkana = (
              'キュ' => 'kyu',
              'ジェ' => 'je',
              'キョ' => 'kyo',
              'デャ' => 'dya',
              'デュ' => 'dyu',
              'ヒェ' => 'hye',
              'デョ' => 'dyo',
              'ヂャ' => 'dza',
              'ヂュ' => 'dju',
              'ヂョ' => 'dzo',
              'ギェ' => 'gye',
              'ぴゃ' => 'pya',
              'ぴゅ' => 'pyu',
              'みぇ' => 'mye',
              'ぴょ' => 'pyo',
              'ジャ' => 'ja',
              'ジュ' => 'ju',
              'ジョ' => 'jo',
              'ふぁ' => 'fa',
              'ヒャ' => 'hya',
              'ふぃ' => 'fi',
              'ヒュ' => 'hyu',
              'ヒョ' => 'hyo',
              'ふぇ' => 'fe',
              'ふぉ' => 'fo',
              'ッチ' => 'tchi',
              'ギャ' => 'gya',
              'ギュ' => 'gyu',
              'ギョ' => 'gyo',
              'みゃ' => 'mya',
              'みゅ' => 'myu',
              'りぇ' => 'rye',
              'ビェ' => 'bye',
              'みょ' => 'myo',
              'にぇ' => 'nye',
              'っちぇ' => 'tche',
              'ふゃ' => 'fya',
              'ドゥ' => 'du',
              'ふゅ' => 'fyu',
              'ふょ' => 'fyo',
              'ちぇ' => 'che',
              'ツァ' => 'tsa',
              'ツェ' => 'tse',
              'ツォ' => 'tso',
              'りゃ' => 'rya',
              'ビャ' => 'bya',
              'りゅ' => 'ryu',
              'にゃ' => 'nya',
              'ビュ' => 'byu',
              'りょ' => 'ryo',
              'にゅ' => 'nyu',
              'ビョ' => 'byo',
              'っちゃ' => 'tcha',
              'にょ' => 'nyo',
              'しぇ' => 'she',
              'っちゅ' => 'tchu',
              'っちょ' => 'tcho',
              'ちゃ' => 'cha',
              'ピェ' => 'pye',
              'ちゅ' => 'chu',
              'ちょ' => 'cho',
              'きぇ' => 'kye',
              'でぃ' => 'di',
              'でぇ' => 'dye',
              'しゃ' => 'sha',
              'しゅ' => 'shu',
              'ぢぇ' => 'dze',
              'しょ' => 'sho',
              '・' => '.',
              'ピャ' => 'pya',
              'ピュ' => 'pyu',
              'ミェ' => 'mye',
              'きゃ' => 'kya',
              'ー' => '-',
              'ピョ' => 'pyo',
              'きゅ' => 'kyu',
              'きょ' => 'kyo',
              'じぇ' => 'je',
              'でゃ' => 'dya',
              'でゅ' => 'dyu',
              'でょ' => 'dyo',
              'ひぇ' => 'hye',
              'ヴァ' => 'va',
              'ヴィ' => 'vi',
              'ヴぁ' => 'va',
              'ヴぃ' => 'vi',
              'ファ' => 'fa',
              'フィ' => 'fi',
              'ヴェ' => 've',
              'ヴぇ' => 've',
              'ぢゃ' => 'dza',
              'ヴォ' => 'vo',
              'ヴぉ' => 'vo',
              'フェ' => 'fe',
              'ぢゅ' => 'dju',
              'フォ' => 'fo',
              'ぢょ' => 'dzo',
              'ぎぇ' => 'gye',
              'ッチェ' => 'tche',
              'ミャ' => 'mya',
              'ミュ' => 'myu',
              'リェ' => 'rye',
              'ミョ' => 'myo',
              'じゃ' => 'ja',
              'ニェ' => 'nye',
              'じゅ' => 'ju',
              'じょ' => 'jo',
              'ぁ' => 'xa',
              'あ' => 'a',
              'ぃ' => 'xi',
              'い' => 'i',
              'ぅ' => 'xu',
              'う' => 'u',
              'ひゃ' => 'hya',
              'ぇ' => 'xe',
              'え' => 'e',
              'ひゅ' => 'hyu',
              'ぉ' => 'xo',
              'お' => 'o',
              'か' => 'ka',
              'ひょ' => 'hyo',
              'が' => 'ga',
              'き' => 'ki',
              'ぎ' => 'gi',
              'く' => 'ku',
              'ぐ' => 'gu',
              'け' => 'ke',
              'げ' => 'ge',
              'こ' => 'ko',
              'ご' => 'go',
              'さ' => 'sa',
              'フャ' => 'fya',
              'っち' => 'tchi',
              'ざ' => 'za',
              'し' => 'shi',
              'フュ' => 'fyu',
              'じ' => 'ji',
              'す' => 'su',
              'ぎゃ' => 'gya',
              'フョ' => 'fyo',
              'ず' => 'zu',
              'せ' => 'se',
              'ぎゅ' => 'gyu',
              'チェ' => 'che',
              'ぜ' => 'ze',
              'ぎょ' => 'gyo',
              'そ' => 'so',
              'ぞ' => 'zo',
              'た' => 'ta',
              'だ' => 'da',
              'ッチャ' => 'tcha',
              'ち' => 'chi',
              'ぢ' => 'dzi',
              'ァ' => 'xa',
              'ッチュ' => 'tchu',
              'っ' => '*',
              'ア' => 'a',
              'つ' => 'tsu',
              'ィ' => 'xi',
              'ッチョ' => 'tcho',
              'づ' => 'dzu',
              'イ' => 'i',
              'て' => 'te',
              'ゥ' => 'xu',
              'で' => 'de',
              'ウ' => 'u',
              'と' => 'to',
              'ェ' => 'xe',
              'ど' => 'do',
              'エ' => 'e',
              'な' => 'na',
              'ォ' => 'xo',
              'びぇ' => 'bye',
              'に' => 'ni',
              'オ' => 'o',
              'ぬ' => 'nu',
              'カ' => 'ka',
              'ね' => 'ne',
              'ガ' => 'ga',
              'の' => 'no',
              'キ' => 'ki',
              'は' => 'ha',
              'ギ' => 'gi',
              'ば' => 'ba',
              'ク' => 'ku',
              'ぱ' => 'pa',
              'グ' => 'gu',
              'ひ' => 'hi',
              'ケ' => 'ke',
              'び' => 'bi',
              'ゲ' => 'ge',
              'リャ' => 'rya',
              'ぴ' => 'pi',
              'コ' => 'ko',
              'ふ' => 'fu',
              'ゴ' => 'go',
              'リュ' => 'ryu',
              'ぶ' => 'bu',
              'サ' => 'sa',
              'ニャ' => 'nya',
              'ぷ' => 'pu',
              'ザ' => 'za',
              'リョ' => 'ryo',
              'へ' => 'he',
              'シ' => 'shi',
              'ニュ' => 'nyu',
              'べ' => 'be',
              'ジ' => 'ji',
              'ぺ' => 'pe',
              'ス' => 'su',
              'ニョ' => 'nyo',
              'ほ' => 'ho',
              'ズ' => 'zu',
              'シェ' => 'she',
              'ぼ' => 'bo',
              'セ' => 'se',
              'ぽ' => 'po',
              'ゼ' => 'ze',
              'ま' => 'ma',
              'ソ' => 'so',
              'み' => 'mi',
              'ゾ' => 'zo',
              'む' => 'mu',
              'タ' => 'ta',
              'め' => 'me',
              'ダ' => 'da',
              'も' => 'mo',
              'チ' => 'chi',
              'ゃ' => 'xya',
              'ヂ' => 'dzi',
              'や' => 'ya',
              'ッ' => '*',
              'ゅ' => 'xyu',
              'ツ' => 'tsu',
              'ゆ' => 'yu',
              'ヅ' => 'dzu',
              'ょ' => 'xyo',
              'テ' => 'te',
              'よ' => 'yo',
              'デ' => 'de',
              'どぅ' => 'du',
              'ら' => 'ra',
              'ト' => 'to',
              'り' => 'ri',
              'ド' => 'do',
              'る' => 'ru',
              'ナ' => 'na',
              'れ' => 're',
              'ニ' => 'ni',
              'ろ' => 'ro',
              'ヌ' => 'nu',
              'ゎ' => 'xwa',
              'ネ' => 'ne',
              'わ' => 'wa',
              'ノ' => 'no',
              'ゐ' => 'wi',
              'ハ' => 'ha',
              'ゑ' => 'we',
              'バ' => 'ba',
              'を' => 'wo',
              'パ' => 'pa',
              'ん' => 'n\'',
              'ヒ' => 'hi',
              'ビ' => 'bi',
              'ピ' => 'pi',
              'フ' => 'fu',
              'つぁ' => 'tsa',
              'ブ' => 'bu',
              'チャ' => 'cha',
              'プ' => 'pu',
              'ヘ' => 'he',
              'チュ' => 'chu',
              'ベ' => 'be',
              'ペ' => 'pe',
              'チョ' => 'cho',
              'つぇ' => 'tse',
              'キェ' => 'kye',
              'ホ' => 'ho',
              'ボ' => 'bo',
              'つぉ' => 'tso',
              'ポ' => 'po',
              'マ' => 'ma',
              'ミ' => 'mi',
              'ム' => 'mu',
              'メ' => 'me',
              'モ' => 'mo',
              'ャ' => 'xya',
              'ヤ' => 'ya',
              'ュ' => 'xyu',
              'びゃ' => 'bya',
              'ディ' => 'di',
              'ユ' => 'yu',
              'ョ' => 'xyo',
              'ヨ' => 'yo',
              'びゅ' => 'byu',
              'ラ' => 'ra',
              'デェ' => 'dye',
              'リ' => 'ri',
              'びょ' => 'byo',
              'ル' => 'ru',
              'レ' => 're',
              'ロ' => 'ro',
              'ヮ' => 'xwa',
              'ワ' => 'wa',
              'ヰ' => 'wi',
              'ヱ' => 'we',
              'ヲ' => 'wo',
              'ン' => 'n\'',
              'ヴ' => 'vu',
              'ヵ' => 'xka',
              'ヶ' => 'xke',
              'シャ' => 'sha',
              'シュ' => 'shu',
              'ヂェ' => 'dze',
              'ショ' => 'sho',
              'ぴぇ' => 'pye',
              'キャ' => 'kya'
            );


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Lingua::JA::Romaji - Perl extension for romaji and kana conversion

=head1 SYNOPSIS

  use Lingua::JA::Romaji ':romajitokana,:kanatoromagi';

  &romajitokana(romaji, [hira|kata])
  &kanatoromaji(EUC-encoded kana)


=head1 DESCRIPTION

Transliterates from roman characters to kana syllables, and back again.

Given an EUC-encoded string of kana $kana, $roma=&kanatoromaji($kana)
will convert to Hepburn romaji.  Hiragana is converted to lower case,
ad katakana is converted to uppercase. Given a string of romaji, 
$kana=&romajitokana($roma,$kanatype) will convert to EUC-encoded kanji. 
If $kanatype matches the pattern /kata/i, it will be katakana, otherwise
it will be hiragana.

To change the romafication style, you can modify  the entries of
%Lingua::JA::Romaji::allkana.  Each key is a single kana, and each
value is the corresponding romaji equivalent.

=head1 EXPORT

None by default.

&romajitokana, &kanatoromaji are available with EXPORT_OK,
as are %hiragana and %katakana.

=head1 BUGS

When using &kanatoromaji($kana), $kana should contain only 
proper EUC-encoded kana of the form 0xA4 or 0xA5 followed by a
single byte.  

Care should be taken when modifying %Lingua::JA::Romaji::allkana
to avoid the strings /ix/i or /ux/i as they will be removed in conversion.

Conversion is not necessarily reversible.  This is because there can be
many romaji representations of given kana.

Certain morae, namely /v[aeiou]/, can only be represented with katakana,
and &romajitokana will produce katakana characters for these morae 
even in hiragana mode.  

Kanji is not implemented at all.  It is a non-trivial problem, and
beyond the scope of this module.  

Behavior on non-little endian machines for &kanatoromaji is not
yet known.

=head1 LICENSE

This is a derived work of Jim Breen's XJDIC, and as such is licensed
under the GNU General Public License, a copy of which was distributed
with perl.  
#'

=head1 AUTHOR

Jacob C. Kesinger  E<lt>kesinger@math.ttu.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut

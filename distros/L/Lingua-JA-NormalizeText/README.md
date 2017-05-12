# NAME

Lingua::JA::NormalizeText - All-in-One Japanese text normalizer

# SYNOPSIS

    use Lingua::JA::NormalizeText;
    use utf8;

    my @options = ( qw/nfkc decode_entities/, \&dearinsu_to_desu );
    my $normalizer = Lingua::JA::NormalizeText->new(@options);

    my $text = $normalizer->normalize('鳥が㌧㌦でありんす&hearts;'); # => '鳥がトンドルです♥'

    sub dearinsu_to_desu
    {
        my $text = shift;
        $text =~ s/でありんす/です/g;

        return $text;
    }

\# or

    use Lingua::JA::NormalizeText qw/old2new_kanji/;
    use utf8;

    my $text = old2new_kanji('惡の華'); # => '悪の華'

# DESCRIPTION

This module provides a lot of Japanese text normalization options.
These options facilitate Japanese text pre-processing.

# METHODS

## new(@options)

Creates a new Lingua::JA::NormalizeText instance.

The following options are available:

    OPTION                 SAMPLE INPUT           OUTPUT FOR SAMPLE INPUT
    ---------------------  ---------------------  -----------------------
    lc                     DdD                    ddd
    uc                     DdD                    DDD
    nfkc                   ｶﾞ                     ガ (U+30AC)
    nfkd                   ｶﾞ                     ガ (U+30AB. U+3099)
    nfc                    ド                     ド (U+30C9)
    nfd                    ド                     ド (U+30C8, U+3099)
    decode_entities        &hearts;               ♥
    strip_html             <em>あ</em>            あ
    alnum_z2h              ＡＢＣ１２３           ABC123
    alnum_h2z              ABC123                 ＡＢＣ１２３
    space_z2h              \x{3000}               \x{0020}
    space_h2z              \x{0020}               \x{3000}
    katakana_z2h           ハァハァ               ﾊｧﾊｧ
    katakana_h2z           ｽｰﾊｰｽｰﾊｰ               スーハースーハー
    katakana2hiragana      パンツ                 ぱんつ
    hiragana2katakana      ぱんつ                 パンツ
    wave2tilde             〜, 〰                 ～
    tilde2wave             ～                     〜
    wavetilde2long         〜, 〰, ～             ー
    wave2long              〜, 〰                 ー
    tilde2long             ～                     ー
    fullminus2long         －                     ー
    dashes2long            —                     ー
    drawing_lines2long     ─                     ー
    unify_long_repeats     ヴァーーー             ヴァー
    nl2space               (LF)(CR)(CRLF}         (space)(space)(space)
    unify_nl               (LF)(CR)(CRLF)         \n\n\n
    unify_long_spaces      あ(space)(space)あ     あ(space)あ
    unify_whitespaces      \x{00A0}               (space)
    trim                   (space)あ(space)あ(space)  あ(space)あ
    ltrim                  (space)あ(space)       あ(space)
    rtrim                  ああ(space)(space)     ああ
    old2new_kana           ゐヰゑヱヸヹ           いイえエイ゙エ゙
    old2new_kanji          亞逸鬭                 亜逸闘
    tab2space              (tab)(tab)             (space)(space)
    remove_controls        あ\x{0000}あ           ああ
    remove_DFC             \x{202E}HOGE           HOGE
    remove_spaces          \x{0020}あ\x{3000}あ\x{0020}  ああ
    dakuon_normalize       さ\x{3099}             ざ (U+3056)
    handakuon_normalize    は\x{309A}             ぱ (U+3071)
    all_dakuon_normalize   さ\x{3099}は\x{309A}   ざぱ (U+3056, U+3071)
    square2katakana        ㌢                     センチ
    circled2kana           ㋙㋛㋑㋟㋑             コシイタイ
    circled2kanji          ㊩㊫㊚㊒㊖             医学男有財
    decompose_parenthesized_kanji  ㈱             (株)

The order in which these options are applied is according to the order of
the elements of @options.
(i.e., The first element is applied first, and the last element is applied last.)

External functions can be added.
(See dearinsu\_to\_desu function of the SYNOPSIS section.)

## normalize($text)

normalizes $text.

# OPTIONS

## lc, uc

These options are the same as CORE::lc and CORE::uc.

## nfkc, nfkd, nfc, nfd

See [Unicode::Normalize](https://metacpan.org/pod/Unicode::Normalize).

## decode\_entities

See [HTML::Entities](https://metacpan.org/pod/HTML::Entities).

## strip\_html

Strips HTML tags.

## alnum\_z2h, alnum\_h2z

Converts English alphabet, numbers and symbols ZENKAKU <-> HANKAKU.

ZENKAKU:

    ！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞
    ？＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼
    ］＾＿｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ
    ｛｜｝～｟｠￠￡￢￣￤￥￦

HANKAKU:

    !"#$%&'()*+,-./0123456789:;<=>
    ?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\
    ]^_`abcdefghijklmnopqrstuvwxyz
    {|}~¢£¥¦¬¯₩⦅⦆

## space\_z2h, space\_h2z

SPACE (U+0020) <-> IDEOGRAPHIC SPACE (U+3000)

## katakana\_z2h, katakana\_h2z

Converts katakanas ZENKAKU <-> HANKAKU.

See [Lingua::JA::Regular::Unicode](https://metacpan.org/pod/Lingua::JA::Regular::Unicode).

## hiragana2katakana

INPUT:

    ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞ
    ただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼ
    ぽまみむめもゃやゅゆょよらりるれろゎわゐゑをんゔゕゖゝゞ

OUTPUT FOR INPUT:

    ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾ
    タダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボ
    ポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶヽヾ

## katakana2hiragana

INPUT:

    ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾ
    タダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボ
    ポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶヽヾ
    ｦｧｨｩｪｫｬｭｮｯｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ

OUTPUT FOR INPUT:

    ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞ
    ただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼ
    ぽまみむめもゃやゅゆょよらりるれろゎわゐゑをんゔゕゖゝゞ
    をぁぃぅぇぉゃゅょっあいうえおかきくけこさしすせそたちつてと
    なにぬねのはひふへほまみむめもやゆよらりるれろわん

## wave2tilde

Converts WAVE DASH (U+301C) and WAVY DASH (U+3030) into tilde (U+FF5E).

## tilde2wave

Converts tilde (U+FF5E) into wave (U+301C).

## wavetilde2long

Converts WAVE DASH (U+301C), WAVY DASH (U+3030) and tilde (U+FF5E) into long (U+30FC).

## wave2long

Converts WAVE DASH (U+301C) and WAVY DASH (U+3030) into long (U+30FC).

## tilde2long

Converts tilde (U+FF5E) into long (U+30FC).

## fullminus2long

Converts FULLWIDTH HYPHEN-MINUS (U+FF0D) into long (U+30FC).

## dashes2long

Converts the following characters into long (U+30FC).

    U+2012  FIGURE DASH
    U+2013  EN DASH
    U+2014  EM DASH
    U+2015  HORIZONTAL BAR

Note that this option does not convert hyphens into long.

## drawing\_line2long

Converts the following characters into long (U+30FC).

    U+2500  BOX DRAWINGS LIGHT HORIZONTAL
    U+2501  BOX DRAWINGS HEAVY HORIZONTAL
    U+254C  BOX DRAWINGS LIGHT DOUBLE DASH HORIZONTAL
    U+254D  BOX DRAWINGS HEAVY DOUBLE DASH HORIZONTAL
    U+2574  BOX DRAWINGS LIGHT LEFT
    U+2576  BOX DRAWINGS LIGHT RIGHT
    U+2578  BOX DRAWINGS HEAVY LEFT
    U+257A  BOX DRAWINGS HEAVY RIGHT

## unify\_long\_repeats

Unifies long (U+30FC) repeats.

## nl2space

Converts new lines (LF, CR, CRLF) into SPACE (U+0020).

## unify\_nl

Unifies new lines.

## unify\_long\_spaces

Unifies long spaces (U+0020 and U+3000).

## unify\_whitespaces

Converts the following characters into SPACE (U+0020).

    U+000B  LINE TABULATION
    U+000C  FORM FEED
    U+0085  NEXT LINE
    U+00A0  NO-BREAK SPACE
    U+1680  OGHAM SPACE MARK
    U+2000  EN QUAD
    U+2001  EM QUAD
    U+2002  EN SPACE
    U+2003  EM SPACE
    U+2004  THREE-PER-EM SPACE
    U+2005  FOUR-PER-EM SPACE
    U+2006  SIX-PER-EM SPACE
    U+2007  FIGURE SPACE
    U+2008  PUNCTUATION SPACE
    U+2009  THIN SPACE
    U+200A  HAIR SPACE
    U+2028  LINE SEPARATOR
    U+2029  PARAGRAPH SEPARATOR
    U+202F  NARROW NO-BREAK SPACE
    U+205F  MEDIUM MATHEMATICAL SPACE

Note that this option does not convert the following characters:

    U+0009  CHARACTER TABULATION
    U+000A  LINE FEED
    U+000D  CARRIAGE RETURN
    U+3000  IDEOGRAPHIC SPACE

## trim

Removes leading and trailing whitespace.

## ltrim

Removes only leading whitespace.

## rtrim

Removes only trailing whitespace.

## old2new\_kana

    INPUT  OUTPUT FOR INPUT
    -----  --------------------
    ゐ     い
    ヰ     イ
    ゑ     え
    ヱ     エ
    ヸ     イ゙ (U+30A4, U+3099)
    ヹ     エ゙ (U+30A8, U+3099)

## old2new\_kanji

INPUT:

    亞惡壓圍爲醫壹逸稻飮隱營榮衞驛謁圓緣艷鹽奧應橫歐毆黃溫穩假價
    禍畫會壞悔懷海繪慨槪擴殼覺學嶽樂喝渴褐勸卷寬歡漢罐觀關陷顏器
    既歸氣祈龜僞戲犧舊據擧虛峽挾狹鄕響曉勤謹區驅勳薰徑惠揭溪經繼
    莖螢輕鷄藝擊缺儉劍圈檢權獻硏縣險顯驗嚴效廣恆鑛號國穀黑濟碎齋
    劑櫻册殺雜參慘棧蠶贊殘祉絲視齒兒辭濕實舍寫煮社者釋壽收臭從澁
    獸縱祝肅處暑緖署諸敍奬將涉燒祥稱證乘剩壤孃條淨狀疊讓釀囑觸寢
    愼眞神盡圖粹醉隨髓數樞瀨聲靜齊攝竊節專戰淺潛纖踐錢禪曾祖僧雙
    壯層搜插巢爭瘦總莊裝騷增憎臟藏贈卽屬續墮體對帶滯臺瀧擇澤單嘆
    擔膽團彈斷癡遲晝蟲鑄著廳徵懲聽敕鎭塚遞鐵轉點傳都黨盜燈當鬭德
    獨讀突屆繩難貳惱腦霸廢拜梅賣麥發髮拔繁晚蠻卑碑祕濱賓頻敏甁侮
    福拂佛倂塀竝變邊勉辨瓣辯舖步穗寶襃豐墨沒飜每萬滿免麵默餠戾彌
    藥譯豫餘與譽搖樣謠來賴亂欄覽隆龍虜兩獵綠壘淚類勵禮隸靈齡曆歷
    戀練鍊爐勞廊朗樓郞錄灣堯巖晉槇渚猪琢瑤祐祿禎穰聰遙

OUTPUT FOR INPUT:

    亜悪圧囲為医壱逸稲飲隠営栄衛駅謁円縁艶塩奥応横欧殴黄温穏仮価
    禍画会壊悔懐海絵慨概拡殻覚学岳楽喝渇褐勧巻寛歓漢缶観関陥顔器
    既帰気祈亀偽戯犠旧拠挙虚峡挟狭郷響暁勤謹区駆勲薫径恵掲渓経継
    茎蛍軽鶏芸撃欠倹剣圏検権献研県険顕験厳効広恒鉱号国穀黒済砕斎
    剤桜冊殺雑参惨桟蚕賛残祉糸視歯児辞湿実舎写煮社者釈寿収臭従渋
    獣縦祝粛処暑緒署諸叙奨将渉焼祥称証乗剰壌嬢条浄状畳譲醸嘱触寝
    慎真神尽図粋酔随髄数枢瀬声静斉摂窃節専戦浅潜繊践銭禅曽祖僧双
    壮層捜挿巣争痩総荘装騒増憎臓蔵贈即属続堕体対帯滞台滝択沢単嘆
    担胆団弾断痴遅昼虫鋳著庁徴懲聴勅鎮塚逓鉄転点伝都党盗灯当闘徳
    独読突届縄難弐悩脳覇廃拝梅売麦発髪抜繁晩蛮卑碑秘浜賓頻敏瓶侮
    福払仏併塀並変辺勉弁弁弁舗歩穂宝褒豊墨没翻毎万満免麺黙餅戻弥
    薬訳予余与誉揺様謡来頼乱欄覧隆竜虜両猟緑塁涙類励礼隷霊齢暦歴
    恋練錬炉労廊朗楼郎録湾尭巌晋槙渚猪琢瑶祐禄禎穣聡遥

## tab2space

Converts CHARACTER TABULATION (U+0009) into SPACE (U+0020).

## remove\_controls

Removes the following control characters:

    U+0000 .. U+0008
    U+000B
    U+000C
    U+000E .. U+001F
    U+007F .. U+009F

Note that this option does not remove the following characters:

    U+0009  CHARACTER TABULATION
    U+000A  LINE FEED
    U+000D  CARRIAGE RETURN

## remove\_DFC

Removes the following Directional Formatting Characters:

    U+061C  ARABIC LETTER MARK
    U+2066  LEFT-TO-RIGHT ISOLATE
    U+2067  RIGHT-TO-LEFT ISOLATE
    U+2068  FIRST STRONG ISOLATE
    U+2069  POP DIRECTIONAL ISOLATE
    U+200E  LEFT-TO-RIGHT MARK
    U+200F  RIGHT-TO-LEFT MARK
    U+202A  LEFT-TO-RIGHT EMBEDDING
    U+202B  RIGHT-TO-LEFT EMBEDDING
    U+202C  POP DIRECTIONAL FORMATTING
    U+202D  LEFT-TO-RIGHT OVERRIDE
    U+202E  RIGHT-TO-LEFT OVERRIDE

See [http://www.unicode.org/reports/tr9/](http://www.unicode.org/reports/tr9/) for more information about Directional Formatting Characters.

## remove\_spaces

Removes SPACE (U+0020) and IDEOGRAPHIC SPACE (U+3000).

## dakuon\_normalize, handakuon\_normalize, all\_dakuon\_normalize

See [Lingua::JA::Dakuon](https://metacpan.org/pod/Lingua::JA::Dakuon).

Note that Lingua::JA::NormalizeText enables $Lingua::JA::Dakuon::EnableCombining flag.

## square2katakana, circled2kana, circled2kanji

See [Lingua::JA::Moji](https://metacpan.org/pod/Lingua::JA::Moji).

## decompose\_parenthesized\_kanji

Decomposes the following parenthesized kanji:

    ㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩㈪㈫㈬㈭㈮㈯㈰㈱㈲㈳㈴㈵㈶㈷㈸㈹㈺㈻㈼㈽㈾㈿㉀㉁㉂㉃

# AUTHOR

pawa <pawapawa@cpan.org>

# SEE ALSO

[新旧字体表](http://www.asahi-net.or.jp/~ax2s-kmtn/ref/old_chara.html)

[康熙字典](http://ja.wikipedia.org/wiki/%E5%BA%B7%E7%86%99%E5%AD%97%E5%85%B8)

[Lingua::JA::Regular::Unicode](https://metacpan.org/pod/Lingua::JA::Regular::Unicode)

[Lingua::JA::Dakuon](https://metacpan.org/pod/Lingua::JA::Dakuon)

[Lingua::JA::Moji](https://metacpan.org/pod/Lingua::JA::Moji)

[Unicode::Normalize](https://metacpan.org/pod/Unicode::Normalize)

[Unicode::Number](https://metacpan.org/pod/Unicode::Number)

[HTML::Entities](https://metacpan.org/pod/HTML::Entities)

[HTML::Scrubber](https://metacpan.org/pod/HTML::Scrubber)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

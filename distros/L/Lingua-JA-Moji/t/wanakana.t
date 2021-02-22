use FindBin '$Bin';
use lib "$Bin";
use LJMT;


is (romaji2hiragana ("IROHANIHOHETO"), "いろはにほへと", "Even the colorful fregrant flowers");
is (romaji2hiragana ("CHIRINURUWO"), "ちりぬるを", "Die sooner or later");
is (romaji2hiragana ("WAKAYOTARESO"), "わかよたれそ", "Us who live in this world");
is (romaji2hiragana ("TSUNENARAMU"), "つねならむ", "Cannot live forever, either.");
is (romaji2hiragana ("UWINOOKUYAMA"), "うゐのおくやま", "This transient mountain with shifts and changes,)");
is (romaji2hiragana ("KEFUKOETE"), "けふこえて", "Today we are going to overcome, and reach the world of enlightenment.");
is (romaji2hiragana ("ASAKIYUMEMISHI"), "あさきゆめみし", "We are not going to have meaningless dreams");
is (romaji2hiragana ("WEHIMOSESUN"), "ゑひもせすん", "nor become intoxicated with the fake world anymore");

is (romaji2hiragana ("babba"),   "ばっば", "double B");
#is (romaji2hiragana ("cacca"),   "cあっcあ", "double C");
is (romaji2hiragana ("chaccha"), "ちゃっちゃ", "double Ch");
is (romaji2hiragana ("dadda"),   "だっだ", "double D");
is (romaji2hiragana ("gagga"),   "がっが", "double G");
is (romaji2hiragana ("hahha"),   "はっは", "double H");
is (romaji2hiragana ("kakka"),   "かっか", "double K");
is (romaji2hiragana ("nanna"),   "なんな", "double N");
is (romaji2hiragana ("pappa"),   "ぱっぱ", "double P");
is (romaji2hiragana ("rarra"),   "らっら", "double R");
is (romaji2hiragana ("sassa"),   "さっさ", "double S");
is (romaji2hiragana ("shassha"), "しゃっしゃ", "double Sh");
is (romaji2hiragana ("tatta"),   "たった", "double T");
is (romaji2hiragana ("tsuttsu"), "つっつ", "double Ts");
is (romaji2hiragana ("zazza"),   "ざっざ", "double Z");

is (romaji2hiragana ("mamma"),   "まんま", "double M");
is (romaji2hiragana ("mamma", { ime => 1 } ),   "まっま", "double M IME style");

is (romaji2hiragana ("fuffu"),   "ふっふ", "double F");
is (romaji2hiragana ("jajja"),   "じゃっじゃ", "double J");
is (romaji2hiragana ("qaqqa"),   "くぁっくぁ", "double Q");
is (romaji2hiragana ("vavva"),   "ゔぁっゔぁ", "double V");
is (romaji2hiragana ("wawwa"),   "わっわ", "double W");
is (romaji2hiragana ("yayya"),   "やっや", "double Y");

is (romaji2hiragana ("aiueo"), romaji2hiragana ("AIUEO"), "cAse DoEsn'T MatTER for toHiragana ()");
is (romaji2kana ("aiueo"), romaji2kana ("AIUEO"), "cAse DoEsn'T MatTER for toKatakana ()");

is (romaji2hiragana ("n"), "ん", "Solo N");
is (romaji2hiragana ("onn"), "おん", "double N");
is (romaji2hiragana ("onna"), "おんな", "N followed by N* syllable");
is (romaji2hiragana ("nnn"), "んん", "Triple N");

is (romaji2hiragana ("onnna", { ime => 1 }, ), "おんな", "Triple N followed by N* syllable (IME mode)");
is (romaji2hiragana ("nnnn"), "んん", "Quadruple N");

is (romaji2hiragana ("nyan"), "にゃん", "nya -> にゃ");
# The original behaviour of wanakana was wrong for an ime.
is (romaji2hiragana ("nnnyann", { ime => 1 }), "んにゃん", "nnnyann -> んにゃん in IME mode");
is (romaji2hiragana ("nnnyannn"), "んにゃんん", "nnnya -> んにゃ");

my $opts = {wapuro => 1, style => 'hepburn'};

is (kana2romaji("ワニカニ ガ スゴイ ダ", $opts), "wanikani ga sugoi da", "Convert katakana to romaji");
is (kana2romaji("わにかに が すごい だ", $opts), "wanikani ga sugoi da", "Convert hiragana to romaji");
is (kana2romaji("ワニカニ が すごい だ", $opts), "wanikani ga sugoi da", "Convert mixed kana to romaji");
isnt (kana2romaji("わにかにがすごいだ", $opts), "wanikani ga sugoi da", "Spaces must be manually entered");

# Don't think this is right (?)
#    is (kana2romaji("ちりぬるを", $opts), "chirinuruwo", "Die sooner or later");
is (kana2romaji("ちりぬるを", {%$opts, wo => 1}), "chirinuruwo",
    "Die sooner or later");
is (kana2romaji("ちりぬるを", {%$opts, wo => 0}), "chirinuruo",
    "Die sooner or later");

is (kana2romaji("いろはにほへと", $opts), "irohanihoheto", "Even the colorful fregrant flowers");
is (kana2romaji("わかよたれそ", $opts), "wakayotareso", "Us who live in this world");
is (kana2romaji("つねならむ", $opts), "tsunenaramu", "Cannot live forever, either.");
is (kana2romaji("うゐのおくやま", $opts), "uwinookuyama", "This transient mountain with shifts and changes,)");
is (kana2romaji("けふこえて", $opts), "kefukoete", "Today we are going to overcome, and reach the world of enlightenment.");
is (kana2romaji("あさきゆめみし", $opts), "asakiyumemishi", "We are not going to have meaningless dreams");
is (kana2romaji("ゑひもせすん", $opts), "wehimosesun", "nor become intoxicated with the fake world anymore");
is (kana2romaji("きんにくまん", $opts), "kinnikuman", "Double and single n");
is (kana2romaji("んんにんにんにゃんやん", $opts), "nnninninnyan'yan", "N extravaganza");
done_testing ();


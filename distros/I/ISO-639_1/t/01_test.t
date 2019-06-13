use strict;
use Test::More 0.98;

use ISO::639_1;

is(get_iso639_1('en')->{nativeName}, 'English',              'en native name, without localisation');
is(get_iso639_1('fr')->{nativeName}, 'Français',             'fr native name, without localisation');
is(get_iso639_1('ab')->{nativeName}, 'аҧсуа бызшәа, аҧсшәа', 'ab native name, without localisation');
is(get_iso639_1('English'),          undef,                  'Badly formatted code should return undef');

is(get_iso639_1('en-us')->{nativeName}, 'English (US)',  'en-us native name, with localisation');
is(get_iso639_1('fr_BE')->{nativeName}, 'Français (BE)', 'fr_BE native name, with localisation');
is(get_iso639_1('fr+FR'),               undef,           'Badly formatted localized code should return undef');

is(get_iso639_1('fr')->{nativeName}, 'Français', 'Check that we didn\'t change the codes hash table (ie don\'t use refs)');

is_deeply(get_iso639_1('zh'), {
        "639-1"      => "zh",
        "639-2"      => "zho",
        "639-2/B"    => "chi",
        "family"     => "Sino-Tibetan",
        "name"       => "Chinese",
        "nativeName" => "中文 (Zhōngwén), 汉语, 漢語",
        "wikiUrl"    => "https://en.wikipedia.org/wiki/Chinese_language"
    }, 'zh native name, full structure');

done_testing;

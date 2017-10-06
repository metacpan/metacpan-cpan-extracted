use strict;
use warnings;
use utf8;
use Test::More;
use Emoji::NationalFlag qw/ code2flag flag2code /;
use Encode;
use Locale::Country;

subtest convert => sub {
    is code2flag('jp'), "🇯🇵";
    is code2flag('jp'), "\x{1F1EF}\x{1F1f5}";

    is flag2code("🇯🇵"), 'jp';
    is flag2code("\x{1F1EF}\x{1F1f5}"), 'jp';
};

subtest 'encoded utf8 is not valid' => sub {
    is flag2code(encode_utf8 "🇯🇵"), undef;
};

subtest 'all pattern' => sub {
    for (all_country_codes()) {
        is flag2code(code2flag($_)), $_;
    }
};

done_testing;

#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING} or plan(
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.'
);

my @data = (
    {
        test   => '02_filter',
        path   => 'example',
        script => '-I../lib -T 02_filter.pl',
        result => <<'EOT',
Hello World 1! filter added: i-default
Hello World 2! filter added: i-default
EOT
    },
    {
        test   => '03_language_of_languages',
        path   => 'example',
        script => '-I../lib -T 03_language_of_languages.pl',
        result => <<'EOT',
i-default
Lexicon "de::" loaded from hash.
de
EOT
    },
    {
        test   => '05_expand_gettext_modifier',
        path   => 'example',
        script => '-I../lib -T 05_expand_gettext_modifier.pl',
        result => <<'EOT',
Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="{count :num} EUR".
Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="{count :num} EUR".
language is i-default
12,345,678.90 EUR
language set to de
12.345.678,90 EUR
modifier deleted
12345678.90 EUR
EOT
    },
    {
        test   => '06_expand_maketext_formatter_code',
        path   => 'example',
        script => '-I../lib -T 06_expand_maketext_formatter_code.pl',
        result => <<'EOT',
Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="[*,_1,EUR]".
Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="[*,_1,EUR]".
language is i-default
12,345,678.90 EUR
language set to de
12.345.678,90 EUR
formatter_code deleted
12345678.90 EUR
EOT
    },
    {
        test   => '11_gettext_hash',
        path   => 'example',
        script => '-I../lib -T 11_gettext_hash.pl',
        result => <<'EOT',
debug: Lexicon "de:LC_MESSAGES:example" loaded from hash.
warn: Using lexicon "de:LC_MESSAGES:example". msgstr not found for msgctxt=undef, msgid="not existing text".
not existing text
Das ist ein Text.
Steffen programmiert Perl.
Steffen programmiert {language}.
Einzahl
Mehrzahl
1 Regal
2 Regale
Sehr geehrter
Sehr geehrter Steffen Winkler
Date
Dates
Das ist 1 Date.
Das sind 2 Dates.
EOT
    },
    {
        test   => '11_gettext_loc_hash',
        path   => 'example',
        script => '-I../lib -T 11_gettext_loc_hash.pl',
        result => <<'EOT',
debug: Lexicon "de:LC_MESSAGES:example" loaded from hash.
warn: Using lexicon "de:LC_MESSAGES:example". msgstr not found for msgctxt=undef, msgid="not existing text".
not existing text
Das ist ein Text.
Steffen programmiert Perl.
Steffen programmiert {language}.
Einzahl
Mehrzahl
1 Regal
2 Regale
Sehr geehrter
Sehr geehrter Steffen Winkler
Date
Dates
Das ist 1 Date.
Das sind 2 Dates.
EOT
    },
    {
        test   => '11_gettext_named_hash',
        path   => 'example',
        script => '-I../lib -T 11_gettext_named_hash.pl',
        result => <<'EOT',
debug: Lexicon "de:LC_MESSAGES:example" loaded from hash.
warn: Using lexicon "de:LC_MESSAGES:example". msgstr not found for msgctxt=undef, msgid="not existing text".
not existing text
Das ist ein Text.
Steffen programmiert Perl.
Steffen programmiert {language}.
Einzahl
Mehrzahl
1 Regal
2 Regale
Sehr geehrter
Sehr geehrter Steffen Winkler
Date
Dates
Das ist 1 Date.
Das sind 2 Dates.
EOT
    },
    {
        test   => '15_gettext_N__',
        path   => 'example',
        script => '-I../lib -T 15_gettext_N__.pl',
        result => <<'EOT',
__: This is a text.
__x: Steffen is programming Perl.
__n: Singular
__nx: 1 shelf
__p: Dear
__px: Dear Steffen Winkler
__np: date
__npx: 1 date
EOT
    },
    {
        test   => '15_gettext_Nloc_',
        path   => 'example',
        script => '-I../lib -T 15_gettext_Nloc_.pl',
        result => <<'EOT',
loc_: This is a text.
loc_x: Steffen is programming Perl.
loc_n: Singular
loc_nx: 1 shelf
loc_p: Dear
loc_px: Dear Steffen Winkler
loc_np: date
loc_npx: 1 date
EOT
    },
    {
        test   => '18_autotranslation_cached',
        path   => 'example',
        script => '-I../lib -T 18_autotranslation_cached.pl',
        result => <<'EOT',
Lexicon "de:cache_en:" loaded from file "LocaleData/de/cache_en/example.po".
statisch
nicht im po File
EOT
    },
    {
        test   => '22_loc_mo_style_gettext',
        path   => 'example',
        script => '-I../lib -T 22_loc_mo_style_gettext.pl',
        result => <<'EOT',
Lexicon "de:LC_MESSAGES:example_maketext_style_gettext" loaded from file "LocaleData/de/LC_MESSAGES/example_maketext_style_gettext.mo".
Das ist ein Text.
§ Buch
Steffen programmiert Perl.
1 Regal
2 Regale
Sehr geehrter
Sehr geehrter Steffen Winkler
Das ist/sind 1 Date.
Das ist/sind 2 Dates.
kein Regal
1 Regal
2 Regale
book
appointment
date
EOT
    },
    {
        test   => '41_tied_interface',
        path   => 'example',
        script => '-I../lib -T 41_tied_interface.pl',
        result => <<'EOT',
Lexicon "de:LC_MESSAGES:example" loaded from file "LocaleData/de/LC_MESSAGES/example.mo".
Lexicon "ru:LC_MESSAGES:example" loaded from file "LocaleData/ru/LC_MESSAGES/example.mo".
Lexicon "de:LC_MESSAGES:example_maketext" loaded from file "LocaleData/de/LC_MESSAGES/example_maketext.mo".
Das ist ein Text.
Das ist ein Text.
Das ist ein Text.
Das ist ein Text.
Steffen programmiert Perl.
Steffen programmiert Perl.
Einzahl
Mehrzahl
1 Regal
2 Regale
Sehr geehrter
Sehr geehrter
Sehr geehrter Steffen Winkler
Sehr geehrter Steffen Winkler
Date
Dates
Das ist 1 Date.
Das sind 2 Dates.
text
singular;plural;1
example
LC_MESSAGES
my_domain
my_category
Das sind 3 Dates.
my_domain
my_category
example
LC_MESSAGES
example_maketext
LC_MESSAGES
Das ist/sind 1 Date.
appointment;This is/are [*,_1,date,dates].;2
example_maketext
LC_MESSAGES
example
LC_MESSAGES
EOT
    },
    {
        test   => '42_functional_interface',
        path   => 'example',
        script => '-I../lib -T 42_functional_interface.pl',
        result => <<'EOT',
Lexicon "de:LC_MESSAGES:example" loaded from file "LocaleData/de/LC_MESSAGES/example.mo".
Lexicon "ru:LC_MESSAGES:example" loaded from file "LocaleData/ru/LC_MESSAGES/example.mo".
Lexicon "de:LC_MESSAGES:example_maketext" loaded from file "LocaleData/de/LC_MESSAGES/example_maketext.mo".
Das ist ein Text.
Steffen programmiert Perl.
Einzahl
Mehrzahl
1 Regal
2 Regale
Sehr geehrter
Sehr geehrter Steffen Winkler
Date
Dates
Das ist 1 Date.
Das sind 2 Dates.
text
singular
plural
1
my_domain
my_category
Das sind 3 Dates.
my_domain
my_category
example
LC_MESSAGES
Das ist/sind 1 Date.
appointment
This is/are [*,_1,date,dates].
2
EOT
    },
);

plan tests => 0 + @data;

for my $data (@data) {
    my $dir = getcwd;
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);
    $result =~ tr{\\}{/};
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}

#!perl -T

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Differences;
use Path::Tiny qw(path);

$ENV{AUTHOR_TESTING}
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';
plan tests => 12;
require Test::NoWarnings;
Test::NoWarnings->import;

use_ok('Locale::TextDomain::OO::Extract::Perl');
use_ok('Locale::TextDomain::OO::Extract::Process');

my @languages = qw( de de-at );
my $category  = 'LC_MESSAGES';
my @domains   = qw( test1 test2 );
my %suffix_of = qw( test1 po test2 mo );

my $process = Locale::TextDomain::OO::Extract::Process->new(
    category => $category, # in this test unchanged
);
$process->add_plugin(mo => 'MO');

for my $domain (@domains) {
    $process->domain($domain); # in this test changed then not in constructor
    for my $language (@languages) {
        $process->language($language);  # in this test changed then not in constructor
        $process->slurp( $suffix_of{$domain} => "./t/LocaleData/$language/$category/$domain.$suffix_of{$domain}" );
    }
}

my $expected_lexicon_ref = {
    'de-at:LC_MESSAGES:test1' => {
        q{} => {
            msgstr => <<"EOT",
Project-Id-Version:\x20
POT-Creation-Date:\x20
PO-Revision-Date:\x20
Last-Translator:\x20
Language-Team:\x20
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=n != 1;
EOT
            nplurals => 2,
            plural => 'n != 1',
        },
        January => {
            automatic => 'automatic 2
automatic 1',
            comment => 'comment 2
comment 1',
            msgstr => 'Jänner',
            reference => 'old/file.pl:3 old/file.pl:2
old/file.pl:1
old/file.pl:456',
        },
    },
    'de-at:LC_MESSAGES:test2' => {
        q{} => {
            msgstr => <<"EOT",
Project-Id-Version:\x20
POT-Creation-Date:\x20
PO-Revision-Date:\x20
Last-Translator: xxxxxxx xxxxxxx <xxxxxxx.xxxxxxx\@xxxxxx.xxx>
Language-Team:\x20
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=n != 1;
EOT
            nplurals => 2,
            plural => 'n != 1',
        },
        January => {
            msgstr => 'Jänner',
        },
    },
    'de:LC_MESSAGES:test1' => {
        q{} => {
            msgstr => <<"EOT",
Project-Id-Version:\x20
POT-Creation-Date:\x20
PO-Revision-Date:\x20
Last-Translator:\x20
Language-Team:\x20
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=n != 1;
EOT
            nplurals => 2,
            plural => 'n != 1',
        },
        January => {
            automatic => 'automatic 2
automatic 1',
            comment => 'comment 2
comment 1',
            msgstr => 'Januar',
            reference => 'old/file.pl:3 old/file.pl:2
old/file.pl:1
old/file.pl:456',
        },
        "This car is damaged.\x00This cars are damaged." => {
            msgstr_plural => [
                'Dieses Auto ist beschädigt.',
                'Diese Autos sind beschädigt.',
            ],
            reference => 'old/file.pl:1',
        },
        date => {
            msgstr => 'Datum',
            reference => 'old/file.pl:1',
        },
        "date\x04appointment" => {
            msgstr => 'Date',
            reference => 'old/file.pl:1',
        },
    },
    'de:LC_MESSAGES:test2' => {
        q{} => {
            msgstr => <<"EOT",
Project-Id-Version:\x20
POT-Creation-Date:\x20
PO-Revision-Date:\x20
Last-Translator: xxxxxxx xxxxxxx <xxxxxxx.xxxxxxx\@xxxxxx.xxx>
Language-Team:\x20
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=n != 1;
EOT
            nplurals => 2,
            plural => 'n != 1',
        },
        January => {
            msgstr => 'Januar',
        },
        "This car is damaged.\x00This cars are damaged." => {
            msgstr_plural => [
                'Dieses Auto ist beschädigt.',
                'Diese Autos sind beschädigt.',
            ],
        },
        date => {
            msgstr => 'Datum',
        },
        "date\x04appointment" => {
            msgstr => 'Date',
        },
    },
};
eq_or_diff
    $process->lexicon_ref,
    $expected_lexicon_ref,
    'data of file';

# a little helper
sub newline { my $text = shift; $text =~ s{\r}{}xmsg; return $text }

# write files for test only
for my $domain (@domains) {
    $process->domain($domain);
    for my $language (@languages) {
        $process->language($language);
        $process->spew( $suffix_of{$domain} => "./1st_${language}_$domain.$suffix_of{$domain}" );

        my $slurp_method = $suffix_of{$domain} eq 'po'
            ? 'slurp_utf8'
            : 'slurp_raw';
        eq_or_diff
            newline( path("./1st_${language}_$domain.$suffix_of{$domain}")->$slurp_method ),
            newline( path("./t/LocaleData/$language/$category/1st_${domain}_expected.$suffix_of{$domain}")->$slurp_method ),
           "${language}_$domain.$suffix_of{$domain}";
    }
}

# Stop with domain test2 here. Read/write PO/MO files is tested.

$process->remove_all_reference;
$process->remove_all_automatic;

# Extract source files here.
my $extract = Locale::TextDomain::OO::Extract::Perl->new;
$extract->clear;
$extract->category($category);
$extract->domain( $domains[0] );
my $file = path('./t/files_to_extract_for_process/gettext_loc.pl');
$extract->filename( $file->relative( q{./} )->stringify );
$extract->content_ref( \( $file->slurp_utf8 ) );
$extract->extract;

# Merge extract
# or put the extracted data with no language (i-default)
# to all processed languages.
$process->domain( $domains[0] );
for my $language (@languages) {
    $process->language($language);
    $process->merge_extract({
        lexicon_ref       => $extract->lexicon_ref,
        category          => $category,
        domain            => $domains[0],
        skip_new_messages => $language eq 'de-at',
    });
}

# Normally write into the same files like read at first.
$process->domain( $domains[0] );
for my $language (@languages) {
    $process->language($language);
    $process->spew(po => "./2nd_${language}_$domains[0]_no_or_new_ref.po");

    eq_or_diff
        newline( path("./2nd_${language}_$domains[0]_no_or_new_ref.po")->slurp_utf8 ),
        newline( path("./t/LocaleData/$language/$category/2nd_$domains[0]_expected_no_or_new_ref.po")->slurp_utf8 ),
        "${language}_$domains[0]_no_or_new_ref.po";
}

# Normally here
# * translation (change PO file msgstr's)
# * read files agian
# so recreate lexicon_ref

# clean
$process->remove_all_non_referenced;
$process->domain( $domains[0] );
for my $language (@languages) {
    $process->language($language);
    $process->spew(po => "./3rd_${language}_$domains[0]_clean.po");

    eq_or_diff
        newline( path("./3rd_${language}_$domains[0]_clean.po")->slurp_utf8 ),
        newline( path("./t/LocaleData/$language/$category/3rd_$domains[0]_expected_clean.po")->slurp_utf8 ),
        "${language}_$domains[0]_clean.po";
}

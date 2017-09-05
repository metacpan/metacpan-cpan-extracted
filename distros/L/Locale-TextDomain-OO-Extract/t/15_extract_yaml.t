#!perl -T

use strict;
use warnings;

use Test::More tests => 8;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;
use Path::Tiny qw(path);

BEGIN {
    use_ok('Locale::TextDomain::OO::Extract::YAML');
}

my $extractor;
lives_ok
    sub {
        $extractor = Locale::TextDomain::OO::Extract::YAML->new;
    },
    'create extractor object';

for ( qw( babelfish_loc gettext gettext_loc maketext_loc ) ) {
    lives_ok
        sub {
            $extractor->filename("${_}.yml");
            $extractor->content_ref(
                \( path("./t/files_to_extract/${_}.yml")->slurp_raw ),
            );
            $extractor->extract;
        },
        "extract ${_}.yml";
}

my $expected_lexicon_ref = {
    'i-default::' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        ' ' => {
            reference => {
                'babelfish_loc.yml:21' => undef,
                'gettext.yml:21' => undef,
                'gettext_loc.yml:21' => undef,
                'maketext_loc.yml:21' => undef,
            },
        },
        Password => {
            reference => {
                'babelfish_loc.yml:15' => undef,
                'gettext.yml:15' => undef,
                'gettext_loc.yml:15' => undef,
                'maketext_loc.yml:15' => undef,
            },
        },
        Username => {
            reference => {
                'babelfish_loc.yml:10' => undef,
                'gettext.yml:10' => undef,
                'gettext_loc.yml:10' => undef,
                'maketext_loc.yml:10' => undef,
            },
        },
        login => {
            reference => {
                'babelfish_loc.yml:23' => undef,
                'gettext.yml:23' => undef,
                'gettext_loc.yml:23' => undef,
                'maketext_loc.yml:23' => undef,
            },
        },
    },
};
eq_or_diff
    $extractor->lexicon_ref,
    $expected_lexicon_ref,
    'data of file';

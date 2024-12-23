#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;
use Path::Tiny qw(path);

BEGIN {
    use_ok('Locale::TextDomain::OO::Extract::HTML');
}

my $extractor;
lives_ok
    sub {
        $extractor = Locale::TextDomain::OO::Extract::HTML->new;
    },
    'create extractor object';

for ( qw( gettext gettext_loc maketext_loc ) ) {
    lives_ok
        sub {
            $extractor->filename("${_}.html");
            $extractor->content_ref(
                \( path("./t/files_to_extract/${_}.html")->slurp_raw ),
            );
            $extractor->extract;
        },
        "extract ${_}.html";
}

my $expected_lexicon_ref = {
    'i-default::' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        'This is a p text.' => {
            reference => {
                'gettext.html:8' => undef,
                'gettext_loc.html:8' => undef,
                'maketext_loc.html:8' => undef,
            },
        },
        'This is an a text.' => {
            reference => {
                'gettext.html:10' => undef,
                'gettext.html:13' => undef,
                'gettext_loc.html:10' => undef,
                'gettext_loc.html:16' => undef,
                'maketext_loc.html:10' => undef,
                'maketext_loc.html:13' => undef,
            },
        },
        "This is an a text.\x04context1 context2" => {
            reference => {
                'gettext_loc.html:13' => undef,
                'gettext_loc.html:17' => undef,
            },
        },
        'my placeholder' => {
            reference => {
                'gettext.html:19' => undef,
                'gettext.html:20' => undef,
                'gettext_loc.html:23' => undef,
                'gettext_loc.html:24' => undef,
                'maketext_loc.html:19' => undef,
                'maketext_loc.html:20' => undef,
            },
        },
        'my title' => {
            reference => {
                'gettext.html:15' => undef,
                'gettext.html:16' => undef,
                'gettext_loc.html:19' => undef,
                'gettext_loc.html:20' => undef,
                'maketext_loc.html:15' => undef,
                'maketext_loc.html:16' => undef,
            },
        },
        'my value' => {
            reference => {
                'gettext.html:14' => undef,
                'gettext.html:17' => undef,
                'gettext.html:18' => undef,
                'gettext_loc.html:18' => undef,
                'gettext_loc.html:21' => undef,
                'gettext_loc.html:22' => undef,
                'maketext_loc.html:14' => undef,
                'maketext_loc.html:17' => undef,
                'maketext_loc.html:18' => undef,
            },
        },
    },
};
eq_or_diff
    $extractor->lexicon_ref,
    $expected_lexicon_ref,
    'data of file';

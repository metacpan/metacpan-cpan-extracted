#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 8;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences; local $Data::Dumper::Useperl = 1;
use Path::Tiny qw(path);

BEGIN {
    use_ok('Locale::TextDomain::OO::Extract::TT');
}

my $extractor;
lives_ok
    sub {
        $extractor = Locale::TextDomain::OO::Extract::TT->new;
    },
    'create extractor object';

for ( qw( babelfish_loc gettext gettext_loc maketext_l ) ) {
    lives_ok
        sub {
            $extractor->filename("$_.tt");
            $extractor->content_ref(
                \( path("./t/files_to_extract/$_.tt")->slurp_utf8 ),
            );
            $extractor->extract;
        },
        'extract $_.tt';
}

my $expected_lexicon_ref = {
    'i-default::' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        '#{name} is programming #{language}.' => {
            automatic => q{name => 'Steffen', language => 'Perl',},
            reference => {
                'babelfish_loc.tt:22' => undef,
            },
        },
        '#{num :num} ((date|dates))' => {
        automatic => 'num => 2,',
            reference => {
                'babelfish_loc.tt:39' => undef,
            },
        },
        '#{num} ((date|dates)):num' => {
            automatic => 'num => 1,',
            reference => {
                'babelfish_loc.tt:35' => undef,
            },
        },
        "#{num} date\x04appointment" => {
            automatic => 'num => 1,',
            reference => {
                'babelfish_loc.tt:47' => undef,
            },
        },
        '((Singular|Plural))' => {
            automatic => '1,',
            reference => {
                'babelfish_loc.tt:27' => undef,
                'babelfish_loc.tt:31' => undef,
            },
        },
        "((date|dates))\x04appointment" => {
            automatic => '1,',
            reference => {
                'babelfish_loc.tt:52' => undef,
                'babelfish_loc.tt:57' => undef,
            },
        },
        "Singular\x00Plural" => {
            automatic => 1,
            reference => {
                'gettext.tt:27' => undef,
                'gettext.tt:32' => undef,
                'gettext_loc.tt:27' => undef,
                'gettext_loc.tt:32' => undef,
            },
        },
        'Text Ä' => {
            reference => {
                'babelfish_loc.tt:9' => undef,
                'gettext.tt:9' => undef,
                'gettext_loc.tt:9' => undef,
                'maketext_l.tt:9' => undef,
            },
        },
        'Text Ö' => {
            reference => {
                'babelfish_loc.tt:13' => undef,
                'gettext.tt:13' => undef,
                'gettext_loc.tt:13' => undef,
                'maketext_l.tt:13' => undef,
            },
        },
        'Text Ü' => {
            reference => {
                'babelfish_loc.tt:16' => undef,
                'gettext.tt:16' => undef,
                'gettext_loc.tt:16' => undef,
                'maketext_l.tt:16' => undef,
            },
        },
        'This is a text.' => {
            reference => {
                'babelfish_loc.tt:21' => undef,
                'gettext.tt:21' => undef,
                'gettext_loc.tt:21' => undef,
            },
        },
        "date\x00dates\x04appointment" => {
            automatic => 1,
            reference => {
                'gettext.tt:58' => undef,
                'gettext.tt:64' => undef,
                'gettext_loc.tt:58' => undef,
                'gettext_loc.tt:64' => undef,
            },
        },
        "date\x04appointment" => {
            reference => {
                'babelfish_loc.tt:43' => undef,
                'gettext.tt:49' => undef,
                'gettext_loc.tt:49' => undef,
            },
        },
        '{name} is programming {language}.' => {
            automatic => q{name => 'Steffen', language => 'Perl',},
            reference => {
                'gettext.tt:22' => undef,
                'gettext_loc.tt:22' => undef,
            },
        },
        "{num} date\x00{num} dates" => {
            automatic => '1, num => 1,',
            reference => {
                'gettext.tt:37' => undef,
                'gettext.tt:43' => undef,
                'gettext_loc.tt:37' => undef,
                'gettext_loc.tt:43' => undef,
            },
        },
        "{num} date\x00{num} dates\x04appointment" => {
            automatic => '1, num => 1,',
            reference => {
                'gettext.tt:70' => undef,
                'gettext.tt:77' => undef,
                'gettext_loc.tt:70' => undef,
                'gettext_loc.tt:77' => undef,
            },
        },
        "{num} date\x04appointment" => {
            automatic => 'num => 1,',
            reference => {
                'gettext.tt:53' => undef,
                'gettext_loc.tt:53' => undef,
            },
        },
    },
};
eq_or_diff
    $extractor->lexicon_ref,
    $expected_lexicon_ref,
    'data of file';

#!perl -T

use strict;
use warnings;

use Test::More tests => 12;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;
use Path::Tiny qw(path);

BEGIN {
    use_ok('Locale::TextDomain::OO::Extract::Perl');
}

my $extractor;
lives_ok
    sub {
        $extractor = Locale::TextDomain::OO::Extract::Perl->new(
            filter      => [ qw(
                BabelFish::Loc
                BabelFish::Loc::DomainAndCategory
            ) ],
        );
    },
    'create extractor object';

{
    my $content = "1\n=pod\n3\n=cut\n5\n__END__\n7\n";
    $extractor->content_ref(\$content);
    # remove POD and all after __END__
    $extractor->preprocess;
    eq_or_diff
       $content,
        "1\n\n\n\n5\n",
        'check default preprocess';
}

for ( qw( babelfish_loc gettext gettext_loc maketext maketext_loc maketext_localise maketext_localize ) ) {
    lives_ok
        sub {
            $extractor->filename("$_.pl");
            $extractor->content_ref(
                \( path("./t/files_to_extract/$_.pl")->slurp_raw ),
            );
            $extractor->extract;
        },
        "extract $_.pl";
}

my $expected_lexicon_ref = {
    'i-default::' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural   => 'n != 1',
            },
        },
        '#{count :num} ((date|dates))' => {
            automatic => '1,',
            reference => {
                'babelfish_loc.pl:32' => undef,
                'babelfish_loc.pl:36' => undef,
            },
        },
        '#{name} is programming #{language}.' => {
            automatic => q{name => 'Steffen', language => 'Perl',},
            reference => {
                'babelfish_loc.pl:19' => undef,
            },
        },
        "#{num} ((date|dates)):num\x04appointment" => {
            automatic => 'num => 1,',
            reference => {
                'babelfish_loc.pl:59' => undef,
                'babelfish_loc.pl:64' => undef,
            },
        },
        "#{num} date\x04appointment" => {
            automatic => 'num => 1,',
            reference => {
                'babelfish_loc.pl:44' => undef,
            },
        },
        "' quoted text with \\\\." => {
            reference => {
                'babelfish_loc.pl:72' => undef,
            },
        },
        '((Singular|Plural))' => {
            automatic => '1,',
            reference => {
                'babelfish_loc.pl:24' => undef,
                'babelfish_loc.pl:28' => undef,
            },
        },
        "((date|dates)):num\x04appointment" => {
            automatic => 'num => 1,',
            reference => {
                'babelfish_loc.pl:49' => undef,
                'babelfish_loc.pl:54' => undef,
            },
        },
        'This is a text.' => {
            reference => {
                'babelfish_loc.pl:16' => undef,
            },
        },
        'category c' => {
            reference => {
                'babelfish_loc.pl:100' => undef,
            },
        },
        "date\x04appointment" => {
            reference => {
                'babelfish_loc.pl:40' => undef,
            },
        },
        'quoted text.' => {
            reference => {
                'babelfish_loc.pl:78' => undef,
            },
        },
        'q{ quoted text with #{placeholders}}.' => {
            reference => {
                'babelfish_loc.pl:75' => undef,
            },
        },
        'text of domain d and category c' => {
            reference => {
                'babelfish_loc.pl:101' => undef,
                'babelfish_loc.pl:107' => undef,
            },
        },
        'text of domain d and no category' => {
            reference => {
                'babelfish_loc.pl:99' => undef,
            },
        },
        'text of no domain and category c' => {
            reference => {
                'babelfish_loc.pl:103' => undef,
            },
        },
        'text of no domain and no category' => {
            reference => {
                'babelfish_loc.pl:105' => undef,
                'babelfish_loc.pl:109' => undef,
                'babelfish_loc.pl:97' => undef
            },
        },
    },
    'i-default::domain d' => {
        q{} => {
            msgstr   => {
                nplurals => 2,
                plural   => 'n != 1',
            },
            reference => {
                'babelfish_loc.pl:98' => undef,
            },
        },
        "((singular dp|plural dp))\x04context dp" => {
            automatic => 0,
            reference => {
                'babelfish_loc.pl:86' => undef,
            },
        },
        '((singular d|plural d))' => {
            automatic => 0,
            reference => {
                'babelfish_loc.pl:85' => undef,
            },
        },
        'category c' => {
            reference => {
                'babelfish_loc.pl:106' => undef,
            },
        },
        'text d' => {
            reference => {
                'babelfish_loc.pl:83' => undef,
            },
        },
        "text dp\x04context dp" => {
            reference => {
                'babelfish_loc.pl:84' => undef,
            },
        },
    },
    'i-default:category c:' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural   => 'n != 1',
            },
        },
        "((singular cp|plural cp))\x04context cp" => {
            automatic => 0,
            reference => {
                'babelfish_loc.pl:90' => undef,
            },
        },
        '((singular c|plural c))' => {
            automatic => 0,
            reference => {
                'babelfish_loc.pl:88' => undef,
            },
        },
        'text c' => {
            reference => {
                'babelfish_loc.pl:87' => undef,
            },
        },
        "text cp\x04context cp" => {
            reference => {
                'babelfish_loc.pl:89' => undef,
            },
        },
    },
    'i-default:category c:domain d' => {
        q{} => {
            msgstr   => {
                nplurals => 2,
                plural   => 'n != 1',
            },
        },
        "((singular dcp|plural dcp))\x04context dcp" => {
            automatic => 0,
            reference => {
                'babelfish_loc.pl:94' => undef,
            },
        },
        '((singular dc|plural dc))' => {
            automatic => 0,
            reference => {
                'babelfish_loc.pl:92' => undef,
            },
        },
        'text dc' => {
            reference => {
                'babelfish_loc.pl:91' => undef,
            },
        },
        "text dcp\x04context dcp" => {
            reference => {
                'babelfish_loc.pl:93' => undef,
            },
        },
    },
};
eq_or_diff
    $extractor->lexicon_ref,
    $expected_lexicon_ref,
    'data of both files';

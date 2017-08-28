#!perl -T

use strict;
use warnings;

use Test::More tests => 11;
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
        $extractor = Locale::TextDomain::OO::Extract::Perl->new;
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

for ( qw( gettext gettext_loc maketext maketext_loc maketext_localise maketext_localize ) ) {
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
                plural => 'n != 1',
            },
        },
        "' quoted text with \\\\." => {
            reference => {
                'gettext.pl:83' => undef,
                'gettext_loc.pl:93' => undef,
            },
        },
        "Singular\x00Plural" => {
            automatic => '1',
            reference => {
                'gettext.pl:24' => undef,
                'gettext.pl:29' => undef,
                'gettext_loc.pl:24' => undef,
                'gettext_loc.pl:29' => undef,
            },
        },
        'This is a text.' => {
            reference => {
                'gettext.pl:16' => undef,
                'gettext_loc.pl:16' => undef,
                'maketext.pl:16' => undef,
                'maketext_loc.pl:16' => undef,
                'maketext_localise.pl:16' => undef,
                'maketext_localize.pl:16' => undef,
            },
        },
        '[*,_1,date,dates,no date]' => {
            automatic => '0,',
            reference => {
                'maketext.pl:46' => undef,
                'maketext.pl:50' => undef,
                'maketext.pl:54' => undef,
                'maketext_loc.pl:46' => undef,
                'maketext_loc.pl:50' => undef,
                'maketext_loc.pl:54' => undef,
                'maketext_localise.pl:46' => undef,
                'maketext_localise.pl:50' => undef,
                'maketext_localise.pl:54' => undef,
                'maketext_localize.pl:46' => undef,
                'maketext_localize.pl:50' => undef,
                'maketext_localize.pl:54' => undef,
            },
        },
        "[*,_1,date,dates]\x04appointment" => {
            automatic => '1,',
            reference => {
                'maketext.pl:36' => undef,
                'maketext.pl:41' => undef,
                'maketext_loc.pl:36' => undef,
                'maketext_loc.pl:41' => undef,
                'maketext_localise.pl:36' => undef,
                'maketext_localise.pl:41' => undef,
                'maketext_localize.pl:36' => undef,
                'maketext_localize.pl:41' => undef,
            },
        },
        '[_1] is programming [_2].' => {
            automatic => q{'Steffen', 'Perl',},
            reference => {
                'maketext.pl:19' => undef,
                'maketext_loc.pl:19' => undef,
                'maketext_localise.pl:19' => undef,
                'maketext_localize.pl:19' => undef,
            },
        },
        '[quant,_1,date,dates]' => {
            automatic => '1,',
            reference => {
                'maketext.pl:24' => undef,
                'maketext.pl:28' => undef,
                'maketext_loc.pl:24' => undef,
                'maketext_loc.pl:28' => undef,
                'maketext_localise.pl:24' => undef,
                'maketext_localise.pl:28' => undef,
                'maketext_localize.pl:24' => undef,
                'maketext_localize.pl:28' => undef,
            },
        },
        'date' => {
            automatic => q{foo => 'bar',},
            reference => {
                'gettext_loc.pl:81' => undef,
            },
        },
        "date\x00dates\x04appointment" => {
            automatic => '1',
            reference => {
                'gettext.pl:55' => undef,
                'gettext.pl:61' => undef,
                'gettext_loc.pl:55' => undef,
                'gettext_loc.pl:61' => undef,
            },
        },
        "date\x04appointment" => {
            reference => {
                'gettext.pl:46' => undef,
                'gettext_loc.pl:46' => undef,
                'gettext_loc.pl:85' => undef,
                'maketext.pl:32' => undef,
                'maketext_loc.pl:32' => undef,
                'maketext_localise.pl:32' => undef,
                'maketext_localize.pl:32' => undef,
            },
        },
        'q{ quoted text with {placeholders}}.' => {
            reference => {
                'gettext.pl:86' => undef,
                'gettext_loc.pl:96' => undef,
            },
        },
        'quoted text.' => {
            reference => {
                'gettext.pl:89' => undef,
                'gettext_loc.pl:99' => undef,
            },
        },
        'text of no domain and no category' => {
            reference => {
                'gettext.pl:108' => undef,
                'gettext.pl:116' => undef,
                'gettext.pl:120' => undef,
                'gettext_loc.pl:118' => undef,
                'gettext_loc.pl:126' => undef,
                'gettext_loc.pl:130' => undef,
            },
        },
        '{name} is programming {language}.' => {
            automatic => q{name => 'Steffen', language => 'Perl',},
            reference => {
                'gettext.pl:19' => undef,
                'gettext_loc.pl:19' => undef,
            },
        },
        "{num} date\x00{num} dates" => {
            automatic => '1, num => 1,',
            reference => {
                'gettext.pl:34' => undef,
                'gettext.pl:40' => undef,
                'gettext_loc.pl:34' => undef,
                'gettext_loc.pl:40' => undef,
            },
        },
        "{num} date\x00{num} dates\x04appointment" => {
            automatic => '1, num => 1,',
            reference => {
                'gettext.pl:67' => undef,
                'gettext.pl:74' => undef,
                'gettext_loc.pl:67' => undef,
                'gettext_loc.pl:74' => undef,
            },
        },
        "{num} date\x04appointment" => {
            automatic => 'num => 1,',
            reference => {
                'gettext.pl:50' => undef,
                'gettext_loc.pl:50' => undef,
            },
        },
    },
    'i-default::domain d' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        "singular dn\x00plural dn" => {
            automatic => '0',
            reference => {
                'gettext.pl:96' => undef,
                'gettext_loc.pl:106' => undef,
            },
        },
        "singular dnp\x00plural dnp\x04context dnp" => {
            automatic => '0',
            reference => {
                'gettext.pl:97' => undef,
                'gettext_loc.pl:107' => undef,
            },
        },
        'text d' => {
            reference => {
                'gettext.pl:94' => undef,
                'gettext_loc.pl:104' => undef,
            },
        },
        "text dp\x04context dp" => {
            reference => {
                'gettext.pl:95' => undef,
                'gettext_loc.pl:105' => undef,
            },
        },
        'text of domain d and no category' => {
            reference => {
                'gettext.pl:110' => undef,
                'gettext_loc.pl:120' => undef,
            },
        },
    },
    'i-default:category c:' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        "singular cn\x00plural cn" => {
            automatic => '0',
            reference => {
                'gettext.pl:99' => undef,
                'gettext_loc.pl:109' => undef,
            },
        },
        "singular cnp\x00plural cnp\x04context cnp" => {
            automatic => '0',
            reference => {
                'gettext.pl:101' => undef,
                'gettext_loc.pl:111' => undef,
            },
        },
        'text c' => {
            reference => {
                'gettext.pl:98' => undef,
                'gettext_loc.pl:108' => undef,
            },
        },
        "text cp\x04context cp" => {
            reference => {
                'gettext.pl:100' => undef,
                'gettext_loc.pl:110' => undef,
            },
        },
        'text of no domain and category c' => {
            reference => {
                'gettext.pl:114' => undef,
                'gettext_loc.pl:124' => undef,
            },
        },
    },
    'i-default:category c:domain d' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        "singular dcn\x00plural dcn" => {
            automatic => '0',
            reference => {
                'gettext.pl:103' => undef,
                'gettext_loc.pl:113' => undef,
            },
        },
        "singular dcnp\x00plural dcnp\x04context dcnp" => {
            automatic => '0',
            reference => {
                'gettext.pl:105' => undef,
                'gettext_loc.pl:115' => undef,
            },
        },
        'text dc' => {
            reference => {
                'gettext.pl:102' => undef,
                'gettext_loc.pl:112' => undef,
            },
        },
        "text dcp\x04context dcp" => {
            reference => {
                'gettext.pl:104' => undef,
                'gettext_loc.pl:114' => undef,
            },
        },
        'text of domain d and category c' => {
            reference => {
                'gettext.pl:112' => undef,
                'gettext.pl:118' => undef,
                'gettext_loc.pl:122' => undef,
                'gettext_loc.pl:128' => undef,
            },
        },
    },
};
eq_or_diff
    $extractor->lexicon_ref,
    $expected_lexicon_ref,
    'data of both files';

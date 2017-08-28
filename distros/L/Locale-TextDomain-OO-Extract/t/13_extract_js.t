#!perl -T

use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;
use Path::Tiny qw(path);

BEGIN {
    use_ok('Locale::TextDomain::OO::Extract::JavaScript');
}

my $extractor;
lives_ok
    sub {
        $extractor = Locale::TextDomain::OO::Extract::JavaScript->new;
    },
    'create extractor object';

{
    my $content = "1\n//2\n3\n4/*\n5\n*/6\n";
    # remove comments
    $extractor->content_ref(\$content);
    $extractor->preprocess;
    eq_or_diff
        $content,
        "1\n\n3\n4\n\n6\n",
        'check default preprocess';
}

# http://www.c-point.com/javascript_tutorial/special_characters.htm
{
    eq_or_diff
        $extractor->interpolate_escape_sequence(<<"EOT"),
\\' \\\\'
\\" \\\\"
\\b \\\\b
\\f \\\\f
\\n \\\\n
\\r \\\\r
\\t \\\\t
\\001 \\\\002
\\x03 \\\\x04
\\uD0D0 \\\\uD0D0
\\ \\\\
EOT
        <<"EOT",
' \\'
" \\"
\b \\b
\f \\f
\n \\n
\r \\r
\t \\t
\001 \\002
\x03 \\x04
\x{D0D0} \\uD0D0
 \\
EOT
        'check interpolate escape sequence';
}

for ( qw( gettext gettext_loc jsgettext ) ) {
    lives_ok
        sub {
            $extractor->filename("$_.js");
            $extractor->content_ref(
                \( path("./t/files_to_extract/$_.js")->slurp_utf8 ),
            );
            $extractor->extract;
        },
        "extract $_.js";
}

my $expected_lexicon_ref = {
    'i-default::' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        'Hello %1' => {
            reference => {
                'jsgettext.js:9' => undef,
            },
        },
        "Hello World!\n" => {
            reference => {
                'jsgettext.js:8' => undef,
            },
        },
        'MSGID %0 %1' => {
            automatic => '\'placeholder 0\', \'placeholder 1\'',
            reference => {
                'jsgettext.js:71' => undef,
            },
        },
        "MSGID n\x00PLURAL n" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:72' => undef,
            },
        },
        "MSGID np\x00PLURAL np\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:74' => undef,
            },
        },
        "MSGID p\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:73' => undef,
            },
        },
        MSGID_ => {
            reference => {
                'jsgettext.js:35' => undef,
                'gettext.js:2' => undef,
                'gettext.js:38' => undef,
                'gettext_loc.js:2' => undef,
                'gettext_loc.js:38' => undef,
            },
        },
        "MSGID_n\x00PLURAL_n" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:37' => undef,
                'gettext.js:4' => undef,
                'gettext.js:40' => undef,
                'gettext_loc.js:4' => undef,
                'gettext_loc.js:40' => undef,
            },
        },
        "MSGID_np\x00PLURAL_np\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:41' => undef,
                'gettext.js:44' => undef,
                'gettext.js:8' => undef,
                'gettext_loc.js:44' => undef,
                'gettext_loc.js:8' => undef,
            },
        },
        "MSGID_npx\x00PLURAL_npx\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:42' => undef,
                'gettext.js:45' => undef,
                'gettext.js:9' => undef,
                'gettext_loc.js:45' => undef,
                'gettext_loc.js:9' => undef,
            },
        },
        "MSGID_nx\x00PLURAL_nx" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:38' => undef,
                'gettext.js:41' => undef,
                'gettext.js:5' => undef,
                'gettext_loc.js:41' => undef,
                'gettext_loc.js:5' => undef,
            },
        },
        "MSGID_p\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:39' => undef,
                'gettext.js:42' => undef,
                'gettext.js:6' => undef,
                'gettext_loc.js:42' => undef,
                'gettext_loc.js:6' => undef,
            },
        },
        "MSGID_px\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:40' => undef,
                'gettext.js:43' => undef,
                'gettext.js:7' => undef,
                'gettext_loc.js:43' => undef,
                'gettext_loc.js:7' => undef,
            },
        },
        "MSGID_x {key1} {key2}" => {
            automatic => q{{ 'key1' : 'value1', 'key2' : 'value2' }},
            reference => {
                'jsgettext.js:36' => undef,'gettext.js:3' => undef,
                'gettext.js:39' => undef,
                'gettext_loc.js:3' => undef,
                'gettext_loc.js:39' => undef,
            },
        },
        "One file deleted.\n\x00%d files deleted.\n" => {
            automatic => 'count',
            reference => {
                'jsgettext.js:11' => undef,
                'jsgettext.js:15' => undef,
            },
        },
        'This is the %1 %2' => {
            reference => {
                'jsgettext.js:10' => undef,
            },
        },
        "View\x04Noun: A View" => {
            reference => {
                'jsgettext.js:20' => undef,
            },
        },
        "View\x04Verb: To View" => {
            reference => {
                'jsgettext.js:19' => undef,
            },
        },
        "one banana\x00%1 bananas" => {
            automatic => 'count',
            reference => {
                'jsgettext.js:22' => undef,
            },
        },
        'some string' => {
            reference => {
                'jsgettext.js:3' => undef,
                'jsgettext.js:4' => undef,
                'jsgettext.js:5' => undef,
            },
        },
        text => {
            reference => {
                'jsgettext.js:7' => undef,
            },
        },
        'this will get translated' => {
            reference => {
                'jsgettext.js:6' => undef,
            },
        },
    },
    'i-default::TEXTDOMAIN' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        'MSGID d' => {
            reference => {
                'jsgettext.js:76' => undef,
            },
        },
        "MSGID dn\x00PLURAL dn" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:77' => undef,
            },
        },
        "MSGID dp\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:78' => undef,
            },
        },
        "MSGID dpn\x00PLURAL dpn\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:79' => undef,
            },
        },
        MSGID_d => {
            reference => {
                'jsgettext.js:44' => undef,
                'gettext.js:11' => undef,
                'gettext.js:47' => undef,
                'gettext_loc.js:11' => undef,
                'gettext_loc.js:47' => undef,
            },
        },
        "MSGID_dn\x00PLURAL_dn" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:46' => undef,
                'gettext.js:13' => undef,
                'gettext.js:49' => undef,
                'gettext_loc.js:13' => undef,
                'gettext_loc.js:49' => undef,
            },
        },
        "MSGID_dnp\x00PLURAL_dnp\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:50' => undef,
                'gettext.js:17' => undef,
                'gettext.js:53' => undef,
                'gettext_loc.js:17' => undef,
                'gettext_loc.js:53' => undef,
            },
        },
        "MSGID_dnpx\x00PLURAL_dnpx\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:51' => undef,
                'gettext.js:18' => undef,
                'gettext.js:54' => undef,
                'gettext_loc.js:18' => undef,
                'gettext_loc.js:54' => undef,
            },
        },
        "MSGID_dnx\x00PLURAL_dnx" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:47' => undef,
                'gettext.js:14' => undef,
                'gettext.js:50' => undef,
                'gettext_loc.js:14' => undef,
                'gettext_loc.js:50' => undef,
            },
        },
        "MSGID_dp\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:48' => undef,
                'gettext.js:15' => undef,
                'gettext.js:51' => undef,
                'gettext_loc.js:15' => undef,
                'gettext_loc.js:51' => undef,
            },
        },
        "MSGID_dpx\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:49' => undef,
                'gettext.js:16' => undef,
                'gettext.js:52' => undef,
                'gettext_loc.js:16' => undef,
                'gettext_loc.js:52' => undef,
            },
        },
        MSGID_dx => {
            reference => {
                'jsgettext.js:45' => undef,
                'gettext.js:12' => undef,
                'gettext.js:48' => undef,
                'gettext_loc.js:12' => undef,
                'gettext_loc.js:48' => undef,
            },
        },
    },
    'i-default:CATEGORY:' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        'MSGID c' => {
            reference => {
                'jsgettext.js:81' => undef,
            },
        },
        "MSGID cn\x00PLURAL cn" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:82' => undef,
            },
        },
        "MSGID cnp\x00PLURAL cnp\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:84' => undef,
            },
        },
        "MSGID cp\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:83' => undef,
            },
        },
        MSGID_c => {
            reference => {
                'jsgettext.js:53' => undef,
                'gettext.js:20' => undef,
                'gettext.js:56' => undef,
                'gettext_loc.js:20' => undef,
                'gettext_loc.js:56' => undef,
            },
        },
        "MSGID_cn\x00PLURAL_cn" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:55' => undef,
                'gettext.js:22' => undef,
                'gettext.js:58' => undef,
                'gettext_loc.js:22' => undef,
                'gettext_loc.js:58' => undef,
            },
        },
        "MSGID_cnp\x00PLURAL_cnp\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:59' => undef,
                'gettext.js:26' => undef,
                'gettext.js:62' => undef,
                'gettext_loc.js:26' => undef,
                'gettext_loc.js:62' => undef,
            },
        },
        "MSGID_cnpx\x00PLURAL_cnpx\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:60' => undef,
                'gettext.js:27' => undef,
                'gettext.js:63' => undef,
                'gettext_loc.js:27' => undef,
                'gettext_loc.js:63' => undef,
            },
        },
        "MSGID_cnx\x00PLURAL_cnx" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:56' => undef,
                'gettext.js:23' => undef,
                'gettext.js:59' => undef,
                'gettext_loc.js:23' => undef,
                'gettext_loc.js:59' => undef,
            },
        },
        "MSGID_cp\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:57' => undef,
                'gettext.js:24' => undef,
                'gettext.js:60' => undef,
                'gettext_loc.js:24' => undef,
                'gettext_loc.js:60' => undef,
            },
        },
        "MSGID_cpx\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:58' => undef,
                'gettext.js:25' => undef,
                'gettext.js:61' => undef,
                'gettext_loc.js:25' => undef,
                'gettext_loc.js:61' => undef,
            },
        },
        MSGID_cx => {
            reference => {
                'jsgettext.js:54' => undef,
                'gettext.js:21' => undef,
                'gettext.js:57' => undef,
                'gettext_loc.js:21' => undef,
                'gettext_loc.js:57' => undef,
            },
        },
    },
    'i-default:CATEGORY:TEXTDOMAIN' => {
        q{} => {
            msgstr => {
                nplurals => 2,
                plural => 'n != 1',
            },
        },
        'MSGID dc' => {
            reference => {
                'jsgettext.js:86' => undef,
            },
        },
        "MSGID dcn\x00PLURAL dcn" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:87' => undef,
            },
        },
        "MSGID dcnp\x00PLURAL dcnp\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:89' => undef,
            },
        },
        "MSGID dcp\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:88' => undef,
            },
        },
        MSGID_dc => {
            reference => {
                'jsgettext.js:62' => undef,
                'gettext.js:29' => undef,
                'gettext.js:65' => undef,
                'gettext_loc.js:29' => undef,
                'gettext_loc.js:65' => undef,
            },
        },
        "MSGID_dcn\x00PLURAL_dcn" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:64' => undef,
                'gettext.js:31' => undef,
                'gettext.js:67' => undef,
                'gettext_loc.js:31' => undef,
                'gettext_loc.js:67' => undef
            },
        },
        "MSGID_dcnp\x00PLURAL_dcnp\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:68' => undef,
                'gettext.js:35' => undef,
                'gettext.js:71' => undef,
                'gettext_loc.js:35' => undef,
                'gettext_loc.js:71' => undef,
            },
        },
        "MSGID_dcnpx\x00PLURAL_dcnpx\x04MSGCTXT" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:69' => undef,
                'gettext.js:36' => undef,
                'gettext.js:72' => undef,
                'gettext_loc.js:36' => undef,
                'gettext_loc.js:72' => undef,
            },
        },
        "MSGID_dcnx\x00PLURAL_dcnx" => {
            automatic => 'COUNT',
            reference => {
                'jsgettext.js:65' => undef,
                'gettext.js:32' => undef,
                'gettext.js:68' => undef,
                'gettext_loc.js:32' => undef,
                'gettext_loc.js:68' => undef,
            },
        },
        "MSGID_dcp\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:66' => undef,
                'gettext.js:33' => undef,
                'gettext.js:69' => undef,
                'gettext_loc.js:33' => undef,
                'gettext_loc.js:69' => undef,
            },
        },
        "MSGID_dcpx\x04MSGCTXT" => {
            reference => {
                'jsgettext.js:67' => undef,
                'gettext.js:34' => undef,
                'gettext.js:70' => undef,
                'gettext_loc.js:34' => undef,
                'gettext_loc.js:70' => undef,
            },
        },
        MSGID_dcx => {
            reference => {
                'jsgettext.js:63' => undef,
                'gettext.js:30' => undef,
                'gettext.js:66' => undef,
                'gettext_loc.js:30' => undef,
                'gettext_loc.js:66' => undef,
            },
        },
    },
};
eq_or_diff
    $extractor->lexicon_ref,
    $expected_lexicon_ref,
    'data of both files';

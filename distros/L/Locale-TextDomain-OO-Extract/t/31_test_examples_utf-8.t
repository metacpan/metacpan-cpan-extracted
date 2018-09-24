#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use Encode qw(decode_utf8);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING}
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';
require Test::NoWarnings;
Test::NoWarnings->import;

my @data = (
    {
        test   => '11_extract_perl_filter_ignore',
        path   => 'example',
        script => '-I../lib 11_extract_perl_filter_ignore.pl',
        result => <<'EOT',
$lexicon_ref = {
  "i-default::" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "' quoted text with \\\\." => {
      reference => {
        "files_to_extract/gettext.pl:83" => undef,
        "files_to_extract/gettext_loc.pl:84" => undef
      }
    },
    January => {
      reference => {
        "files_to_extract/test_process.pl:16" => undef
      }
    },
    "Singular\0Plural" => {
      automatic => 1,
      reference => {
        "files_to_extract/gettext.pl:24" => undef,
        "files_to_extract/gettext.pl:29" => undef,
        "files_to_extract/gettext_loc.pl:24" => undef,
        "files_to_extract/gettext_loc.pl:29" => undef
      }
    },
    "This is a new text." => {
      reference => {
        "files_to_extract/test_process.pl:15" => undef
      }
    },
    "This is a text." => {
      reference => {
        "files_to_extract/gettext.pl:16" => undef,
        "files_to_extract/gettext_loc.pl:16" => undef,
        "files_to_extract/maketext.pl:16" => undef,
        "files_to_extract/maketext_loc.pl:16" => undef,
        "files_to_extract/maketext_localise.pl:16" => undef,
        "files_to_extract/maketext_localize.pl:16" => undef
      }
    },
    "This is an old text." => {
      reference => {
        "files_to_extract/test_process.pl:14" => undef
      }
    },
    "[*,_1,date,dates,no date]" => {
      automatic => "0,",
      reference => {
        "files_to_extract/maketext.pl:46" => undef,
        "files_to_extract/maketext.pl:50" => undef,
        "files_to_extract/maketext.pl:54" => undef,
        "files_to_extract/maketext_loc.pl:46" => undef,
        "files_to_extract/maketext_loc.pl:50" => undef,
        "files_to_extract/maketext_loc.pl:54" => undef,
        "files_to_extract/maketext_localise.pl:46" => undef,
        "files_to_extract/maketext_localise.pl:50" => undef,
        "files_to_extract/maketext_localise.pl:54" => undef,
        "files_to_extract/maketext_localize.pl:46" => undef,
        "files_to_extract/maketext_localize.pl:50" => undef,
        "files_to_extract/maketext_localize.pl:54" => undef
      }
    },
    "[*,_1,date,dates]\4appointment" => {
      automatic => "1,",
      reference => {
        "files_to_extract/maketext.pl:36" => undef,
        "files_to_extract/maketext.pl:41" => undef,
        "files_to_extract/maketext_loc.pl:36" => undef,
        "files_to_extract/maketext_loc.pl:41" => undef,
        "files_to_extract/maketext_localise.pl:36" => undef,
        "files_to_extract/maketext_localise.pl:41" => undef,
        "files_to_extract/maketext_localize.pl:36" => undef,
        "files_to_extract/maketext_localize.pl:41" => undef
      }
    },
    "[_1] is programming [_2]." => {
      automatic => "'Steffen', 'Perl',",
      reference => {
        "files_to_extract/maketext.pl:19" => undef,
        "files_to_extract/maketext_loc.pl:19" => undef,
        "files_to_extract/maketext_localise.pl:19" => undef,
        "files_to_extract/maketext_localize.pl:19" => undef
      }
    },
    "[quant,_1,date,dates]" => {
      automatic => "1,",
      reference => {
        "files_to_extract/maketext.pl:24" => undef,
        "files_to_extract/maketext.pl:28" => undef,
        "files_to_extract/maketext_loc.pl:24" => undef,
        "files_to_extract/maketext_loc.pl:28" => undef,
        "files_to_extract/maketext_localise.pl:24" => undef,
        "files_to_extract/maketext_localise.pl:28" => undef,
        "files_to_extract/maketext_localize.pl:24" => undef,
        "files_to_extract/maketext_localize.pl:28" => undef
      }
    },
    "date\0dates\4appointment" => {
      automatic => 1,
      reference => {
        "files_to_extract/gettext.pl:55" => undef,
        "files_to_extract/gettext.pl:61" => undef,
        "files_to_extract/gettext_loc.pl:55" => undef,
        "files_to_extract/gettext_loc.pl:61" => undef
      }
    },
    "date\4appointment" => {
      reference => {
        "files_to_extract/gettext.pl:46" => undef,
        "files_to_extract/gettext_loc.pl:46" => undef,
        "files_to_extract/maketext.pl:32" => undef,
        "files_to_extract/maketext_loc.pl:32" => undef,
        "files_to_extract/maketext_localise.pl:32" => undef,
        "files_to_extract/maketext_localize.pl:32" => undef
      }
    },
    "quoted text." => {
      reference => {
        "files_to_extract/gettext.pl:89" => undef,
        "files_to_extract/gettext_loc.pl:90" => undef
      }
    },
    "q{ quoted text with {placeholders}}." => {
      reference => {
        "files_to_extract/gettext.pl:86" => undef,
        "files_to_extract/gettext_loc.pl:87" => undef
      }
    },
    "text of no domain and no category" => {
      reference => {
        "files_to_extract/gettext.pl:108" => undef,
        "files_to_extract/gettext.pl:116" => undef,
        "files_to_extract/gettext.pl:120" => undef,
        "files_to_extract/gettext_loc.pl:109" => undef,
        "files_to_extract/gettext_loc.pl:117" => undef,
        "files_to_extract/gettext_loc.pl:121" => undef
      }
    },
    "{name} is programming {language}." => {
      automatic => "name => 'Steffen', language => 'Perl',",
      reference => {
        "files_to_extract/gettext.pl:19" => undef,
        "files_to_extract/gettext_loc.pl:19" => undef
      }
    },
    "{num} date\0{num} dates" => {
      automatic => "1, num => 1,",
      reference => {
        "files_to_extract/gettext.pl:34" => undef,
        "files_to_extract/gettext.pl:40" => undef,
        "files_to_extract/gettext_loc.pl:34" => undef,
        "files_to_extract/gettext_loc.pl:40" => undef
      }
    },
    "{num} date\0{num} dates\4appointment" => {
      automatic => "1, num => 1,",
      reference => {
        "files_to_extract/gettext.pl:67" => undef,
        "files_to_extract/gettext.pl:74" => undef,
        "files_to_extract/gettext_loc.pl:67" => undef,
        "files_to_extract/gettext_loc.pl:74" => undef
      }
    },
    "{num} date\4appointment" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/gettext.pl:50" => undef,
        "files_to_extract/gettext_loc.pl:50" => undef
      }
    }
  },
  "i-default::domain d" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "singular dn\0plural dn" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:96" => undef,
        "files_to_extract/gettext_loc.pl:97" => undef
      }
    },
    "singular dnp\0plural dnp\4context dnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:97" => undef,
        "files_to_extract/gettext_loc.pl:98" => undef
      }
    },
    "text d" => {
      reference => {
        "files_to_extract/gettext.pl:94" => undef,
        "files_to_extract/gettext_loc.pl:95" => undef
      }
    },
    "text dp\4context dp" => {
      reference => {
        "files_to_extract/gettext.pl:95" => undef,
        "files_to_extract/gettext_loc.pl:96" => undef
      }
    },
    "text of domain d and no category" => {
      reference => {
        "files_to_extract/gettext.pl:110" => undef,
        "files_to_extract/gettext_loc.pl:111" => undef
      }
    }
  },
  "i-default:category c:" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "singular cn\0plural cn" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:99" => undef,
        "files_to_extract/gettext_loc.pl:100" => undef
      }
    },
    "singular cnp\0plural cnp\4context cnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:101" => undef,
        "files_to_extract/gettext_loc.pl:102" => undef
      }
    },
    "text c" => {
      reference => {
        "files_to_extract/gettext.pl:98" => undef,
        "files_to_extract/gettext_loc.pl:99" => undef
      }
    },
    "text cp\4context cp" => {
      reference => {
        "files_to_extract/gettext.pl:100" => undef,
        "files_to_extract/gettext_loc.pl:101" => undef
      }
    },
    "text of no domain and category c" => {
      reference => {
        "files_to_extract/gettext.pl:114" => undef,
        "files_to_extract/gettext_loc.pl:115" => undef
      }
    }
  },
  "i-default:category c:domain d" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "singular dcn\0plural dcn" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:103" => undef,
        "files_to_extract/gettext_loc.pl:104" => undef
      }
    },
    "singular dcnp\0plural dcnp\4context dcnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:105" => undef,
        "files_to_extract/gettext_loc.pl:106" => undef
      }
    },
    "text dc" => {
      reference => {
        "files_to_extract/gettext.pl:102" => undef,
        "files_to_extract/gettext_loc.pl:103" => undef
      }
    },
    "text dcp\4context dcp" => {
      reference => {
        "files_to_extract/gettext.pl:104" => undef,
        "files_to_extract/gettext_loc.pl:105" => undef
      }
    },
    "text of domain d and category c" => {
      reference => {
        "files_to_extract/gettext.pl:112" => undef,
        "files_to_extract/gettext.pl:118" => undef,
        "files_to_extract/gettext_loc.pl:113" => undef,
        "files_to_extract/gettext_loc.pl:119" => undef
      }
    }
  }
};
EOT
    },
    {
        test   => '11_extract_perl_filter_only_babelfish',
        path   => 'example',
        script => '-I../lib 11_extract_perl_filter_only_babelfish.pl',
        result => <<'EOT',
$lexicon_ref = {
  "i-default::" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "#{count :num} ((date|dates))" => {
      automatic => "1,",
      reference => {
        "files_to_extract/babelfish_loc.pl:32" => undef,
        "files_to_extract/babelfish_loc.pl:36" => undef
      }
    },
    "#{name} is programming #{language}." => {
      automatic => "name => 'Steffen', language => 'Perl',",
      reference => {
        "files_to_extract/babelfish_loc.pl:19" => undef
      }
    },
    "#{num} ((date|dates)):num\4appointment" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/babelfish_loc.pl:59" => undef,
        "files_to_extract/babelfish_loc.pl:64" => undef
      }
    },
    "#{num} date\4appointment" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/babelfish_loc.pl:44" => undef
      }
    },
    "' quoted text with \\\\." => {
      reference => {
        "files_to_extract/babelfish_loc.pl:72" => undef
      }
    },
    "((Singular|Plural))" => {
      automatic => "1,",
      reference => {
        "files_to_extract/babelfish_loc.pl:24" => undef,
        "files_to_extract/babelfish_loc.pl:28" => undef
      }
    },
    "((date|dates)):num\4appointment" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/babelfish_loc.pl:49" => undef,
        "files_to_extract/babelfish_loc.pl:54" => undef
      }
    },
    "This is a text." => {
      reference => {
        "files_to_extract/babelfish_loc.pl:16" => undef
      }
    },
    "category c" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:100" => undef
      }
    },
    "date\4appointment" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:40" => undef
      }
    },
    "quoted text." => {
      reference => {
        "files_to_extract/babelfish_loc.pl:78" => undef
      }
    },
    "q{ quoted text with #{placeholders}}." => {
      reference => {
        "files_to_extract/babelfish_loc.pl:75" => undef
      }
    },
    "text of domain d and category c" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:101" => undef,
        "files_to_extract/babelfish_loc.pl:107" => undef
      }
    },
    "text of domain d and no category" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:99" => undef
      }
    },
    "text of no domain and category c" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:103" => undef
      }
    },
    "text of no domain and no category" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:105" => undef,
        "files_to_extract/babelfish_loc.pl:109" => undef,
        "files_to_extract/babelfish_loc.pl:97" => undef
      }
    }
  },
  "i-default::domain d" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      },
      reference => {
        "files_to_extract/babelfish_loc.pl:98" => undef
      }
    },
    "((singular dp|plural dp))\4context dp" => {
      automatic => 0,
      reference => {
        "files_to_extract/babelfish_loc.pl:86" => undef
      }
    },
    "((singular d|plural d))" => {
      automatic => 0,
      reference => {
        "files_to_extract/babelfish_loc.pl:85" => undef
      }
    },
    "category c" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:106" => undef
      }
    },
    "text d" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:83" => undef
      }
    },
    "text dp\4context dp" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:84" => undef
      }
    }
  },
  "i-default:category c:" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "((singular cp|plural cp))\4context cp" => {
      automatic => 0,
      reference => {
        "files_to_extract/babelfish_loc.pl:90" => undef
      }
    },
    "((singular c|plural c))" => {
      automatic => 0,
      reference => {
        "files_to_extract/babelfish_loc.pl:88" => undef
      }
    },
    "text c" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:87" => undef
      }
    },
    "text cp\4context cp" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:89" => undef
      }
    }
  },
  "i-default:category c:domain d" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "((singular dcp|plural dcp))\4context dcp" => {
      automatic => 0,
      reference => {
        "files_to_extract/babelfish_loc.pl:94" => undef
      }
    },
    "((singular dc|plural dc))" => {
      automatic => 0,
      reference => {
        "files_to_extract/babelfish_loc.pl:92" => undef
      }
    },
    "text dc" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:91" => undef
      }
    },
    "text dcp\4context dcp" => {
      reference => {
        "files_to_extract/babelfish_loc.pl:93" => undef
      }
    }
  }
};
EOT
    },
    {
        test   => '12_extract_tt',
        path   => 'example',
        script => '-I../lib 12_extract_tt.pl',
        result => <<'EOT',
$lexicon_ref = {
  "i-default::" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "#{name} is programming #{language}." => {
      automatic => "name => 'Steffen', language => 'Perl',",
      reference => {
        "files_to_extract/babelfish_loc.tt:22" => undef
      }
    },
    "#{num :num} ((date|dates))" => {
      automatic => "num => 2,",
      reference => {
        "files_to_extract/babelfish_loc.tt:39" => undef
      }
    },
    "#{num} ((date|dates)):num" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/babelfish_loc.tt:35" => undef
      }
    },
    "#{num} date\4appointment" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/babelfish_loc.tt:47" => undef
      }
    },
    "((Singular|Plural))" => {
      automatic => "1,",
      reference => {
        "files_to_extract/babelfish_loc.tt:27" => undef,
        "files_to_extract/babelfish_loc.tt:31" => undef
      }
    },
    "((date|dates))\4appointment" => {
      automatic => "1,",
      reference => {
        "files_to_extract/babelfish_loc.tt:52" => undef,
        "files_to_extract/babelfish_loc.tt:57" => undef
      }
    },
    "Singular\0Plural" => {
      automatic => 1,
      reference => {
        "files_to_extract/gettext.tt:27" => undef,
        "files_to_extract/gettext.tt:32" => undef,
        "files_to_extract/gettext_loc.tt:27" => undef,
        "files_to_extract/gettext_loc.tt:32" => undef
      }
    },
    "Text \x{c4}" => {
      reference => {
        "files_to_extract/babelfish_loc.tt:9" => undef,
        "files_to_extract/gettext.tt:9" => undef,
        "files_to_extract/gettext_loc.tt:9" => undef,
        "files_to_extract/maketext_l.tt:9" => undef
      }
    },
    "Text \x{d6}" => {
      reference => {
        "files_to_extract/babelfish_loc.tt:13" => undef,
        "files_to_extract/gettext.tt:13" => undef,
        "files_to_extract/gettext_loc.tt:13" => undef,
        "files_to_extract/maketext_l.tt:13" => undef
      }
    },
    "Text \x{dc}" => {
      reference => {
        "files_to_extract/babelfish_loc.tt:16" => undef,
        "files_to_extract/gettext.tt:16" => undef,
        "files_to_extract/gettext_loc.tt:16" => undef,
        "files_to_extract/maketext_l.tt:16" => undef
      }
    },
    "This is a text." => {
      reference => {
        "files_to_extract/babelfish_loc.tt:21" => undef,
        "files_to_extract/gettext.tt:21" => undef,
        "files_to_extract/gettext_loc.tt:21" => undef
      }
    },
    "date\0dates\4appointment" => {
      automatic => 1,
      reference => {
        "files_to_extract/gettext.tt:58" => undef,
        "files_to_extract/gettext.tt:64" => undef,
        "files_to_extract/gettext_loc.tt:58" => undef,
        "files_to_extract/gettext_loc.tt:64" => undef
      }
    },
    "date\4appointment" => {
      reference => {
        "files_to_extract/babelfish_loc.tt:43" => undef,
        "files_to_extract/gettext.tt:49" => undef,
        "files_to_extract/gettext_loc.tt:49" => undef
      }
    },
    "{name} is programming {language}." => {
      automatic => "name => 'Steffen', language => 'Perl',",
      reference => {
        "files_to_extract/gettext.tt:22" => undef,
        "files_to_extract/gettext_loc.tt:22" => undef
      }
    },
    "{num} date\0{num} dates" => {
      automatic => "1, num => 1,",
      reference => {
        "files_to_extract/gettext.tt:37" => undef,
        "files_to_extract/gettext.tt:43" => undef,
        "files_to_extract/gettext_loc.tt:37" => undef,
        "files_to_extract/gettext_loc.tt:43" => undef
      }
    },
    "{num} date\0{num} dates\4appointment" => {
      automatic => "1, num => 1,",
      reference => {
        "files_to_extract/gettext.tt:70" => undef,
        "files_to_extract/gettext.tt:77" => undef,
        "files_to_extract/gettext_loc.tt:70" => undef,
        "files_to_extract/gettext_loc.tt:77" => undef
      }
    },
    "{num} date\4appointment" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/gettext.tt:53" => undef,
        "files_to_extract/gettext_loc.tt:53" => undef
      }
    }
  }
};
EOT
    },
    {
        test   => '13_extract_js',
        path   => 'example',
        script => '-I../lib 13_extract_js.pl',
        result => <<'EOT',
$lexicon_ref = {
  "i-default::" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "Hello %1" => {
      reference => {
        "files_to_extract/jsgettext.js:9" => undef
      }
    },
    "Hello World!\n" => {
      reference => {
        "files_to_extract/jsgettext.js:8" => undef
      }
    },
    "MSGID %0 %1" => {
      automatic => "'placeholder 0', 'placeholder 1'",
      reference => {
        "files_to_extract/jsgettext.js:71" => undef
      }
    },
    "MSGID n\0PLURAL n" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:72" => undef
      }
    },
    "MSGID np\0PLURAL np\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:74" => undef
      }
    },
    "MSGID p\4MSGCTXT" => {
      reference => {
        "files_to_extract/jsgettext.js:73" => undef
      }
    },
    MSGID_ => {
      reference => {
        "files_to_extract/gettext.js:2" => undef,
        "files_to_extract/gettext.js:38" => undef,
        "files_to_extract/gettext_loc.js:2" => undef,
        "files_to_extract/gettext_loc.js:38" => undef,
        "files_to_extract/jsgettext.js:35" => undef
      }
    },
    "MSGID_n\0PLURAL_n" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:4" => undef,
        "files_to_extract/gettext.js:40" => undef,
        "files_to_extract/gettext_loc.js:4" => undef,
        "files_to_extract/gettext_loc.js:40" => undef,
        "files_to_extract/jsgettext.js:37" => undef
      }
    },
    "MSGID_np\0PLURAL_np\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:44" => undef,
        "files_to_extract/gettext.js:8" => undef,
        "files_to_extract/gettext_loc.js:44" => undef,
        "files_to_extract/gettext_loc.js:8" => undef,
        "files_to_extract/jsgettext.js:41" => undef
      }
    },
    "MSGID_npx\0PLURAL_npx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:45" => undef,
        "files_to_extract/gettext.js:9" => undef,
        "files_to_extract/gettext_loc.js:45" => undef,
        "files_to_extract/gettext_loc.js:9" => undef,
        "files_to_extract/jsgettext.js:42" => undef
      }
    },
    "MSGID_nx\0PLURAL_nx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:41" => undef,
        "files_to_extract/gettext.js:5" => undef,
        "files_to_extract/gettext_loc.js:41" => undef,
        "files_to_extract/gettext_loc.js:5" => undef,
        "files_to_extract/jsgettext.js:38" => undef
      }
    },
    "MSGID_p\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:42" => undef,
        "files_to_extract/gettext.js:6" => undef,
        "files_to_extract/gettext_loc.js:42" => undef,
        "files_to_extract/gettext_loc.js:6" => undef,
        "files_to_extract/jsgettext.js:39" => undef
      }
    },
    "MSGID_px\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:43" => undef,
        "files_to_extract/gettext.js:7" => undef,
        "files_to_extract/gettext_loc.js:43" => undef,
        "files_to_extract/gettext_loc.js:7" => undef,
        "files_to_extract/jsgettext.js:40" => undef
      }
    },
    "MSGID_x {key1} {key2}" => {
      automatic => "{ 'key1' : 'value1', 'key2' : 'value2' }",
      reference => {
        "files_to_extract/gettext.js:3" => undef,
        "files_to_extract/gettext.js:39" => undef,
        "files_to_extract/gettext_loc.js:3" => undef,
        "files_to_extract/gettext_loc.js:39" => undef,
        "files_to_extract/jsgettext.js:36" => undef
      }
    },
    "One file deleted.\n\0%d files deleted.\n" => {
      automatic => "count",
      reference => {
        "files_to_extract/jsgettext.js:11" => undef,
        "files_to_extract/jsgettext.js:15" => undef
      }
    },
    "This is the %1 %2" => {
      reference => {
        "files_to_extract/jsgettext.js:10" => undef
      }
    },
    "View\4Noun: A View" => {
      reference => {
        "files_to_extract/jsgettext.js:20" => undef
      }
    },
    "View\4Verb: To View" => {
      reference => {
        "files_to_extract/jsgettext.js:19" => undef
      }
    },
    "one banana\0%1 bananas" => {
      automatic => "count",
      reference => {
        "files_to_extract/jsgettext.js:22" => undef
      }
    },
    "some string" => {
      reference => {
        "files_to_extract/jsgettext.js:3" => undef,
        "files_to_extract/jsgettext.js:4" => undef,
        "files_to_extract/jsgettext.js:5" => undef
      }
    },
    text => {
      reference => {
        "files_to_extract/jsgettext.js:7" => undef
      }
    },
    "this will get translated" => {
      reference => {
        "files_to_extract/jsgettext.js:6" => undef
      }
    }
  },
  "i-default::TEXTDOMAIN" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "MSGID d" => {
      reference => {
        "files_to_extract/jsgettext.js:76" => undef
      }
    },
    "MSGID dn\0PLURAL dn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:77" => undef
      }
    },
    "MSGID dp\4MSGCTXT" => {
      reference => {
        "files_to_extract/jsgettext.js:78" => undef
      }
    },
    "MSGID dpn\0PLURAL dpn\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:79" => undef
      }
    },
    MSGID_d => {
      reference => {
        "files_to_extract/gettext.js:11" => undef,
        "files_to_extract/gettext.js:47" => undef,
        "files_to_extract/gettext_loc.js:11" => undef,
        "files_to_extract/gettext_loc.js:47" => undef,
        "files_to_extract/jsgettext.js:44" => undef
      }
    },
    "MSGID_dn\0PLURAL_dn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:13" => undef,
        "files_to_extract/gettext.js:49" => undef,
        "files_to_extract/gettext_loc.js:13" => undef,
        "files_to_extract/gettext_loc.js:49" => undef,
        "files_to_extract/jsgettext.js:46" => undef
      }
    },
    "MSGID_dnp\0PLURAL_dnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:17" => undef,
        "files_to_extract/gettext.js:53" => undef,
        "files_to_extract/gettext_loc.js:17" => undef,
        "files_to_extract/gettext_loc.js:53" => undef,
        "files_to_extract/jsgettext.js:50" => undef
      }
    },
    "MSGID_dnpx\0PLURAL_dnpx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:18" => undef,
        "files_to_extract/gettext.js:54" => undef,
        "files_to_extract/gettext_loc.js:18" => undef,
        "files_to_extract/gettext_loc.js:54" => undef,
        "files_to_extract/jsgettext.js:51" => undef
      }
    },
    "MSGID_dnx\0PLURAL_dnx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:14" => undef,
        "files_to_extract/gettext.js:50" => undef,
        "files_to_extract/gettext_loc.js:14" => undef,
        "files_to_extract/gettext_loc.js:50" => undef,
        "files_to_extract/jsgettext.js:47" => undef
      }
    },
    "MSGID_dp\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:15" => undef,
        "files_to_extract/gettext.js:51" => undef,
        "files_to_extract/gettext_loc.js:15" => undef,
        "files_to_extract/gettext_loc.js:51" => undef,
        "files_to_extract/jsgettext.js:48" => undef
      }
    },
    "MSGID_dpx\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:16" => undef,
        "files_to_extract/gettext.js:52" => undef,
        "files_to_extract/gettext_loc.js:16" => undef,
        "files_to_extract/gettext_loc.js:52" => undef,
        "files_to_extract/jsgettext.js:49" => undef
      }
    },
    MSGID_dx => {
      reference => {
        "files_to_extract/gettext.js:12" => undef,
        "files_to_extract/gettext.js:48" => undef,
        "files_to_extract/gettext_loc.js:12" => undef,
        "files_to_extract/gettext_loc.js:48" => undef,
        "files_to_extract/jsgettext.js:45" => undef
      }
    }
  },
  "i-default:CATEGORY:" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "MSGID c" => {
      reference => {
        "files_to_extract/jsgettext.js:81" => undef
      }
    },
    "MSGID cn\0PLURAL cn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:82" => undef
      }
    },
    "MSGID cnp\0PLURAL cnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:84" => undef
      }
    },
    "MSGID cp\4MSGCTXT" => {
      reference => {
        "files_to_extract/jsgettext.js:83" => undef
      }
    },
    MSGID_c => {
      reference => {
        "files_to_extract/gettext.js:20" => undef,
        "files_to_extract/gettext.js:56" => undef,
        "files_to_extract/gettext_loc.js:20" => undef,
        "files_to_extract/gettext_loc.js:56" => undef,
        "files_to_extract/jsgettext.js:53" => undef
      }
    },
    "MSGID_cn\0PLURAL_cn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:22" => undef,
        "files_to_extract/gettext.js:58" => undef,
        "files_to_extract/gettext_loc.js:22" => undef,
        "files_to_extract/gettext_loc.js:58" => undef,
        "files_to_extract/jsgettext.js:55" => undef
      }
    },
    "MSGID_cnp\0PLURAL_cnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:26" => undef,
        "files_to_extract/gettext.js:62" => undef,
        "files_to_extract/gettext_loc.js:26" => undef,
        "files_to_extract/gettext_loc.js:62" => undef,
        "files_to_extract/jsgettext.js:59" => undef
      }
    },
    "MSGID_cnpx\0PLURAL_cnpx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:27" => undef,
        "files_to_extract/gettext.js:63" => undef,
        "files_to_extract/gettext_loc.js:27" => undef,
        "files_to_extract/gettext_loc.js:63" => undef,
        "files_to_extract/jsgettext.js:60" => undef
      }
    },
    "MSGID_cnx\0PLURAL_cnx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:23" => undef,
        "files_to_extract/gettext.js:59" => undef,
        "files_to_extract/gettext_loc.js:23" => undef,
        "files_to_extract/gettext_loc.js:59" => undef,
        "files_to_extract/jsgettext.js:56" => undef
      }
    },
    "MSGID_cp\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:24" => undef,
        "files_to_extract/gettext.js:60" => undef,
        "files_to_extract/gettext_loc.js:24" => undef,
        "files_to_extract/gettext_loc.js:60" => undef,
        "files_to_extract/jsgettext.js:57" => undef
      }
    },
    "MSGID_cpx\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:25" => undef,
        "files_to_extract/gettext.js:61" => undef,
        "files_to_extract/gettext_loc.js:25" => undef,
        "files_to_extract/gettext_loc.js:61" => undef,
        "files_to_extract/jsgettext.js:58" => undef
      }
    },
    MSGID_cx => {
      reference => {
        "files_to_extract/gettext.js:21" => undef,
        "files_to_extract/gettext.js:57" => undef,
        "files_to_extract/gettext_loc.js:21" => undef,
        "files_to_extract/gettext_loc.js:57" => undef,
        "files_to_extract/jsgettext.js:54" => undef
      }
    }
  },
  "i-default:CATEGORY:TEXTDOMAIN" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "MSGID dc" => {
      reference => {
        "files_to_extract/jsgettext.js:86" => undef
      }
    },
    "MSGID dcn\0PLURAL dcn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:87" => undef
      }
    },
    "MSGID dcnp\0PLURAL dcnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/jsgettext.js:89" => undef
      }
    },
    "MSGID dcp\4MSGCTXT" => {
      reference => {
        "files_to_extract/jsgettext.js:88" => undef
      }
    },
    MSGID_dc => {
      reference => {
        "files_to_extract/gettext.js:29" => undef,
        "files_to_extract/gettext.js:65" => undef,
        "files_to_extract/gettext_loc.js:29" => undef,
        "files_to_extract/gettext_loc.js:65" => undef,
        "files_to_extract/jsgettext.js:62" => undef
      }
    },
    "MSGID_dcn\0PLURAL_dcn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:31" => undef,
        "files_to_extract/gettext.js:67" => undef,
        "files_to_extract/gettext_loc.js:31" => undef,
        "files_to_extract/gettext_loc.js:67" => undef,
        "files_to_extract/jsgettext.js:64" => undef
      }
    },
    "MSGID_dcnp\0PLURAL_dcnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:35" => undef,
        "files_to_extract/gettext.js:71" => undef,
        "files_to_extract/gettext_loc.js:35" => undef,
        "files_to_extract/gettext_loc.js:71" => undef,
        "files_to_extract/jsgettext.js:68" => undef
      }
    },
    "MSGID_dcnpx\0PLURAL_dcnpx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:36" => undef,
        "files_to_extract/gettext.js:72" => undef,
        "files_to_extract/gettext_loc.js:36" => undef,
        "files_to_extract/gettext_loc.js:72" => undef,
        "files_to_extract/jsgettext.js:69" => undef
      }
    },
    "MSGID_dcnx\0PLURAL_dcnx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:32" => undef,
        "files_to_extract/gettext.js:68" => undef,
        "files_to_extract/gettext_loc.js:32" => undef,
        "files_to_extract/gettext_loc.js:68" => undef,
        "files_to_extract/jsgettext.js:65" => undef
      }
    },
    "MSGID_dcp\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:33" => undef,
        "files_to_extract/gettext.js:69" => undef,
        "files_to_extract/gettext_loc.js:33" => undef,
        "files_to_extract/gettext_loc.js:69" => undef,
        "files_to_extract/jsgettext.js:66" => undef
      }
    },
    "MSGID_dcpx\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:34" => undef,
        "files_to_extract/gettext.js:70" => undef,
        "files_to_extract/gettext_loc.js:34" => undef,
        "files_to_extract/gettext_loc.js:70" => undef,
        "files_to_extract/jsgettext.js:67" => undef
      }
    },
    MSGID_dcx => {
      reference => {
        "files_to_extract/gettext.js:30" => undef,
        "files_to_extract/gettext.js:66" => undef,
        "files_to_extract/gettext_loc.js:30" => undef,
        "files_to_extract/gettext_loc.js:66" => undef,
        "files_to_extract/jsgettext.js:63" => undef
      }
    }
  }
};
EOT
    },
    {
        test   => '14_extract_html',
        path   => 'example',
        script => '-I../lib 14_extract_html.pl',
        result => <<'EOT',
$lexicon_ref = {
  "i-default::" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    "This is a p text." => {
      reference => {
        "files_to_extract/gettext.html:8" => undef,
        "files_to_extract/gettext_loc.html:8" => undef,
        "files_to_extract/maketext_loc.html:8" => undef
      }
    },
    "This is an a text." => {
      reference => {
        "files_to_extract/gettext.html:10" => undef,
        "files_to_extract/gettext.html:13" => undef,
        "files_to_extract/gettext_loc.html:10" => undef,
        "files_to_extract/gettext_loc.html:13" => undef,
        "files_to_extract/maketext_loc.html:10" => undef,
        "files_to_extract/maketext_loc.html:13" => undef
      }
    }
  }
};
EOT
    },
    {
        test   => '15_extract_yaml',
        path   => 'example',
        script => '-I../lib 15_extract_yaml.pl',
        result => <<'EOT',
$lexicon_ref = {
  "i-default::" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    " " => {
      reference => {
        "files_to_extract/babelfish_loc.yml:21" => undef,
        "files_to_extract/gettext.yml:21" => undef,
        "files_to_extract/gettext_loc.yml:21" => undef,
        "files_to_extract/maketext_loc.yml:21" => undef
      }
    },
    Password => {
      reference => {
        "files_to_extract/babelfish_loc.yml:15" => undef,
        "files_to_extract/gettext.yml:15" => undef,
        "files_to_extract/gettext_loc.yml:15" => undef,
        "files_to_extract/maketext_loc.yml:15" => undef
      }
    },
    Username => {
      reference => {
        "files_to_extract/babelfish_loc.yml:10" => undef,
        "files_to_extract/gettext.yml:10" => undef,
        "files_to_extract/gettext_loc.yml:10" => undef,
        "files_to_extract/maketext_loc.yml:10" => undef
      }
    },
    login => {
      reference => {
        "files_to_extract/babelfish_loc.yml:23" => undef,
        "files_to_extract/gettext.yml:23" => undef,
        "files_to_extract/gettext_loc.yml:23" => undef,
        "files_to_extract/maketext_loc.yml:23" => undef
      }
    }
  }
};
EOT
    },
    {
        test   => '21_process',
        path   => 'example',
        script => '-I../lib 21_process_utf-8.pl',
        result => <<'EOT',
de/LC_MESSAGES/example1.po (clean)

msgid ""
msgstr ""
"Project-Id-Version: \n"
"POT-Creation-Date: \n"
"PO-Revision-Date: \n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

# comment 2
# comment 1
#: files_to_extract_for_process/gettext_loc.pl:14
msgid "January"
msgstr "Januar"

#. thing => 'text'
#: files_to_extract_for_process/gettext_loc.pl:15
msgid "This is a new {thing}."
msgstr ""

de-at/LC_MESSAGES/example1.po (clean)

msgid ""
msgstr ""
"Project-Id-Version: \n"
"POT-Creation-Date: \n"
"PO-Revision-Date: \n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

# comment 2
# comment 1
#: files_to_extract_for_process/gettext_loc.pl:14
msgid "January"
msgstr "Jänner"

EOT
    },
    {
        test   => '22_process_extended_skip',
        path   => 'example',
        script => '-I../lib 22_process_extended_skip_utf-8.pl',
        result => <<'EOT',
de/LC_MESSAGES/example1.po (clean)

msgid ""
msgstr ""
"Project-Id-Version: \n"
"POT-Creation-Date: \n"
"PO-Revision-Date: \n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

# comment 2
# comment 1
#: files_to_extract_for_process/gettext_loc.pl:14
msgid "January"
msgstr "Januar"

#. thing => 'text'
#: files_to_extract_for_process/gettext_loc.pl:15
msgid "This is a new {thing}."
msgstr ""

de-at/LC_MESSAGES/example1.po (clean)

msgid ""
msgstr ""
"Project-Id-Version: \n"
"POT-Creation-Date: \n"
"PO-Revision-Date: \n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

# comment 2
# comment 1
#: files_to_extract_for_process/gettext_loc.pl:14
msgid "January"
msgstr "Jänner"

#. thing => 'text'
#: files_to_extract_for_process/gettext_loc.pl:15
msgid "This is a new {thing}."
msgstr ""

EOT
    },
);

plan tests => 1 + @data;

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = decode_utf8( qx{perl $data->{script} 2>&1} );
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}

#!perl ## no critic (TidyCode)

use strict;
use warnings;
use utf8;

use Data::Dumper ();
use Locale::TextDomain::OO::Extract::TT;
use Path::Iterator::Rule;
use Path::Tiny qw(path);

our $VERSION = 0;

my $extractor = Locale::TextDomain::OO::Extract::TT->new(
    # In case of multiple extractors extract into the same array reference.
    # Parameter lexicon_ref is optional. If not set, there is a default.
    # Get back all of this by: $extractor->lexicon_ref
    lexicon_ref => \my %lexicon,
);

my @files = Path::Iterator::Rule
    ->new
    ->file( qw( *.tt *.tt2 ) )
    ->all( qw( ./files_to_extract ) );

for my $file ( map { path($_) } @files ) {
    $extractor->filename( $file->relative( q{./} )->stringify );
    $extractor->content_ref( \( $file->slurp_utf8 ) );
    $extractor->extract;
}

() = print {*STDOUT} Data::Dumper ## no critic (LongChainsOfMethodCalls)
    ->new( [ $extractor->lexicon_ref ], [ 'lexicon_ref' ] )
    ->Indent(1)
    ->Quotekeys(0)
    ->Sortkeys(1)
    ->Useqq(1)
    ->Dump;

# $Id: 12_extract_tt.pl 561 2014-11-11 16:12:48Z steffenw $

__END__

Output:

$lexicon_ref = {
  "i-default::" => {
    "" => {
      msgstr => {
        nplurals => 2,
        plural => "n != 1"
      }
    },
    January => {
      reference => {
        "files_to_extract/test_process.pl:16" => undef
      }
    },
    MSGID_ => {
      reference => {
        "files_to_extract/gettext.js:2" => undef,
        "files_to_extract/gettext.js:38" => undef,
        "files_to_extract/gettext_loc.js:2" => undef,
        "files_to_extract/gettext_loc.js:38" => undef
      }
    },
    "MSGID_n\0PLURAL_n" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:4" => undef,
        "files_to_extract/gettext.js:40" => undef,
        "files_to_extract/gettext_loc.js:4" => undef,
        "files_to_extract/gettext_loc.js:40" => undef
      }
    },
    "MSGID_np\0PLURAL_np\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:44" => undef,
        "files_to_extract/gettext.js:8" => undef,
        "files_to_extract/gettext_loc.js:44" => undef,
        "files_to_extract/gettext_loc.js:8" => undef
      }
    },
    "MSGID_npx\0PLURAL_npx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:45" => undef,
        "files_to_extract/gettext.js:9" => undef,
        "files_to_extract/gettext_loc.js:45" => undef,
        "files_to_extract/gettext_loc.js:9" => undef
      }
    },
    "MSGID_nx\0PLURAL_nx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:41" => undef,
        "files_to_extract/gettext.js:5" => undef,
        "files_to_extract/gettext_loc.js:41" => undef,
        "files_to_extract/gettext_loc.js:5" => undef
      }
    },
    "MSGID_p\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:42" => undef,
        "files_to_extract/gettext.js:6" => undef,
        "files_to_extract/gettext_loc.js:42" => undef,
        "files_to_extract/gettext_loc.js:6" => undef
      }
    },
    "MSGID_px\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:43" => undef,
        "files_to_extract/gettext.js:7" => undef,
        "files_to_extract/gettext_loc.js:43" => undef,
        "files_to_extract/gettext_loc.js:7" => undef
      }
    },
    "MSGID_x {key1} {key2}" => {
      automatic => "{ 'key1' : 'value1', 'key2' : 'value2' }",
      reference => {
        "files_to_extract/gettext.js:3" => undef,
        "files_to_extract/gettext.js:39" => undef,
        "files_to_extract/gettext_loc.js:3" => undef,
        "files_to_extract/gettext_loc.js:39" => undef
      }
    },
    "Singular\0Plural" => {
      automatic => 1,
      reference => {
        "files_to_extract/gettext.pl:24" => undef,
        "files_to_extract/gettext.pl:29" => undef,
        "files_to_extract/gettext.tt:27" => undef,
        "files_to_extract/gettext.tt:32" => undef,
        "files_to_extract/gettext_loc.pl:24" => undef,
        "files_to_extract/gettext_loc.pl:29" => undef,
        "files_to_extract/gettext_loc.tt:27" => undef,
        "files_to_extract/gettext_loc.tt:32" => undef
      }
    },
    "Text \x{c4}" => {
      reference => {
        "files_to_extract/gettext.tt:9" => undef,
        "files_to_extract/gettext_loc.tt:9" => undef,
        "files_to_extract/maketext_l.tt:9" => undef
      }
    },
    "Text \x{d6}" => {
      reference => {
        "files_to_extract/gettext.tt:13" => undef,
        "files_to_extract/gettext_loc.tt:13" => undef,
        "files_to_extract/maketext_l.tt:13" => undef
      }
    },
    "Text \x{dc}" => {
      reference => {
        "files_to_extract/gettext.tt:16" => undef,
        "files_to_extract/gettext_loc.tt:16" => undef,
        "files_to_extract/maketext_l.tt:16" => undef
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
        "files_to_extract/gettext.tt:21" => undef,
        "files_to_extract/gettext_loc.pl:16" => undef,
        "files_to_extract/gettext_loc.tt:21" => undef
      }
    },
    "This is an old text." => {
      reference => {
        "files_to_extract/test_process.pl:14" => undef
      }
    },
    "\\' quoted text with \\\\." => {
      reference => {
        "files_to_extract/gettext.pl:83" => undef,
        "files_to_extract/gettext_loc.pl:83" => undef
      }
    },
    "date\0dates\4appointment" => {
      automatic => 1,
      reference => {
        "files_to_extract/gettext.pl:55" => undef,
        "files_to_extract/gettext.pl:61" => undef,
        "files_to_extract/gettext.tt:58" => undef,
        "files_to_extract/gettext.tt:64" => undef,
        "files_to_extract/gettext_loc.pl:55" => undef,
        "files_to_extract/gettext_loc.pl:61" => undef,
        "files_to_extract/gettext_loc.tt:58" => undef,
        "files_to_extract/gettext_loc.tt:64" => undef
      }
    },
    "date\4appointment" => {
      reference => {
        "files_to_extract/gettext.pl:46" => undef,
        "files_to_extract/gettext.tt:49" => undef,
        "files_to_extract/gettext_loc.pl:46" => undef,
        "files_to_extract/gettext_loc.tt:49" => undef
      }
    },
    "q\\{ quoted text with {placeholders\\}}." => {
      reference => {
        "files_to_extract/gettext.pl:86" => undef,
        "files_to_extract/gettext_loc.pl:86" => undef
      }
    },
    "quoted text." => {
      reference => {
        "files_to_extract/gettext.pl:89" => undef,
        "files_to_extract/gettext_loc.pl:89" => undef
      }
    },
    "text of domain d and category c" => {
      reference => {
        "files_to_extract/gettext.pl:112" => undef,
        "files_to_extract/gettext.pl:118" => undef,
        "files_to_extract/gettext_loc.pl:112" => undef,
        "files_to_extract/gettext_loc.pl:118" => undef
      }
    },
    "text of domain d and no category" => {
      reference => {
        "files_to_extract/gettext.pl:110" => undef,
        "files_to_extract/gettext_loc.pl:110" => undef
      }
    },
    "text of no domain and category c" => {
      reference => {
        "files_to_extract/gettext.pl:114" => undef,
        "files_to_extract/gettext_loc.pl:114" => undef
      }
    },
    "text of no domain and no category" => {
      reference => {
        "files_to_extract/gettext.pl:108" => undef,
        "files_to_extract/gettext.pl:116" => undef,
        "files_to_extract/gettext.pl:120" => undef,
        "files_to_extract/gettext_loc.pl:108" => undef,
        "files_to_extract/gettext_loc.pl:116" => undef,
        "files_to_extract/gettext_loc.pl:120" => undef
      }
    },
    "{name} is programming {language}." => {
      automatic => "name => 'Steffen', language => 'Perl',",
      reference => {
        "files_to_extract/gettext.pl:19" => undef,
        "files_to_extract/gettext.tt:22" => undef,
        "files_to_extract/gettext_loc.pl:19" => undef,
        "files_to_extract/gettext_loc.tt:22" => undef
      }
    },
    "{num} date\0{num} dates" => {
      automatic => "1, num => 1,",
      reference => {
        "files_to_extract/gettext.pl:34" => undef,
        "files_to_extract/gettext.pl:40" => undef,
        "files_to_extract/gettext.tt:37" => undef,
        "files_to_extract/gettext.tt:43" => undef,
        "files_to_extract/gettext_loc.pl:34" => undef,
        "files_to_extract/gettext_loc.pl:40" => undef,
        "files_to_extract/gettext_loc.tt:37" => undef,
        "files_to_extract/gettext_loc.tt:43" => undef
      }
    },
    "{num} date\0{num} dates\4appointment" => {
      automatic => "1, num => 1,",
      reference => {
        "files_to_extract/gettext.pl:67" => undef,
        "files_to_extract/gettext.pl:74" => undef,
        "files_to_extract/gettext.tt:70" => undef,
        "files_to_extract/gettext.tt:77" => undef,
        "files_to_extract/gettext_loc.pl:67" => undef,
        "files_to_extract/gettext_loc.pl:74" => undef,
        "files_to_extract/gettext_loc.tt:70" => undef,
        "files_to_extract/gettext_loc.tt:77" => undef
      }
    },
    "{num} date\4appointment" => {
      automatic => "num => 1,",
      reference => {
        "files_to_extract/gettext.pl:50" => undef,
        "files_to_extract/gettext.tt:53" => undef,
        "files_to_extract/gettext_loc.pl:50" => undef,
        "files_to_extract/gettext_loc.tt:53" => undef
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
    MSGID_d => {
      reference => {
        "files_to_extract/gettext.js:11" => undef,
        "files_to_extract/gettext.js:47" => undef,
        "files_to_extract/gettext_loc.js:11" => undef,
        "files_to_extract/gettext_loc.js:47" => undef
      }
    },
    "MSGID_dn\0PLURAL_dn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:13" => undef,
        "files_to_extract/gettext.js:49" => undef,
        "files_to_extract/gettext_loc.js:13" => undef,
        "files_to_extract/gettext_loc.js:49" => undef
      }
    },
    "MSGID_dnp\0PLURAL_dnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:17" => undef,
        "files_to_extract/gettext.js:53" => undef,
        "files_to_extract/gettext_loc.js:17" => undef,
        "files_to_extract/gettext_loc.js:53" => undef
      }
    },
    "MSGID_dnpx\0PLURAL_dnpx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:18" => undef,
        "files_to_extract/gettext.js:54" => undef,
        "files_to_extract/gettext_loc.js:18" => undef,
        "files_to_extract/gettext_loc.js:54" => undef
      }
    },
    "MSGID_dnx\0PLURAL_dnx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:14" => undef,
        "files_to_extract/gettext.js:50" => undef,
        "files_to_extract/gettext_loc.js:14" => undef,
        "files_to_extract/gettext_loc.js:50" => undef
      }
    },
    "MSGID_dp\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:15" => undef,
        "files_to_extract/gettext.js:51" => undef,
        "files_to_extract/gettext_loc.js:15" => undef,
        "files_to_extract/gettext_loc.js:51" => undef
      }
    },
    "MSGID_dpx\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:16" => undef,
        "files_to_extract/gettext.js:52" => undef,
        "files_to_extract/gettext_loc.js:16" => undef,
        "files_to_extract/gettext_loc.js:52" => undef
      }
    },
    MSGID_dx => {
      reference => {
        "files_to_extract/gettext.js:12" => undef,
        "files_to_extract/gettext.js:48" => undef,
        "files_to_extract/gettext_loc.js:12" => undef,
        "files_to_extract/gettext_loc.js:48" => undef
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
        "files_to_extract/gettext_loc.pl:96" => undef
      }
    },
    "singular dnp\0plural dnp\4context dnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:97" => undef,
        "files_to_extract/gettext_loc.pl:97" => undef
      }
    },
    "text d" => {
      reference => {
        "files_to_extract/gettext.pl:94" => undef,
        "files_to_extract/gettext_loc.pl:94" => undef
      }
    },
    "text dp\4context dp" => {
      reference => {
        "files_to_extract/gettext.pl:95" => undef,
        "files_to_extract/gettext_loc.pl:95" => undef
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
    MSGID_c => {
      reference => {
        "files_to_extract/gettext.js:20" => undef,
        "files_to_extract/gettext.js:56" => undef,
        "files_to_extract/gettext_loc.js:20" => undef,
        "files_to_extract/gettext_loc.js:56" => undef
      }
    },
    "MSGID_cn\0PLURAL_cn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:22" => undef,
        "files_to_extract/gettext.js:58" => undef,
        "files_to_extract/gettext_loc.js:22" => undef,
        "files_to_extract/gettext_loc.js:58" => undef
      }
    },
    "MSGID_cnp\0PLURAL_cnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:26" => undef,
        "files_to_extract/gettext.js:62" => undef,
        "files_to_extract/gettext_loc.js:26" => undef,
        "files_to_extract/gettext_loc.js:62" => undef
      }
    },
    "MSGID_cnpx\0PLURAL_cnpx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:27" => undef,
        "files_to_extract/gettext.js:63" => undef,
        "files_to_extract/gettext_loc.js:27" => undef,
        "files_to_extract/gettext_loc.js:63" => undef
      }
    },
    "MSGID_cnx\0PLURAL_cnx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:23" => undef,
        "files_to_extract/gettext.js:59" => undef,
        "files_to_extract/gettext_loc.js:23" => undef,
        "files_to_extract/gettext_loc.js:59" => undef
      }
    },
    "MSGID_cp\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:24" => undef,
        "files_to_extract/gettext.js:60" => undef,
        "files_to_extract/gettext_loc.js:24" => undef,
        "files_to_extract/gettext_loc.js:60" => undef
      }
    },
    "MSGID_cpx\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:25" => undef,
        "files_to_extract/gettext.js:61" => undef,
        "files_to_extract/gettext_loc.js:25" => undef,
        "files_to_extract/gettext_loc.js:61" => undef
      }
    },
    MSGID_cx => {
      reference => {
        "files_to_extract/gettext.js:21" => undef,
        "files_to_extract/gettext.js:57" => undef,
        "files_to_extract/gettext_loc.js:21" => undef,
        "files_to_extract/gettext_loc.js:57" => undef
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
    MSGID_dc => {
      reference => {
        "files_to_extract/gettext.js:29" => undef,
        "files_to_extract/gettext.js:65" => undef,
        "files_to_extract/gettext_loc.js:29" => undef,
        "files_to_extract/gettext_loc.js:65" => undef
      }
    },
    "MSGID_dcn\0PLURAL_dcn" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:31" => undef,
        "files_to_extract/gettext.js:67" => undef,
        "files_to_extract/gettext_loc.js:31" => undef,
        "files_to_extract/gettext_loc.js:67" => undef
      }
    },
    "MSGID_dcnp\0PLURAL_dcnp\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:35" => undef,
        "files_to_extract/gettext.js:71" => undef,
        "files_to_extract/gettext_loc.js:35" => undef,
        "files_to_extract/gettext_loc.js:71" => undef
      }
    },
    "MSGID_dcnpx\0PLURAL_dcnpx\4MSGCTXT" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:36" => undef,
        "files_to_extract/gettext.js:72" => undef,
        "files_to_extract/gettext_loc.js:36" => undef,
        "files_to_extract/gettext_loc.js:72" => undef
      }
    },
    "MSGID_dcnx\0PLURAL_dcnx" => {
      automatic => "COUNT",
      reference => {
        "files_to_extract/gettext.js:32" => undef,
        "files_to_extract/gettext.js:68" => undef,
        "files_to_extract/gettext_loc.js:32" => undef,
        "files_to_extract/gettext_loc.js:68" => undef
      }
    },
    "MSGID_dcp\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:33" => undef,
        "files_to_extract/gettext.js:69" => undef,
        "files_to_extract/gettext_loc.js:33" => undef,
        "files_to_extract/gettext_loc.js:69" => undef
      }
    },
    "MSGID_dcpx\4MSGCTXT" => {
      reference => {
        "files_to_extract/gettext.js:34" => undef,
        "files_to_extract/gettext.js:70" => undef,
        "files_to_extract/gettext_loc.js:34" => undef,
        "files_to_extract/gettext_loc.js:70" => undef
      }
    },
    MSGID_dcx => {
      reference => {
        "files_to_extract/gettext.js:30" => undef,
        "files_to_extract/gettext.js:66" => undef,
        "files_to_extract/gettext_loc.js:30" => undef,
        "files_to_extract/gettext_loc.js:66" => undef
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
        "files_to_extract/gettext_loc.pl:99" => undef
      }
    },
    "singular cnp\0plural cnp\4context cnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:101" => undef,
        "files_to_extract/gettext_loc.pl:101" => undef
      }
    },
    "text c" => {
      reference => {
        "files_to_extract/gettext.pl:98" => undef,
        "files_to_extract/gettext_loc.pl:98" => undef
      }
    },
    "text cp\4context cp" => {
      reference => {
        "files_to_extract/gettext.pl:100" => undef,
        "files_to_extract/gettext_loc.pl:100" => undef
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
        "files_to_extract/gettext_loc.pl:103" => undef
      }
    },
    "singular dcnp\0plural dcnp\4context dcnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:105" => undef,
        "files_to_extract/gettext_loc.pl:105" => undef
      }
    },
    "text dc" => {
      reference => {
        "files_to_extract/gettext.pl:102" => undef,
        "files_to_extract/gettext_loc.pl:102" => undef
      }
    },
    "text dcp\4context dcp" => {
      reference => {
        "files_to_extract/gettext.pl:104" => undef,
        "files_to_extract/gettext_loc.pl:104" => undef
      }
    }
  }
};

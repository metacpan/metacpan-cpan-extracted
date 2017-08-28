#!perl ## no critic (TidyCode)

use strict;
use warnings;

use Data::Dumper ();
use Locale::TextDomain::OO::Extract::JavaScript;
use Path::Iterator::Rule;
use Path::Tiny qw(path);

our $VERSION = 0;

my $extractor = Locale::TextDomain::OO::Extract::JavaScript->new(
    # In case of multiple extractors extract into the same array reference.
    # Parameter lexicon_ref is optional. If not set, there is a default.
    # Get back all of this by: $extractor->lexicon_ref
    lexicon_ref => \my %lexicon,
);

my @files = Path::Iterator::Rule ## no critic (LongChainsOfMethodCalls)
    ->new
    ->file
    ->name( qw( *.js ) )
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

# $Id: 13_extract_js.pl 683 2017-08-22 18:41:42Z steffenw $

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

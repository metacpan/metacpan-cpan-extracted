#!perl ## no critic (TidyCode)

use strict;
use warnings;

use Data::Dumper ();
use Locale::TextDomain::OO::Extract::Perl;
use Path::Iterator::Rule;
use Path::Tiny qw(path);

our $VERSION = 0;

my $extractor = Locale::TextDomain::OO::Extract::Perl->new(
    # In case of multiple extractors extract into the same array reference.
    # Parameter lexicon_ref is optional. If not set, there is a default.
    # Get back all of this by: $extractor->lexicon_ref
    lexicon_ref => \my %lexicon,
);

my @files = Path::Iterator::Rule ## no critic (LongChainsOfMethodCalls)
    ->new
    ->file
    ->name( qw( *.pl *.pm ) )
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

# $Id: 11_extract_perl.pl 683 2017-08-22 18:41:42Z steffenw $

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
    "' quoted text with \\\\." => {
      reference => {
        "files_to_extract/gettext.pl:83" => undef,
        "files_to_extract/gettext_loc.pl:93" => undef
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
    date => {
      automatic => "foo => 'bar',",
      reference => {
        "files_to_extract/gettext_loc.pl:81" => undef
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
        "files_to_extract/gettext_loc.pl:85" => undef,
        "files_to_extract/maketext.pl:32" => undef,
        "files_to_extract/maketext_loc.pl:32" => undef,
        "files_to_extract/maketext_localise.pl:32" => undef,
        "files_to_extract/maketext_localize.pl:32" => undef
      }
    },
    "quoted text." => {
      reference => {
        "files_to_extract/gettext.pl:89" => undef,
        "files_to_extract/gettext_loc.pl:99" => undef
      }
    },
    "q{ quoted text with {placeholders}}." => {
      reference => {
        "files_to_extract/gettext.pl:86" => undef,
        "files_to_extract/gettext_loc.pl:96" => undef
      }
    },
    "text of no domain and no category" => {
      reference => {
        "files_to_extract/gettext.pl:108" => undef,
        "files_to_extract/gettext.pl:116" => undef,
        "files_to_extract/gettext.pl:120" => undef,
        "files_to_extract/gettext_loc.pl:118" => undef,
        "files_to_extract/gettext_loc.pl:126" => undef,
        "files_to_extract/gettext_loc.pl:130" => undef
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
        "files_to_extract/gettext_loc.pl:106" => undef
      }
    },
    "singular dnp\0plural dnp\4context dnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:97" => undef,
        "files_to_extract/gettext_loc.pl:107" => undef
      }
    },
    "text d" => {
      reference => {
        "files_to_extract/gettext.pl:94" => undef,
        "files_to_extract/gettext_loc.pl:104" => undef
      }
    },
    "text dp\4context dp" => {
      reference => {
        "files_to_extract/gettext.pl:95" => undef,
        "files_to_extract/gettext_loc.pl:105" => undef
      }
    },
    "text of domain d and no category" => {
      reference => {
        "files_to_extract/gettext.pl:110" => undef,
        "files_to_extract/gettext_loc.pl:120" => undef
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
        "files_to_extract/gettext_loc.pl:109" => undef
      }
    },
    "singular cnp\0plural cnp\4context cnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:101" => undef,
        "files_to_extract/gettext_loc.pl:111" => undef
      }
    },
    "text c" => {
      reference => {
        "files_to_extract/gettext.pl:98" => undef,
        "files_to_extract/gettext_loc.pl:108" => undef
      }
    },
    "text cp\4context cp" => {
      reference => {
        "files_to_extract/gettext.pl:100" => undef,
        "files_to_extract/gettext_loc.pl:110" => undef
      }
    },
    "text of no domain and category c" => {
      reference => {
        "files_to_extract/gettext.pl:114" => undef,
        "files_to_extract/gettext_loc.pl:124" => undef
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
        "files_to_extract/gettext_loc.pl:113" => undef
      }
    },
    "singular dcnp\0plural dcnp\4context dcnp" => {
      automatic => 0,
      reference => {
        "files_to_extract/gettext.pl:105" => undef,
        "files_to_extract/gettext_loc.pl:115" => undef
      }
    },
    "text dc" => {
      reference => {
        "files_to_extract/gettext.pl:102" => undef,
        "files_to_extract/gettext_loc.pl:112" => undef
      }
    },
    "text dcp\4context dcp" => {
      reference => {
        "files_to_extract/gettext.pl:104" => undef,
        "files_to_extract/gettext_loc.pl:114" => undef
      }
    },
    "text of domain d and category c" => {
      reference => {
        "files_to_extract/gettext.pl:112" => undef,
        "files_to_extract/gettext.pl:118" => undef,
        "files_to_extract/gettext_loc.pl:122" => undef,
        "files_to_extract/gettext_loc.pl:128" => undef
      }
    }
  }
};

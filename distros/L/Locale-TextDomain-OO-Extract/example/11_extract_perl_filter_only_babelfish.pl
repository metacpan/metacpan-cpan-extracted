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
    # scan only BabelFish styles of writing
    filter      => [ qw(
        BabelFish::Loc
        BabelFish::Loc::DomainAndCategory
    ) ],
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

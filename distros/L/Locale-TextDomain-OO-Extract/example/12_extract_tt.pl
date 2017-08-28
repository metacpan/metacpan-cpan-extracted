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

my @files = Path::Iterator::Rule ## no critic (LongChainsOfMethodCalls)
    ->new
    ->file
    ->name( qw( *.tt *.tt2 ) )
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

# $Id: 12_extract_tt.pl 683 2017-08-22 18:41:42Z steffenw $

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
    "This is a text." => {
      reference => {
        "files_to_extract/gettext.tt:21" => undef,
        "files_to_extract/gettext_loc.tt:21" => undef
      }
    },
    date => {
      reference => {
        "files_to_extract/gettext_loc.tt:84" => undef
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
        "files_to_extract/gettext.tt:49" => undef,
        "files_to_extract/gettext_loc.tt:49" => undef,
        "files_to_extract/gettext_loc.tt:87" => undef
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

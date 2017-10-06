#!perl ## no critic (TidyCode)

use strict;
use warnings;

use Data::Dumper ();
use Locale::TextDomain::OO::Extract::YAML;
use Path::Iterator::Rule;
use Path::Tiny qw(path);

our $VERSION = 0;

my $extractor = Locale::TextDomain::OO::Extract::YAML->new(
    # In case of multiple extractors extract into the same array reference.
    # Parameter lexicon_ref is optional. If not set, there is a default.
    # Get back all of this by: $extractor->lexicon_ref
    lexicon_ref => \my %lexicon,
);

my @files = Path::Iterator::Rule ## no critic (LongChainsOfMethodCalls)
    ->new
    ->file
    ->name( qw( *.yml ) )
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

# $Id: 15_extract_yaml.pl 695 2017-09-02 09:24:08Z steffenw $

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

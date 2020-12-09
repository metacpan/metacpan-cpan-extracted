use ExtUtils::MakeMaker;

require 5.006;

my $version  = '2.18';   # scanned by bin/collect_types !

WriteMakefile
  ( NAME      => 'MIME::Types'
  , VERSION   => $version
  , PREREQ_PM =>
    { Test::More     => 0.47
    , File::Spec     => 0
    , File::Basename => 0
    , List::Util     => 0
    }
  , AUTHOR    => 'Mark Overmeer <markov@cpan.org>'
  , ABSTRACT  => 'Definition of MIME types'
  , LICENSE   => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-MIME-Types.git'
              , web  => 'https://github.com/markov2/perl5-MIME-Types'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/mime-types/raw
DISTDIR         = ../public_html/mime-types/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 1999
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

# for HTML
HTML_OUTPUT     = ../public_html/mime-types/html
HTML_DOCROOT    = /mime-types/html
HTML_PACKAGE    = ../public_html/mime-types/htmlpkg

__POSTAMBLE

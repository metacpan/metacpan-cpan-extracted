use ExtUtils::MakeMaker;

require 5.010;

WriteMakefile
  ( NAME        => 'Math::Polygon'
  , VERSION     => '1.11'
  , PREREQ_PM   =>
     { Test::More    => 0.47
     , Scalar::Util  => 1.13
     , Math::Trig    => 0
     }
  , AUTHOR      => 'Mark Overmeer <markov@cpan.org>'
  , ABSTRACT    => 'basic polygon calculations'
  , LICENSE     => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Math-Polygon.git'
              , web  => 'https://github.com/markov2/perl5-Math-Polygon'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/math-polygon/raw
DISTDIR         = ../public_html/math-polygon/source

# for POD
FIRST_YEAR      = 2004
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE

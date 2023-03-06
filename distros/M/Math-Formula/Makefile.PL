#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use 5.016;

WriteMakefile
  ( NAME	 => 'Math::Formula'
  , VERSION      => '0.15'
  , PREREQ_PM    =>
    { 'Test::More'    => 0,
    , 'Log::Report'   => 0,
	, 'POSIX'         => 0,
	, 'Scalar::Util'  => 0,
	, 'File::Spec'    => 0,
	, 'File::Slurper' => 0,

	, 'DateTime'           => 0,
	, 'DateTime::Duration' => 0,
	, 'DateTime::TimeZone' => 0,
	, 'DateTime::TimeZone::OffsetOnly' => 0,
    , 'DateTime::Format::Duration::ISO8601' => 0.006,
    }
  , AUTHOR       => 'Mark Overmeer <markov@cpan.org>'
  , ABSTRACT     => 'Expressions on steroids'
  , LICENSE      => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Math-Formula.git'
              , web  => 'https://github.com/markov2/perl5-Math-Formula'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/math-formula/raw
DISTDIR         = ../public_html/math-formula/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2023
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

__POSTAMBLE


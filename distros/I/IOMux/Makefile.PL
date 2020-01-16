#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use 5.008;

my $version = '1.01';

WriteMakefile
 ( NAME	 	=> 'IOMux'
 , VERSION	=> $version
 , PREREQ_PM    =>
    { Test::More  => 0.80
    , IO::Socket  => 1.18
    , Log::Report => 0.91
    }
 , EXE_FILES    => []
 , ABSTRACT     => 'Abstraction of event loop'
 , AUTHOR       => 'Mark Overmeer <markov@cpan.org>'
 , LICENSE      => 'perl_5'

 , META_MERGE   =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-IOMux.git'
              , web  => 'https://github.com/markov2/perl5-IOMux'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }

 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/iomux/raw
DISTDIR         = ../public_html/iomux/source

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/CPAN

EXTENDS		    = ../Any-Daemon
__POSTAMBLE

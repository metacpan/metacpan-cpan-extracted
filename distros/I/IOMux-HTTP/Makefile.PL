#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use 5.008;

my $version = '0.11';

WriteMakefile
 ( NAME	 	=> 'IOMux::HTTP'
 , VERSION	=> $version
 , PREREQ_PM    =>
    { Test::More  => 0.80
    , IOMux       => 0.12
    , Log::Report => 0.91
    , LWP         => 5.834
    , Time::HiRes => 1.9719
    }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'IOMux based HTTP'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/iomux-http/raw
DISTDIR         = ../public_html/iomux-http/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/

EXTENDS		= ../AnyDaemon:../IOMux
PODTAIL		= ../Mux-shared-podtail
__POSTAMBLE

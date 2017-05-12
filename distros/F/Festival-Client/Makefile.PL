#
# Skeleton Perl Makefile
#
# Last updated by gossamer on Wed Aug 12 21:44:27 EST 1998
#

require 5;
use strict;

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Festival::Client',
    'VERSION_FROM' => 'Client.pm',

    'dist'         => { 
                         COMPRESS => 'gzip -9f',
                         SUFFIX => '.gz',
                      },
);

sub MY::postamble {
   package MY;

   '

WEBDIR = /home/gossamer/websrc/docs/code
WEB_FILELIST = $(WEBDIR)/file-list

webdist: dist
	@$(MKPATH) $(WEBDIR)/$(DISTNAME)/
	cp $(DISTVNAME).tar$(SUFFIX) $(WEBDIR)/$(DISTNAME)/
	cp README $(WEBDIR)/$(DISTNAME)/$(DISTVNAME).README

'
}


# Makefile.PL
#
# Author: Mike McCauley (mikem@airspayce.com)
# Copyright (C) 2006 Mike McCauley
# $Id: Makefile.PL,v 1.1 2006/05/31 23:30:53 mikem Exp $

use ExtUtils::MakeMaker;
WriteMakefile
    (
     NAME		=> 'Device::SNP',
     VERSION_FROM	=> 'Device/SNP.pm', # finds $VERSION
     EXE_FILES        => ['datapanel.pl'],
     PREREQ_PM      => {
		Device::SerialPort => 1.002,
	},
     
     ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Mike McCauley <mikem@airspayce.com>') : ()),
     dist          => {
         COMPRESS => 'gzip -f',
         SUFFIX   => 'gz',
	 POSTOP   => '$(MV) $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
     },
     );

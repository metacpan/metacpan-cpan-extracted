#!/usr/bin/env perl

# Creation date: 2003-04-06 13:26:22
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.9 2007/11/14 04:28:50 don Exp $

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
              NAME => 'File::Rotate::Backup',
              DISTNAME => 'File-Rotate-Backup',
              VERSION_FROM => 'lib/File/Rotate/Backup.pm',
              ABSTRACT => 'Performs system backups and rotates them',
              AUTHOR => 'Don Owens <don@regexguy.com>',
              PM => { 'lib/File/Rotate/Backup.pm' => '$(INST_LIBDIR)/Backup.pm',
                      'lib/File/Rotate/Backup/Copy.pm' => '$(INST_LIBDIR)/Backup/Copy.pm',
                    },
              PREREQ_PM => { 'File::Spec' => 0,
                             'Fcntl' => 0,
                           },
              dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              DIR => [],
              EXE_FILES => [],
             );


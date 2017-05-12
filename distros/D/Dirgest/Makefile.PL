
######################################################################
#
#    Directory Digest -- Makefile.PL
#    Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#    Copyright 2002 Matthew Gream. All Rights Reserved.
#    $Id: Makefile.PL,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#    
######################################################################

use ExtUtils::MakeMaker;
my @executables = qw(dirgest.cgi dirgest.pl);
WriteMakefile(
    'NAME'      => 'Dirgest',
    'VERSION'   => '0.90',
    'ABSTRACT'  => 'Directory Digests - cgi/cli digests of file/directory sets',
    'AUTHOR'    => 'Matthew Gream <matthew.gream@pobox.com>',
    'PREREQ_PM' => { Digest::MD5 => 0, 
                     LWP::UserAgent => 2.0,
                     File::Find => 0,
                     CGI => 0,
                     Getopt::Long => 2.24,
                     Test => 0,
                     Fcntl => 0,
                    },
    'PL_FILES'  => { 'Scripts.PL' => [ @executables ] },
    'EXE_FILES' => [ @executables ],
    clean       => { FILES => join(' ', @executables) },
);


#!/usr/local/bin/perl 

use File::Copy;
use File::Path;

print "\n\nMakefile.PL for Db-DFC\n\n";

foreach (@INC) {
    if (/site.lib/) {
        print "Copying dm_JCast.class to $_ ...\n";
        copy("dm_JCast.class","$_/dm_JCast.class") || warn "Copy Error: $!";
        last;
    }        
}


use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Db::DFC',
    'VERSION_FROM'	=> 'DFC.pm', # finds $VERSION
    'PREREQ_PM'		=> {'JNI' => ''}, # e.g., Module::Name => 1.1
    'AUTHOR'    => 'M. Scott Roth (michael.s.roth@saic.com)',
    'ABSTRACT'  => 'Interface to Documentum\'s DFC Java classes'
);



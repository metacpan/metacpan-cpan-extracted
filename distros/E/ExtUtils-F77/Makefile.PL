
# Makefile.PL for ExtUtils::F77

use ExtUtils::MakeMaker;
# # See lib/ExtUtils/MakeMaker.pm for details of how to influence
# # the contents of the Makefile that is written.
WriteMakefile(
     'NAME'          => 'ExtUtils::F77',
     'ABSTRACT'      => 'a simple interface to F77 libs',
     'AUTHOR'        => 'Karl Glazebrook <karlglazebrook@yahoo.com>',
     'LICENSE'       => 'perl_5',
     'VERSION_FROM'  => 'F77.pm',  
     'dist'     => { COMPRESS=>"gzip", SUFFIX=>"gz" },  # Is this still needed?
 );


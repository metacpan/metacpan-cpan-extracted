use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'HTML::Clean',
    'VERSION_FROM' => 'lib/HTML/Clean.pm', # finds $VERSION
    'EXE_FILES'    => [ 'bin/htmlclean' ],    
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

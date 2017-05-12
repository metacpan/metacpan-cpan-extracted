use ExtUtils::MakeMaker;
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
# If any modules outside of the core perl distribution are required,
# these should be included as a PREREQ_PM entry in WriteMakefile below, 
# as indicated in the example. This example requires the modules 
# MOD1 and MOD2 to be installed, with minimal versions 1 and 5,
# respectively. If the version number is 0, any version is sufficient.
#
# As well, if you wish to force a minimal perl version to run the
# script, insert a line, for example,
#
#   require 5.004;
#
# below.

WriteMakefile(
    'NAME'	=> 'HTMLTMPL',
    'VERSION_FROM' => 'HTMLTMPL.pm', # finds $VERSION
    'dist'  => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'EXE_FILES' => [ 'HTMLTMPL.pm' ], # scripts to install
# Uncomment and edit the following line to include required modules
#   'PREREQ_PM' => { 'MOD1' => 1, 'MOD2' => 5 },
);


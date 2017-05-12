use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::HE::Sentence',
    'VERSION_FROM'	=> 'lib/Lingua/HE/Sentence.pm', # finds $VERSION
    'PREREQ_PM'		=> {Test::More => 0.47}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
    'dist'		=> {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'}
);

print "\n";
print "Please take a moment to review the license.\n\n";
print "Do a 'make' to create the Makefile\n";
print "Do a 'make test' to test the module before installation\n";
print "Do a 'make install' to install the module.\n"; 

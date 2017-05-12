use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Decision::ACL',
    'VERSION_FROM' => 'ACL.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'clean'        => { 'FILES' => 'pod2html*', },
    'dist'    => { 'PREOP' => 'pod2text ACL.pm > README; pod2html ACL.pm > README.html', },
);

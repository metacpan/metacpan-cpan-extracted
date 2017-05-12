use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Mail::SMI',
    'VERSION_FROM'	=> 'SMI.pm', # finds $VERSION
    'AUTHOR'		=> 'Daniel Froz Costa (dfroz@users.sourceforge.net)'
);

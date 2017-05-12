use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'INSTALLDIRS' => 'perl',
    'NAME'	=> 'Devel::ptkdb',
    'VERSION_FROM' => 'ptkdb.pm', # finds $VERSION
);

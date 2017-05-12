use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DirDB::Storable',
    'VERSION_FROM'	=> 'Storable.pm', # finds $VERSION
    'PREREQ_PM'		=> {Storable => 1}, # e.g., Module::Name => 1.1
);

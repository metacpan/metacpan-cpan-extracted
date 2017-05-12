use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MPEG::Info',
    'VERSION_FROM'	=> 'Info.pm', # finds $VERSION
    'PREREQ_PM'		=> { Video::Info => 0.06 }, # e.g., Module::Name => 1.1
);

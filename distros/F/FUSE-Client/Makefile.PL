use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'FUSE::Client',
    'VERSION_FROM'	=> 'Client.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'IO::Socket' => 1.00 }
);

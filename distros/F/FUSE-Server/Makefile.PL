use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'FUSE::Server',
    'VERSION_FROM'	=> 'Server.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'IO::Socket' => 1.00, 'IO::Select' => 1.00 }
);

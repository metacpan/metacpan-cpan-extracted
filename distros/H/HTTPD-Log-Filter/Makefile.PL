use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTPD::Log::Filter',
    'EXE_FILES'         => [ 'exclude_robots' ],
    'VERSION_FROM'      => 'lib/HTTPD/Log/Filter.pm',
    'PREREQ_PM'		=> {
        IO::File        => 0,
        IO::Zlib        => 0,
    },
);

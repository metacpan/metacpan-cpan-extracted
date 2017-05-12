use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTPD::Log::Merge',
    'VERSION_FROM'      => 'lib/HTTPD/Log/Merge.pm',
    'PREREQ_PM'		=> {
        IO::File                => undef,
        Date::Parse             => undef,
        HTTPD::Log::Filter      => 1.03,
    },
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::Rollup',
    'VERSION_FROM'	=> 'Rollup.pm', # finds $VERSION
    'PREREQ_PM'		=> { CGI::Util => 1.3 }, # e.g., Module::Name => 1.1
);

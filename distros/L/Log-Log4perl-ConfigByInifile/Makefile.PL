

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Log::Log4perl::ConfigByInifile',
    VERSION_FROM => 'lib/Log/Log4perl/ConfigByInifile.pm', # finds \$VERSION
    AUTHOR       => 'Richard Lippmann (horshack@lisa.franken.de)',
    ABSTRACT     => 'Get Log::Log4perl config from an ini-File',
    PREREQ_PM => {
        'Test::Simple'     => 0.44,
        'Test::More'       => undef,
        'Log::Log4perl'    => undef,
        'FindBin'          => undef,
        'Config::IniFiles' => undef,
        'Params::Validate' => undef,
      },
);

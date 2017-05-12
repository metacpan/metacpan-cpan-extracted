

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Logic::Tools',
    VERSION_FROM => 'lib/Logic/Tools.pm', # finds \$VERSION
    AUTHOR       => 'Lagutas (lagutas@gmail.com)',
    ABSTRACT     => 'Application to make life easier',
    PREREQ_PM    => {
                        'Test::Simple' => 0.44,
            			'Test::Strict' => 0.14,
            			'Test::Fixme' => 0.04,
            			'Test::Perl::Critic' => 1.02,
            			'Test::Pod' => 1.44,
            			'Test::Pod::Coverage' => 1.08,
            			'Test::Fork' => 0.02,
            			'Config::IniFiles' => 2.75,
            			'Archive::Tar' => 1.58,
            			'Log::Any' => 1.032,
            			'Log::Any::Adapter::Syslog' => 1.5
                    },
);

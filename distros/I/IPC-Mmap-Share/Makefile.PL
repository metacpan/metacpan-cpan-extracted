

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'IPC::Mmap::Share',
    VERSION_FROM => 'lib/IPC/Mmap/Share.pm', # finds \$VERSION
    AUTHOR       => 'Athanasios Douitsis (aduitsis@cpan.org)',
    ABSTRACT     => 'Safely share structures using anonymous mmap',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
			Storable => 0,
			IPC::Mmap => 0,
                    },
);

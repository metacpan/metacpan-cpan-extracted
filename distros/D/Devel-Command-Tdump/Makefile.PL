use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Devel::Command::Tdump',
    VERSION_FROM => 'lib/Devel/Command/Tdump.pm', # finds $VERSION
    AUTHOR       => 'Joe McMahon (mcmahon@cpan.org)',
    ABSTRACT     => 'embedded test support in the debugger',
    PREREQ_PM    => {
                     'Test::More' => 0,
                     'Devel::Command' => 0,
                    },
);



use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Format::LongNumber',
    VERSION_FROM => 'lib/Format/LongNumber.pm', # finds \$VERSION
    AUTHOR       => 'Mikhail N Bogdanov (bogdanovmn@gmail.com)',
    ABSTRACT     => 'Human-like long numbers',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);

use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::DyckWords',
    VERSION_FROM      => 'lib/Math/DyckWords.pm',
    PREREQ_PM         => { 'Math::BigInt' },
    ( $] >= 5.005
        ? ( ABSTRACT_FROM  => 'lib/Math/DyckWords.pm',
            AUTHOR         => 'Mark Mertel <mmertel@cpan.org>' )
        : ()
    ),
);

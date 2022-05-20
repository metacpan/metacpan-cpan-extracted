use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Math::Round::SignificantFigures',
    VERSION_FROM   => 'lib/Math/Round/SignificantFigures.pm',
    PREREQ_PM      => {
                       POSIX => 0,
                      },
    ABSTRACT_FROM  => 'lib/Math/Round/SignificantFigures.pm',
    AUTHOR         => 'Michael R. Davis',
);

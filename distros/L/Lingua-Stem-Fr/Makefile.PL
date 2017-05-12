use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::Stem::Fr',
    VERSION_FROM      => 'lib/Lingua/Stem/Fr.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ? () : (     ## Add these new keywords supported since 5.005
        'AUTHOR'                => 'Sébastien Darribere-Pleyt <sebastien.darribere@lefute.com>',
        'ABSTRACT'              => 'Porter\'s stemming algorithm for French',
    )),
);


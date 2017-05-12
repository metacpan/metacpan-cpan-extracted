use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::JA::Sort::ReadableKey',
    VERSION_FROM      => 'lib/Lingua/JA/Sort/ReadableKey.pm', # finds $VERSION
    PREREQ_PM         => {Text::ChaSen => 0,
                          Encode => 0},
);

warn 'If you do not have Text::ChaSen, it comes as part of the ChaSen
distribution from http://chasen.aist-nara.ac.jp/ or as
libtext-chasen-perl in Debian' unless eval { require Text::ChaSen};


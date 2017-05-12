use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Lingua::JA::Summarize',
    VERSION_FROM => 'lib/Lingua/JA/Summarize.pm',
    PREREQ_PM => {
        Jcode => 0,
    },
    ABSTRACT_FROM => 'lib/Lingua/JA/Summarize.pm',
    AUTHOR => 'Kazuho Oku <kazuhooku ___at___ gmail.com>',
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Lingua::JA::Romaji::Valid',
    AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM   => 'lib/Lingua/JA/Romaji/Valid.pm',
    ABSTRACT_FROM  => 'lib/Lingua/JA/Romaji/Valid.pm',
    PREREQ_PM => {
        'Test::UseAllModules' => 0,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE => 'perl') : ()
    ),
);

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Language::Prolog::Sugar',
               VERSION_FROM => 'Sugar.pm',
               PREREQ_PM => {'Language::Prolog::Types' => 0,
                             'Test::More' => 0 },
               ABSTRACT_FROM => 'Sugar.pm',
               AUTHOR => 'Salvador Fandiño <sfandino@yahoo.com>' );

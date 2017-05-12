use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME          => 'HTML::PopupTreeSelect',
              VERSION_FROM  => 'PopupTreeSelect.pm',
              PREREQ_PM     => {
                                Test::More     => 0,
                                Carp           => 0,
                                HTML::Template => 2.6,
                               },
              ABSTRACT_FROM => 'PopupTreeSelect.pm',
              AUTHOR        => 'Sam Tregar <sam@tregar.com>',
             );

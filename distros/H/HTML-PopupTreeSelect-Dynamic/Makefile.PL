use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTML::PopupTreeSelect::Dynamic',
    VERSION_FROM      => 'Dynamic.pm',
    PREREQ_PM         => { 
                          'HTML::Prototype' => '1.33',
                          'HTML::PopupTreeSelect' => '1.5', 
                         },
    ABSTRACT_FROM     => 'Dynamic.pm',
    AUTHOR            => 'Sam <sam@tregar.com>',
);

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'LEGO::NXT',
    VERSION_FROM    => 'lib/LEGO/NXT.pm',
    ABSTRACT_FROM   => 'lib/LEGO/NXT.pm',
    AUTHOR          => 'Michael Collins <michaelcollins@ivorycity.com>',
    PREREQ_PM       => {
        'Net::Bluetooth' => 0,
    },
);

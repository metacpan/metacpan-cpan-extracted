use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Lingua::EO::Supersignoj',
    VERSION_FROM    => 'Supersignoj.pm',
    ABSTRACT_FROM   => 'Supersignoj.pm',
    PREREQ_PM       => { 'Attribute::Property' => '1.03' },
    AUTHOR          => 'Juerd',
);

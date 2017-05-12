use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Logic',
    VERSION_FROM      => 'lib/Logic.pm',
    PREREQ_PM         => {
        Perl6::Attributes   => 0,
        Scalar::Util        => 0,
        Devel::Caller::Perl => 0,
        Attribute::Handlers => 0,
        Filter::Simple      => 0,
    }, 
    ABSTRACT_FROM     => 'lib/Logic.pm',
    AUTHOR            => 'Luke Palmer <luke@luqui.org>',
);

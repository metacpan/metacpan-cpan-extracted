use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Domain::Register::TK',
    AUTHOR              => 'Dot TK Limited <partners@dot.tk>';
    VERSION_FROM        => 'lib/Domain/Register/TK.pm',
    ABSTRACT_FROM       => 'lib/Domain/Register/TK.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Domain-Register-TK-*' },
);

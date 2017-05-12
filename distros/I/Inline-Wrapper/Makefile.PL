use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Inline::Wrapper',
    AUTHOR              => 'Jason McManus (INFIDEL) <infidel@cpan.org>',
    VERSION_FROM        => 'lib/Inline/Wrapper.pm',
    ABSTRACT_FROM       => 'lib/Inline/Wrapper.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'File::Temp'        => 0,       # CORE since Perl 5.6.1
        'Test::More'        => 0,       # CORE since Perl 5.6.2
        'Inline'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Inline-Wrapper-*' },
);

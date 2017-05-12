use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'License::Syntax',
    AUTHOR              => q{Juergen Weigert <jw@suse.de>},
    VERSION_FROM        => 'Syntax.pm',
    ABSTRACT_FROM       => 'Syntax.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBD::SQLite' => 1,
        'Text::CSV' => 1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => ['License-Syntax-*', 't/tmpmap.csv', '*.orig', 't/*.orig' ] },
);

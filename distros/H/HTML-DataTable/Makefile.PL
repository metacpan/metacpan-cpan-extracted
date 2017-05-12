use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::DataTable',
    AUTHOR              => q{Nic Wolff <nic@angel.net>},
    VERSION_FROM        => 'lib/HTML/DataTable.pm',
    ABSTRACT_FROM       => 'lib/HTML/DataTable.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
				'HTML::FromArrayref' => 0,
				'DBI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-DataTable-*' },
);

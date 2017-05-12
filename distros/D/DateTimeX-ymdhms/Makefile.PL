use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DateTimeX::ymdhms',
    AUTHOR              => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    VERSION_FROM        => 'lib/DateTimeX/ymdhms.pm',
    ABSTRACT_FROM       => 'lib/DateTimeX/ymdhms.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'DateTime'            => '1.01',
                  'Test::Most'          => '0.25',
                  'Test::Perl::Critic'  => '1.02',
                  'Test::Pod'           => '1.45',
                  'Test::Pod::Coverage' => '1.08',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DateTimeX-ymdhms-*' },
);

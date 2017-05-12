use 5.10.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mason::Plugin::SliceFilter',
    AUTHOR              => q{Jerome Eteve <jerome.eteve@gmail.com>},
    VERSION_FROM        => 'lib/Mason/Plugin/SliceFilter.pm',
    ABSTRACT_FROM       => 'lib/Mason/Plugin/SliceFilter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Mason' => 2.15,
        'Test::Class::Most' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mason-Plugin-SliceFilter-*' },
    META_MERGE => {
                   resources => {
                                 repository => 'https://github.com/jeteve/Mason-Plugin-SliceFilter',
                                },
    },
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Memoize::Memcached',
    AUTHOR              => 'David Trischuk <trischuk@gmail.com>',
    VERSION_FROM        => 'lib/Memoize/Memcached.pm',
    ABSTRACT_FROM       => 'lib/Memoize/Memcached.pm',
    PL_FILES            => {},
    PREREQ_PM => {
      'Test::More'       => 0,
      'Carp'             => 0,
      'Memoize'          => 0,
      'Cache::Memcached' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Memoize-Memcached-*' },
);

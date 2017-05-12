use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JSON::RPC::Dispatcher::ClassMapping',
    AUTHOR              => q{Sherwin Daganato <sherwin@daganato.com>},
    VERSION_FROM        => 'lib/JSON/RPC/Dispatcher/ClassMapping.pm',
    ABSTRACT_FROM       => 'lib/JSON/RPC/Dispatcher/ClassMapping.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'JSON::RPC::Dispatcher' => '0.0505', 
        'Moose' => 0,
        'namespace::autoclean' => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/sherwind/JSON-RPC-Dispatcher-ClassMapping/issues',
            repository  => 'https://github.com/sherwind/JSON-RPC-Dispatcher-ClassMapping.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JSON-RPC-Dispatcher-ClassMapping-*' },
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'LightTCP::SSLclient',
    VERSION_FROM      => 'lib/LightTCP/SSLclient.pm',
    ABSTRACT_FROM     => 'lib/LightTCP/SSLclient.pm',
    AUTHOR            => 'Hans Harder',
    LICENSE           => 'perl_5',
    PL_FILES          => {},
    EXE_FILES         => [
        'examples/ssltest.pl',
        'examples/simple_get.pl',
        'examples/simple_post.pl',
        'examples/simple_redirect.pl',
        'examples/simple_verbose.pl',
        'examples/simple_keepalive.pl',
    ],
    PREREQ_PM         => {
        'IO::Socket::SSL' => '1.00',
        'IO::Socket::INET'=> '0',
        'MIME::Base64'    => '0',
        'URI'             => '0',
    },
    BUILD_REQUIRES    => {
        'Test::More' => '0',
    },
    META_MERGE        => {
        resources => {
            repository => 'https://github.com/HansH111/LightTCP-SSLclient.pm',
            bugtracker => 'https://github.com/HansH111/LightTCP-SSLclient.pm/issues',
        },
    },
    clean             => {
        FILES => 'examples/*.tmp t/*.tmp',
    },
);


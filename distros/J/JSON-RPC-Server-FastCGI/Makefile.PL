use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JSON::RPC::Server::FastCGI',
    AUTHOR              => 'Faiz Kazi <faiz@cpan.org>',
    VERSION_FROM        => 'lib/JSON/RPC/Server/FastCGI.pm',
    ABSTRACT_FROM       => 'lib/JSON/RPC/Server/FastCGI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                => 0,
        'JSON::RPC::Server::CGI'    => '0.92',
        'CGI::Fast'                 => 0,
        'HTTP::Request'             => 0,
        'URI'                       => 0,
        'HTML::HeadParser'          => 0,
	'FCGI'	                    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JSON-RPC-Server-FastCGI-*' },
);

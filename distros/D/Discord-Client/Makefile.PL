use strict;
use warnings;
use ExtUtils::MakeMaker;

# Declare install requirements and indexing boundaries in one distribution definition.
WriteMakefile(
    NAME => 'Discord::Client',
    VERSION_FROM => 'lib/Discord/Client.pm',
    ABSTRACT => 'Discord client for Perl using IO::Async and Future',
    AUTHOR => 'Takuya Oshima',
    LICENSE => 'apache_2_0',
    MIN_PERL_VERSION => '5.026',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'JSON::PP' => 0,
        'Digest::SHA' => 0,
        'Math::BigInt' => 0,
        'Time::HiRes' => '1.9764',
        'Future' => '0.49',
        'IO::Async' => '0.802',
        'Net::Async::HTTP' => '0.48',
        'Net::Async::WebSocket::Client' => '0.14',
        'Protocol::WebSocket' => '0.26',
        'Protocol::WebSocket::Frame' => 0,
        'IO::Async::SSL' => '0.24',
        'HTTP::Request' => 0,
        'HTTP::Response' => 0,
        'URI' => 0,
        'Crypt::PK::Ed25519' => '0.067',
    },
    TEST_REQUIRES => {
        'Test2::V1' => '1.302217',
        'CPAN::Meta' => '2.120351',
        'IO::Socket::SSL::Utils' => 0,
        'Net::Async::WebSocket::Server' => '0.14',
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
            url => 'https://metacpan.org/pod/CPAN::Meta::Spec',
        },
        dynamic_config => 0,
        no_index => {
            directory => [qw(examples)],
            package => [
                qw(
                    Discord::Client::Gateway::Session
                    Discord::Client::Gateway::IdentifyLimiter
                    Discord::Client::Gateway::IdentifyLimiter::Permit
                    Discord::Client::Gateway::WebSocket
                    Discord::Client::Gateway::WebSocket::Client
                    Discord::Client::REST::RateLimiter
                )
            ],
        },
        resources => {
            homepage => 'https://github.com/viasnake/Discord-Client',
            bugtracker => { web => 'https://github.com/viasnake/Discord-Client/issues' },
            repository => {
                type => 'git',
                url => 'https://github.com/viasnake/Discord-Client.git',
                web => 'https://github.com/viasnake/Discord-Client'
            },
        },
    },
);

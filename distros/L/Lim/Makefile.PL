use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lim',
    AUTHOR              => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM        => 'lib/Lim.pm',
    ABSTRACT_FROM       => 'lib/Lim.pm',
    EXE_FILES           => [ 'bin/lim-agentd', 'bin/lim-cli' ],
    (! eval { ExtUtils::MakeMaker->VERSION(6.3002) } ? () :
        (LICENSE => 'perl')
    ),
    (eval { ExtUtils::MakeMaker->VERSION(6.5503) } ?
    (
        BUILD_REQUIRES => {
            'Test::More' => 0,
            'common::sense' => 3,
            'AnyEvent' => 5,
            ( $^V gt v5.10 ?  ('AnyEvent::RabbitMQ' => 1.15) : ()),
            'Data::Dumper' => 2.124,
            'Digest::SHA' => 5,
            'Fcntl' => 1.06,
            'File::Temp' => 0.2,
            'Getopt::Long' => 2,
            'HTTP::Request' => 5,
            'HTTP::Response' => 5,
            'HTTP::Status' => 5,
            'IO::File' => 0,
            'IO::Handle' => 0,
            'JSON::XS' => 2,
            'Log::Dispatch::Syslog' => 1.18,
            'Log::Log4perl' => 1,
            'Log::Log4perl::Appender::Lim::CLI' => 0.12,
            'LWP::MediaTypes' => 5.822,
            'Net::SSLeay' => 1.35,
            'Module::Find' => 0,
            'Pod::Usage' => 1,
            'Scalar::Util' => 1,
            'SOAP::Lite' => 0.71,
            'SOAP::Transport::HTTP' => 0.71,
            'XMLRPC::Lite' => 0.71,
            'XMLRPC::Transport::HTTP::Server' => 0.12,
            'URI' => 1,
            'URI::Escape' => 3.29,
            'URI::Split' => 0,
            'YAML::Any' => 0.70
        },
        PREREQ_PM => {
            'common::sense' => 3,
            'AnyEvent' => 5,
            ( $^V gt v5.10 ?  ('AnyEvent::RabbitMQ' => 1.15) : ()),
            'Data::Dumper' => 2.124,
            'Digest::SHA' => 5,
            'Fcntl' => 1.06,
            'File::Temp' => 0.2,
            'Getopt::Long' => 2,
            'HTTP::Request' => 5,
            'HTTP::Response' => 5,
            'HTTP::Status' => 5,
            'IO::File' => 0,
            'IO::Handle' => 0,
            'JSON::XS' => 2,
            'Log::Dispatch::Syslog' => 1.18,
            'Log::Log4perl' => 1,
            'Log::Log4perl::Appender::Lim::CLI' => 0.12,
            'LWP::MediaTypes' => 5.822,
            'Net::SSLeay' => 1.35,
            'Module::Find' => 0,
            'Pod::Usage' => 1,
            'Scalar::Util' => 1,
            'SOAP::Lite' => 0.71,
            'SOAP::Transport::HTTP' => 0.71,
            'XMLRPC::Lite' => 0.71,
            'XMLRPC::Transport::HTTP::Server' => 0.12,
            'URI' => 1,
            'URI::Escape' => 3.29,
            'URI::Split' => 0,
            'YAML::Any' => 0.70,
            'DBI' => 1.612
        }
    ) : (
        PREREQ_PM => {
            'Test::More' => 0,
            'common::sense' => 3,
            'AnyEvent' => 5,
            ( $^V gt v5.10 ?  ('AnyEvent::RabbitMQ' => 1.15) : ()),
            'Data::Dumper' => 2.124,
            'Digest::SHA' => 5,
            'Fcntl' => 1.06,
            'File::Temp' => 0.2,
            'Getopt::Long' => 2,
            'HTTP::Request' => 5,
            'HTTP::Response' => 5,
            'HTTP::Status' => 5,
            'IO::File' => 0,
            'IO::Handle' => 0,
            'JSON::XS' => 2,
            'Log::Dispatch::Syslog' => 1.18,
            'Log::Log4perl' => 1,
            'Log::Log4perl::Appender::Lim::CLI' => 0.12,
            'LWP::MediaTypes' => 5.822,
            'Net::SSLeay' => 1.35,
            'Module::Find' => 0,
            'Pod::Usage' => 1,
            'Scalar::Util' => 1,
            'SOAP::Lite' => 0.71,
            'SOAP::Transport::HTTP' => 0.71,
            'XMLRPC::Lite' => 0.71,
            'XMLRPC::Transport::HTTP::Server' => 0.12,
            'URI' => 1,
            'URI::Escape' => 3.29,
            'URI::Split' => 0,
            'YAML::Any' => 0.70,
            'DBI' => 1.612
        }
    )),
    META_MERGE => {
        recommends => {
            'AnyEvent::ReadLine::Gnu' => 1,
            'URI::Escape::XS' => 0.11,
        }
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'https://github.com/jelu/lim/wiki',
                repository => 'https://github.com/jelu/lim',
                bugtracker => 'https://github.com/jelu/lim/issues',
            },
        })
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lim-*' },
);

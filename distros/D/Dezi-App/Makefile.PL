use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi-App';
all_from 'lib/Dezi/App.pm';

requires 'Search::Tools'                => '1.000';
requires 'File::Basename'               => 0;
requires 'Time::HiRes'                  => 0;
requires 'Path::Class'                  => '0.32';
requires 'Path::Class::File::Lockable'  => 0;
requires 'Path::Class::File::Stat'      => '0.05';
requires 'File::Rules'                  => '0.02';
requires 'SWISH::Filter'                => '0.190';
requires 'DateTime::Format::DateParse'  => 0;
requires 'Type::Tiny'                   => 0;
requires 'Types::Standard'              => 0;
requires 'Moose'                        => 0;
requires 'MooseX::Types::Path::Class'   => 0;
requires 'MooseX::Types::DateTime'      => 0;
requires 'MooseX::StrictConstructor'    => 0;
requires 'MooseX::XSAccessor'           => 0;
requires 'File::Temp'                   => 0;
requires 'Data::Dump'                   => 0;
requires 'Config::General'              => '2.31';
requires 'Scalar::Util'                 => 0;
requires 'Test::More'                   => 0;
requires 'Search::Query'                => '0.300';
requires 'Search::Query::Dialect::Lucy' => '0.200';
requires 'SWISH::3'                     => 1.000012;
requires 'Lucy'                         => 0.003002;
requires 'Class::Load'                  => 0;
requires 'HTTP::Date'                   => 0;
requires 'Sort::SQL'                    => 0;
requires 'Text::ParseWords'             => 0;
requires 'Sys::Hostname'                => 0;
requires 'MooseX::Getopt'               => 0;
requires 'namespace::autoclean'         => 0;

# SWISH::Filters::Decompress requires these, and so do our tests
requires 'Compress::Zlib'               => 0;
requires 'CAM::PDF'                     => 0;

# recommended Aggregator support

# FF should be part of base install just like Carp
recommends 'File::Find'                   => 0;
recommends 'LWP::RobotUA'                 => 0;
recommends 'HTML::Tagset'                 => 0;
recommends 'HTML::LinkExtor'              => 0;
recommends 'HTTP::Message'                => 0;
recommends 'HTTP::Cookies'                => 0;
recommends 'HTTP::Server::Simple'         => 0;
recommends 'HTTP::Server::Simple::Authen' => 0;
recommends 'Test::HTTP::Server::Simple'   => 0;
recommends 'XML::Feed'                    => 0;
recommends 'WWW::Sitemap::XML'            => 0;
recommends 'URI'                          => 0;
recommends 'YAML::Syck'                   => '0.72';
recommends 'JSON'                         => 2.0;
recommends 'Mail::Box'                    => 0;
recommends 'DBI'                          => 0;
recommends 'Term::ProgressBar'            => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'http://dezi.org/';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App';
repository 'https://github.com/karpet/dezi-app';

install_script 'bin/deziapp';
install_script 'bin/lucyx-dump-terms';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t t/*/*.t' },
    clean => {
        FILES => join(
            ' ',
            qw(
                t/dbi.index
                t/testindex
                t/index.swish
                t/spider.index
                t/mail.index
                Dezi-App-*
                )
        )
    }
);

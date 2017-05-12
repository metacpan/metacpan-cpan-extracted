use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi-Bot';
all_from 'lib/Dezi/Bot.pm';

# runtime dependencies
requires 'Test::More'           => 0;
requires 'SWISH::Prog'          => 0.68;
requires 'Module::Load'         => 0;
requires 'DBIx::Connector'      => 0;
requires 'DBIx::InsertHash'     => 0;
requires 'CHI'                  => 0;
requires 'File::Temp'           => 0;
requires 'Data::Dump'           => 0;
requires 'Time::HiRes'          => 0;
requires 'Parallel::Forker'     => 0;
requires 'Parallel::Scoreboard' => 0;
requires 'Digest::MD5'          => 0;

# test dependencies
test_requires 'DBD::SQLite'                => 0;
test_requires 'HTTP::Server::Simple'       => 0;
test_requires 'Test::HTTP::Server::Simple' => 0;

perl_version '5.8.9';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/dezi-bot';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Bot';
repository 'http://github.com/karpet/dezi-bot';

install_script 'bin/dezibot';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dezi-Bot* dezi.index' },
);


use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi-Stats';
all_from 'lib/Dezi/Stats.pm';
requires 'Test::More'                 => 0;
requires 'Search::OpenSearch::Server' => 0.15;
requires 'Dezi'                       => 0.002007;
requires 'Module::Load'               => 0;
recommends 'DBIx::Connector'          => 0;
recommends 'DBIx::InsertHash'         => 0;
recommends 'Log::Dispatchouli'        => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/dezi-stats';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Stats';
repository 'http://github.com/karpet/dezi-stats';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dezi-Stats* dezi.index' },
);

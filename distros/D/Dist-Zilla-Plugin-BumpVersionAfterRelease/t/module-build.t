use strict;
use warnings;
use Test::More 0.96;
use utf8;

use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Version::Next qw/next_version/;

my @plugins = (
    [ GatherDir => { exclude_filename => ['Build.PL'] } ],
    'FakeRelease',
    'ModuleBuild',
    'MetaConfig',
    'RewriteVersion',
    'BumpVersionAfterRelease',
);
my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
        add_files => { 'source/dist.ini' => simple_ini( { version => undef }, @plugins ), },
    },
);

my $version = 42;
{
    local $ENV{V} = $version;
    $tzil->release;
}

my $buildPL = $tzil->slurp_file('source/Build.PL');

like(
     $buildPL,
    _regex_for_buildPL( next_version($version) ),
    "Build.PL version bumped"
);

sub _regex_for_buildPL {
    my ($version) = @_;
    return qr{"dist_version" => "\Q$version\E"}m;
}

done_testing;

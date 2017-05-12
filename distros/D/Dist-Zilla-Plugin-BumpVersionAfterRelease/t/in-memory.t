use strict;
use warnings;
use Test::More 0.96;

use Test::DZil;
use Test::Fatal;
use Path::Tiny;

sub _new_tzil {
    {
        package inc::MyGatherer;
        use Moose;
        with 'Dist::Zilla::Role::FileGatherer';
        use Dist::Zilla::File::InMemory;
        sub gather_files
        {
            shift->add_file(Dist::Zilla::File::InMemory->new(
                name => Path::Tiny::path(qw(lib Bar.pm))->stringify,
                content => 'in memory',
            ));
        }
    }
    return Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    { version => 3.1415 },
                    'GatherDir',
                    '=inc::MyGatherer',
                    [ 'RewriteVersion', { skip_version_provider => 1 } ],
                    'FakeRelease',
                    'BumpVersionAfterRelease',
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n\nour \$VERSION = '0.002';\n\n1;\n",
            },
        },
    );
}

# Just to make sure nothing leaks through when doing
# V=0.01 dzil test
delete $ENV{TRIAL};
delete $ENV{V};
delete $ENV{RELEASE_STATUS};

my $tzil = _new_tzil;
$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->release },
    undef,
    'build and release proceeds normally',
);

is(
    path($tzil->tempdir, qw(source lib Foo.pm))->slurp_utf8,
    "package Foo;\n\nour \$VERSION = '3.1416';\n\n1;\n",
    '.pm contents in source saw the version updated',
);

ok(
    grep { $_ eq '[BumpVersionAfterRelease] Skipping: "lib/Bar.pm" not found in source' }
        @{ $tzil->log_messages },
    'got appropriate log messages about skipping in-memory file',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

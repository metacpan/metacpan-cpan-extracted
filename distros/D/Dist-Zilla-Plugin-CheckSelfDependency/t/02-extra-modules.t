use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    'CheckSelfDependency',
                    [ 'Prereqs / RuntimeRequires' => { 'Foo::Bar' => '1.23' } ],
                ),
                path(qw(source lib Foo Bar.pm)) => "package Foo::Bar::Baz;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build is not aborted - prereq not actually provided by dist',
    );

    ok(!exists $tzil->distmeta->{provides}, 'provides field was not autovivified in distmeta');

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    'CheckSelfDependency',
                    [ 'Prereqs / RuntimeRequires' => { 'Foo::Bar::Baz' => '1.23' } ],
                ),
                path(qw(source lib Foo Bar.pm)) => "package Foo::Bar::Baz;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr{Foo::Bar::Baz is listed as a prereq, but is also provided by this dist \(lib/Foo/Bar.pm\)!},
        'build is aborted',
    );

    ok(!exists $tzil->distmeta->{provides}, 'provides field was not autovivified in distmeta');

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;

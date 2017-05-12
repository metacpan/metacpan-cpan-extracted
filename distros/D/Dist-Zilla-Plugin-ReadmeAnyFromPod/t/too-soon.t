#!perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::DZil;
use Path::Tiny;
use Test::Fatal;
use Test::Deep;

use Test::Requires 'Dist::Zilla::Plugin::PodWeaver';

my @module = (
                path(qw(source lib Foo.pm)) => <<'MODULE'
package Foo;
# ABSTRACT: stuff
=pod

=head1 SYNOPSIS

This is the module synopsis.

=cut
1;
MODULE
);

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [ ReadmeAnyFromPod => { location => 'build', type => 'pod', filename => 'README.md' } ],
                    'PodWeaver',
                ),
                @module,
            },
        },
    );

    is(
        exception { $tzil->build },
        undef,
        'build still proceeds',
    );

    cmp_deeply(
        $tzil->log_messages,
        supersetof('[ReadmeAnyFromPod] someone tried to munge lib/Foo.pm after we read from it. Making modifications again...'),
        '...but includes a useful warning about plugin ordering',
    );

    my $build_dir = path($tzil->tempdir)->child('build');

    my $dist_file = path($build_dir, "README.md");
    ok(-e $dist_file, "README.md created in dist");

    my $content = $dist_file->slurp_utf8;
    like($content, qr/=head1 NAME/, 'contains headers added by PodWeaver');

    my $pm_content = path($build_dir, 'lib/Foo.pm')->slurp_utf8;

    like($pm_content, qr/=head1 NAME/, 'PodWeaver added a NAME header to document');
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    # identical to above, except PodWeaver is loaded first
                    'PodWeaver',
                    [ ReadmeAnyFromPod => { location => 'build', type => 'pod', filename => 'README.md' } ],
                ),
                @module,
            },
        },
    );

    is(
        exception { $tzil->build },
        undef,
        'build completes successfully',
    );

    my $build_dir = path($tzil->tempdir)->child('build');

    my $dist_file = path($build_dir, "README.md");
    ok(-e $dist_file, "README.md created in dist");

    my $content = $dist_file->slurp_utf8;
    like($content, qr/=head1 NAME/, 'contains headers added by PodWeaver');

    my $pm_content = path($build_dir, 'lib/Foo.pm')->slurp_utf8;

    like($pm_content, qr/=head1 NAME/, 'PodWeaver added a NAME header to document');
}

done_testing;

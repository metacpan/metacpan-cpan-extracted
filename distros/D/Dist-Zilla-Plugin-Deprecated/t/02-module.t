use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;
use CPAN::Meta::Validator;

# newer CPAN::Meta::Merge, or older Dist::Zilla (which used
# Hash::Merge::Simple instead), is required for the 'modules' feature, due to
# how CPAN::Meta::Merge handled 'provides' data before 2.150002

# a plain "use if eval ..." behaves badly, because eval returns an empty list
# in list context on a die.
use if !!eval { require Dist::Zilla; Dist::Zilla->VERSION('5.022') },
    'Test::Needs' => { 'CPAN::Meta::Merge' => '2.150002' };

use lib 't/lib';

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ '=SimpleProvides' ],
                    [ MetaConfig => ],
                    [ 'Deprecated' => { module => [ 'Foo::Bar', 'Foo::Baz' ] } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source lib Foo Bar.pm)) => "package Foo::Bar;\n1;\n",
                path(qw(source lib Foo Baz.pm)) => "package Foo::Baz;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    my $cmv = CPAN::Meta::Validator->new($tzil->distmeta);
    ok($cmv->is_valid, 'metadata validates')
        or do { diag 'validation error: ', $_ foreach $cmv->errors };

    cmp_deeply(
        $tzil->distmeta,
        all(
            # TODO: replace with Test::Deep::notexists($key)
            code(sub {
                !exists $_[0]->{x_deprecated} ? 1 : (0, 'x_deprecated exists');
            }),
            superhashof({
                provides => {
                    'Foo' => {
                        file => 'lib/Foo.pm',
                        version => '0.001',
                    },
                    'Foo::Bar' => {
                        file => 'lib/Foo/Bar.pm',
                        version => '0.001',
                        x_deprecated => 1,
                    },
                    'Foo::Baz' => {
                        file => 'lib/Foo/Baz.pm',
                        version => '0.001',
                        x_deprecated => 1,
                    },
                },
                x_Dist_Zilla => superhashof({
                    plugins => supersetof({
                        class => 'Dist::Zilla::Plugin::Deprecated',
                        config => {
                            'Dist::Zilla::Plugin::Deprecated' => {
                                all => 0,
                                modules => [ 'Foo::Bar', 'Foo::Baz' ],
                            },
                        },
                        name => 'Deprecated',
                        version => Dist::Zilla::Plugin::Deprecated->VERSION,
                    }),
                }),
            }),
        ),
        'plugin metadata, including dumped configs',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'Deprecated' => { module => 'Foo::Bar' } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source lib Foo Bar.pm)) => "package Foo::Bar;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    my $cmv = CPAN::Meta::Validator->new($tzil->distmeta);
    ok(!$cmv->is_valid, 'metadata does not validate - incomplete provides data');
    note 'validation error: ', $_ foreach $cmv->errors;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            provides => {
                'Foo::Bar' => {
                    x_deprecated => 1,
                },
            },
        }),
        'plugin metadata (broken - [MetaJSON] will never write this out)',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;

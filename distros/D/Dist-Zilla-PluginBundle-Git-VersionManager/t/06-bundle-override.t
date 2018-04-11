use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 1.33 'first';

use lib 't/lib';
use Helper;

{
    package Dist::Zilla::PluginBundle::MyBundle;
    use Moose;
    with
        'Dist::Zilla::Role::PluginBundle::Easy',
        'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
        'Dist::Zilla::Role::PluginBundle::Config::Slicer';

    sub configure
    {
        my $self = shift;

        # this is the default config, but dist.ini should still be able to override it
        $self->add_bundle('@Git::VersionManager' => {
            # we recommend you use this module and config..
            'RewriteVersion::Transitional.fallback_version_provider' => 'Default::Module',
            'RewriteVersion::Transitional.version_regexp' => '^v([\d._]+)(-TRIAL)?$',

            # but in in case the caller prefers Foo::Bar, this is a recommended config
            'Foo::Bar.version_regexp' => '^a silly regexp',

            # and then pass along everything the caller sent, overriding everything else
            %{ $self->payload },
        });
    }
}

delete $ENV{V};

my $tempdir = no_git_tempdir();

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        tempdir_root => $tempdir->stringify,
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                { # configs as in simple_ini, but no version assignment
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                'GatherDir',
                [ '@MyBundle' => {
                        # modify some configs - we expect these to take precedence
                        'RewriteVersion::Transitional.fallback_version_provider' => 'Foo::Bar',
                        # even though MyBundle provided a default for
                        # Foo::Bar, we want to use this one instead.
                        'Foo::Bar.version_regexp' => '^ohhai',
                    } ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\nour \$VERSION = '0.002';\n1",
            path(qw(source Changes)) => '',
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

is($tzil->version, '0.002', 'version properly extracted from main module');

# we need the configs that we passed through in dist.ini to override
# those set in the payload in the wrapping bundle
cmp_deeply(
    (first { $_->isa('Dist::Zilla::Plugin::RewriteVersion::Transitional') } @{ $tzil->plugins }),
    methods(
        fallback_version_provider => 'Foo::Bar',
        _fallback_version_provider_args => {
            version_regexp => '^ohhai'
        },
    ),
    'marshalled all RewriteVersion::Transitional arguments',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

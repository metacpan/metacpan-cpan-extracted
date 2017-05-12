use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

# Instead of using [ModuleBuildTiny] to set x_static_install, we set the
# x_static_install flag directly using a simple plugin.

use lib 't/lib';

my @tests = (
    {
        x_static_install => 0,
        mode => 'auto',         # and we return x_static_install => 1
    },
    {
        x_static_install => 1,
        mode => 'auto',         # and we return x_static_install => 0
    },
);

subtest "preset x_static_install input of $_->{x_static_install}, our $_->{mode} mode returns " . ($_->{x_static_install} ? 0 : 1) => sub
{
    my $config = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    # the lack of META.json will disqualify us in our plugin
                    $config->{x_static_install} ? () : [ MetaJSON => ],
                    [ '=SimpleFlagSetter' => { value => $config->{x_static_install} } ],
                    [ 'MakeMaker' ],
                    [ 'StaticInstall' => { mode => $config->{mode} } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        ($config->{x_static_install}
            ? qr/\[StaticInstall\] x_static_install was set but this distribution is ineligible: META.json is not being added to the distribution/
            : qr/\[StaticInstall\] something set x_static_install = 0 but we want to set it to 1/),
        'build fails in setup_installer when the results conflict',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;

use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Term::ANSIColor 2.01 'colorstrip';

{
    # plugin sets x_static_install = 0 in MetaProvider,
    # do not blow up!
    package Dist::Zilla::Plugin::ThisIsOkay;
    use Moose;
    with 'Dist::Zilla::Role::MetaProvider',
        'Dist::Zilla::Role::InstallTool';

    sub metadata
    {
        my $self = shift;
        +{ x_static_install => 0 }
    }
    sub setup_installer
    {
        my $self = shift;
        $self->zilla->distmeta->{x_static_install} = 1;
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ ThisIsOkay => ],
                [ VerifyPhases => ],
            ),
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

cmp_deeply(
    [
        grep { ! /^\[VerifyPhases\] ---- this is the last .* plugin ----$/ }
        grep { /\[VerifyPhases\]/ }
        map { colorstrip($_) } @{ $tzil->log_messages }
    ],
    [],
    'no warnings from the plugin despite this meta field being modified after the normal phase',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

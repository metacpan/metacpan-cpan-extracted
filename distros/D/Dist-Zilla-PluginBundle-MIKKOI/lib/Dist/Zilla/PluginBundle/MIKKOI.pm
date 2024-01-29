package Dist::Zilla::PluginBundle::MIKKOI;
use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

# ABSTRACT: BeLike::MIKKOI when you build your dists

use Moose;
with
    'Dist::Zilla::Role::PluginBundle::Easy'
    ;

sub configure {
    my $self = shift;
    my $target_perl = '5.014';

    $self->add_bundle('@Filter', {
            '-bundle' => '@Basic',
            '-remove' => [ 'License', 'ExtraTests', ],
            '-version' => '5.031',
        });
    $self->add_plugins([ 'OurPkgVersion', ]);
    $self->add_plugins([ 'Git::NextVersion', ]);

    # NextRelease must be before [@Git](Git::Commit)
    $self->add_plugins([ 'NextRelease', ]);
    $self->add_bundle('@Git');

    $self->add_plugins(
            'MetaJSON',
            'PodWeaver',
            'PerlTidy',
            'PruneFiles',
            'MinimumPerl',
            'AutoPrereqs',
            [ 'CPANFile' => {
                'filename' => 'dzil-generated-cpanfile',
            }],
            'Test::PodSpelling',
            'Test::CheckManifest',
            'MetaTests',
            'PodSyntaxTests',
            'PodCoverageTests',
            'Test::Portability',
            'Test::Version',
            'Test::Kwalitee',
            'Test::CPAN::Changes',
            ['Test::Perl::Critic' => {
                'critic_config' => '.perlcriticrc',
            }],
            ['Test::EOL' => {
                'trailing_whitespace' => 1,
            }],
            'Test::UnusedVars',
            'Test::Synopsis',
            'Test::Pod::LinkCheck',
            'RunExtraTests',
            'Test::CPAN::Meta::JSON',
            ['Test::MinimumVersion' => {
                    'max_target_perl' => $target_perl,
            }],
            'CheckExtraTests',
            'MojibakeTests',
            'Test::NoTabs',
        );
}

1;

package Dist::Zilla::PluginBundle::MIKKOI;
use strict;
use warnings;

our $VERSION = '0.003';

# ABSTRACT: BeLike::MIKKOI when you build your dists

use Moose;
with
    'Dist::Zilla::Role::PluginBundle::Easy'
    ;

sub configure {
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    my $self = shift;
    my $target_perl = '5.014';

    $self->add_bundle('@Filter', {
            '-bundle' => '@Basic',
            '-remove' => [ 'License', 'ExtraTests', ],
            '-version' => '6.030',
        });
    # $self->add_plugins([ 'Git::NextVersion', ]);
    $self->add_plugins([ 'RewriteVersion', {
            'allow_decimal_underscore' => 1,
        }]);

    # NextRelease must be before [@Git](Git::Commit)
    $self->add_plugins([ 'NextRelease', ]);
    $self->add_bundle('@Git');
    $self->add_plugins([ 'BumpVersionAfterRelease', ]);

    $self->add_plugins(
            'MetaJSON',
            'PodWeaver',
            'PerlTidy',
            'PruneFiles',
            'MinimumPerl',
            'AutoPrereqs',
            ['Test::PodSpelling' => {
                    'directories' => ['lib', 'bin', 'script', ],
                    'stopword' => [ 'env', 'dotenv', 'envdot', ],
            }],
            # 'Test::CheckManifest',
            'Test::DistManifest', # By Karen Etheridge
            'MetaTests',
            'PodSyntaxTests',
            'PodCoverageTests',
            'Test::Portability',
            'Test::Version',
            'Test::Kwalitee',
            'Test::CPAN::Changes',
            ['Test::Perl::Critic' => {
                'embed_critic_config' => 1,
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
            # 'CheckExtraTests', We already run RunExtraTests
            'MojibakeTests',
            'Test::NoTabs',
            'Signature',
            'AuthorSignatureTest',
            ['Test::Software::Policies' => {
                    'include_policy' => [
                        'Contributing',
                        'CodeOfConduct',
                        'License',
                        'Security',
                    ],
            }],
        );
    return;
}
1;

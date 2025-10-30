package Dist::Zilla::PluginBundle::Author::REFECO;
# ABSTRACT: REFECO dist defaults

use strict;
use warnings;

our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.007';          # VERSION

use Moose;
use Dist::Zilla 6.030;

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {

    my $self = shift;

    my @copy = qw(Makefile.PL LICENSE cpanfile);

    $self->add_bundle(
        'Filter' => {
            '-bundle' => '@Basic',
            '-remove' => ['GatherDir', 'PruneCruft']});

    $self->add_plugins(    #
        [
            'GatherDir' => {
                exclude_filename => [@copy],
                include_dotfiles => 1
            }
        ],
        ['PruneCruft'         => {except => [qw(.perlcriticrc .perltidyrc)]}],
        ['CopyFilesFromBuild' => {copy   => [@copy]}],
        'OurPkgVersion',
        'Test::Version',
        [
            'Authority' => {
                authority      => 'cpan:REFECO',
                locate_comment => 1
            }
        ],
        'PodWeaver',
        ['PerlTidy' => {perltidyrc => '.perltidyrc'}],
        [
            'ReadmeAnyFromPod' => 'Git' => {
                filename => 'README.md',
                location => 'root',
                type     => 'gfm',
                phase    => 'build'
            }
        ],
        'NextRelease',
        'MetaJSON',
        [
            'GithubMeta' => {
                issues => 1,
            }
        ],
        'MetaProvides::Package',
        'CPANFile',
        'Test::Compile',
        'Test::CheckDeps',
        ['Test::Perl::Critic' => {critic_config => '.perlcriticrc'}],
        'PodSyntaxTests',
        'MetaTests',
        'TestRelease',
        'ConfirmRelease',
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::REFECO - REFECO dist defaults

=head1 VERSION

version 0.007

=head1 OVERVIEW

This is the default Dist::Zilla release configuration for REFECO

Reproducible by the following dist.ini config:

    [@Filter]
    -bundle = @Basic
    -remove = GatherDir
    -remove = PruneCruft

    [GatherDir]
    exclude_filename = Makefile.PL
    exclude_filename = LICENSE
    exclude_filename = cpanfile
    include_dotfiles = 1

    [PruneCruft]
    except = .perlcriticrc
    except = .perltidyrc

    [CopyFilesFromBuild]
    copy = Makefile.PL
    copy = LICENSE
    copy = cpanfile

    [OurPkgVersion]
    [Test::Version]

    [Authority]
    authority = cpan:REFECO
    locate_comment = 1

    [PodWeaver]
    [PerlTidy]
    perltidyrc = .perltidyrc

    [ReadmeAnyFromPod]
    type = gfm
    filename = README.md
    location = root
    phase = build

    [NextRelease]
    [CPANFile]
    [MetaJSON]

    [GithubMeta]
    issues = 1

    [MetaProvides::Package]
    [Test::Compile]
    [Test::CheckDeps]

    [Test::Perl::Critic]
    critic_config = .perlcriticrc

    [PodSyntaxTests]
    [MetaTests]

    [TestRelease]
    [ConfirmRelease]

=head1 AUTHOR

Reginaldo Costa <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut

package Dist::Zilla::PluginBundle::JAITKEN;

# ABSTRACT: Build your distributions like JAITKEN

=head1 NAME

Dist::Zilla::PluginBundle::JAITKEN - Build your Dist::Zilla distributions like JAITKEN

=head1 SYNOPSIS

This is the L<Dist::Zilla> configuration that I use.

It is exactly equivalent to

    [VersionFromModule]
    [NameFromDirectory]

    [AutoPrereqs]

    [MinimumPerl]

    [MetaJSON]

    [ReadmeAnyFromPod]
    type = markdown
    filename = README
    location = build

    [PruneFiles]
    filenames = dist.ini
    filenames = README.markdown

    [GithubMeta]
    issues = 1

    [MinimumPrereqs]
    minimum_year = 2007

    [PrereqsClean]
    minimum_perl = v5.10

    [@Filter]
    -bundle = @Basic
    -remove = Readme


=head1 USAGE

In dist.ini

    [@JAITKEN]

And that's it.

The module needs to be under version control at GitHub
in order for L<Dist::Zilla::Plugin::GithubMeta> to extract relevant
info from your local git repo.

=cut

use strict;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

our $VERSION = '0.1.6';

sub configure {
    my $self = shift;

    $self->add_plugins(
        ['AutoPrereqs'],
        ['MetaJSON'],
        ['MinimumPerl'],
        ['VersionFromModule'],
        ['NameFromDirectory'],
        [
            ReadmeAnyFromPod => {
                type     => 'markdown',
                filename => 'README',
                location => 'build',
            }
        ], [
            PruneFiles => {
                filenames => ['dist.ini', 'README.markdown']
            }
        ], [
            GithubMeta => {
                issues => 1,
            }
        ], [
            MinimumPrereqs => {
                minimum_year => 2007,
            }
        ], [
            PrereqsClean => {
                minimum_perl => 'v5.10',
            }
        ],
    );

    $self->add_bundle('@Filter', {
      '-bundle' => '@Basic',
      '-remove' => ['Readme'],
    });
}

1;

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::Role::PluginBundle::Easy>,
L<Dist::Zilla::Plugin::AutoPrereqs>, L<Dist::Zilla::Plugin::GithubMeta>,
L<Dist::Zilla::Plugin::MetaJSON>, L<Dist::Zilla::Plugin::MinimumPerl>,
L<Dist::Zilla::Plugin::MinimumPrereqs>, L<Dist::Zilla::Plugin::PrereqsClean>,
L<Dist::Zilla::Plugin::PruneFiles>, L<Dist::Zilla::Plugin::ReadmeAnyFromPod>,
L<Dist::Zilla::Plugin::VersionFromModule>, L<Dist::Zilla::Plugin::NameFromDirectory>,
L<Dist::Zilla::PluginBundle::Basic>, L<Dist::Zilla::PluginBundle::Filter>


=head1 AUTHOR

James Aitken <jaitken@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

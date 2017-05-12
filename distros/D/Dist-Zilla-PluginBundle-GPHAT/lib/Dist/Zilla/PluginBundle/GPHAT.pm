package Dist::Zilla::PluginBundle::GPHAT;
$Dist::Zilla::PluginBundle::GPHAT::VERSION = '0.06';
use Moose;

with 'Dist::Zilla::Role::PluginBundle::Easy';

# ABSTRACT: Dist::Zilla plugins for gphat


sub configure {
    my ($self) = @_;

    $self->add_bundle('@Basic');

    $self->add_plugins([
        'Git::NextVersion' => {
            first_version  => '0.01',
            version_regexp => '^(\d+\.\d+)$'
        }
    ]);

    $self->add_plugins(qw(
        ReadmeMarkdownFromPod
        PkgVersion
        AutoPrereqs
    ));

    $self->add_plugins([
        'NextRelease' => {
            format => '%v %{MMM d yyyy}d'
        }
    ]);

    $self->add_plugins(qw(
        SynopsisTests
        PodSyntaxTests
        MetaJSON
    ));

    $self->add_plugins([
        'GithubMeta' => {
            issues => 1
        }
    ]);

    $self->add_plugins([
        'CopyFilesFromBuild' => {
            copy => 'README.mkdn'
        }
    ]);
    
    $self->add_plugins([
        'PruneFiles' => {
            filenames => [ qw(dist.ini weaver.ini) ]
        }
    ]);

    $self->add_plugins(qw(Git::Commit));

    $self->add_plugins([
        'Git::Tag' => {
            tag_format => '%v'
        }
    ]);

    $self->add_plugins(qw(PodWeaver));
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::GPHAT - Dist::Zilla plugins for gphat

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This is the plugin bundle that GPHAT uses.  It's equivalent to:

    [@Basic]

    [Git::NextVersion]
    first_version   = 0.01
    version_regexp  = ^(\d+\.\d+)$

    [ReadmeMarkdownFromPod]

    [PkgVersion]

    [AutoPrereqs]

    [NextRelease]
    format          = %v %{MMM d yyyy}d

    [Test::Synopsis]

    [PodSyntaxTests]

    [MetaJSON]

    [GithubMeta]
    issues = 1

    [CopyFilesFromBuild]
    copy            = README.mkdn

    [PruneFiles]
    filenames       = dist.ini

    [Git::Commit]

    [Git::Tag]
    tag_format      = %v

    [PodWeaver]

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strictures 2;

package Dist::Zilla::PluginBundle::ZURBORG;

# ABSTRACT: dzil plugin bundle of ZURBORG

use Moose;

our $VERSION = '0.007'; # VERSION

with 'Dist::Zilla::Role::PluginBundle::Easy';


sub configure {
    my $self = shift;

    my @plugins = (
        'Git::GatherDir' => {},
        'PruneCruft' => {},
        'PruneFiles' => {
            filename => 'dist.ini',
        },
        'MinimumPerl' => {},
        'AutoPrereqs' => {},
        'PreviousVersion::Changelog' => {},
        'NextVersion::Semantic' => {
            format => '%d.%03d',
        },
        'PodWeaver' => {
            config_plugin => '@ZURBORG',
        },
        'OurPkgVersion' => {},
        'NextRelease' => {
            format => '%v %{yyyy-MM-dd}d',
        },
        'GithubMeta' => {
            issues => '1',
        },
        'Git::Check' => {
            allow_dirty => '.travis.yml',
        },
        'Git::Commit' => {},
        'Git::Tag' => {
            tag_message => 'Released version %v',
            signed => 1,
        },
        'Git::Contributors' => {},
        'ContributorsFile' => {},
        'ManifestSkip' => {},
        'MetaYAML' => {},
        'License' => {},
        'Readme' => {},
        'CPANFile' => {},
        'ExtraTests' => {},
        'PodSyntaxTests' => {},
        'PodCoverageTests' => {},
        'Test::CPAN::Changes' => {},
        'Test::Perl::Critic' => {},
        'Test::Kwalitee::Extra' => {
            arg => '!prereq_matches_use',
        },
        'ExecDir' => {},
        'ShareDir' => {},
        'Signature' => {},
        'ModuleBuild' => {},
        'Manifest' => {},
        'TestRelease' => {},
        'ConfirmRelease' => {},
        'UploadToCPAN' => {},
        'Git::Push' => {},
        'GitHub::UploadRelease' => {},
    );

    for (0 .. $#plugins/2) {
        push @plugins => [ splice @plugins, 0, 2 ];
    }
    $self->add_plugins(@plugins);
    return;
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::ZURBORG - dzil plugin bundle of ZURBORG

=head1 VERSION

version 0.007

=head1 METHODS

=head2 configure

Configuration of Dist::Zilla::PluginBundle::Easy

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/zurborg/libdist-zilla-pluginbundle-zurborg-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg <zurborg@cpan.org>.

This is free software, licensed under:

  The ISC License

=cut

package Dist::Zilla::PluginBundle::Author::BLUEFEET;
$Dist::Zilla::PluginBundle::Author::BLUEFEET::VERSION = '0.02';
use Moose;
use strictures 2;
use namespace::clean;

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
    my ($self) = @_;

    $self->add_bundle('Basic');

    $self->add_plugins(
        # Before a release, check that the repo is in a clean state (you have committed your changes).
        'Git::Check',

        # Automatically determine the next version by looking at git tags.
        ['Git::NextVersion' => {
            first_version => '0.01',
        }],

        # During build update the Changes file with the new version, and after release update the
        # Changes file in the root with the version and move the {{$NEXT}} marker.
        ['NextRelease' => {
            format => '%v %{yyyy-MM-dd}d',
        }],

        # Update the README.pod in the root directory.
        ['ReadmeAnyFromPod' => 'ReadmePodInRoot' => {
            type => 'pod',
        }],

        # Extract the bugtracker, homepage, and repository URLs from GitHub,
        ['GithubMeta' => {
            issues => 1,
        }],

        # During build munge the .pms to include the distribution version.
        'PkgVersion',

        # Run various tests.
        'PodSyntaxTests',
        'Test::ReportPrereqs',

        # Read CPAN prerequisites from the root cpanfile.
        'Prereqs::FromCPANfile',

        # After a release, commit updated files.
        'Git::Commit',

        # After a release, tag the just-released version.
        'Git::Tag',

        # After a release, push the released code & tag to your public repo.
        'Git::Push',
    );
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Dist::Zilla::PluginBundle::Author::BLUEFEET - The Dist::Zilla
plugins which Aran Deltac uses for his CPAN distributions.

=head1 SYNOPSIS

    [@Author::BLUEFEET]

=head1 DESCRIPTION

Using this L<Dist::Zilla> plugin bundle is equivalent to:

    [@Basic]
   
    [Git::Check]

    [Git::NextVersion]
    first_version = 0.01
    
    [NextRelease]
    format = %v %{yyyy-MM-dd}d
    
    [ReadmeAnyFromPod / ReadmePodInRoot]
    type = pod
    
    [GithubMeta]
    issues = 1
    
    [PkgVersion]
    [PodSyntaxTests]
    [Test::ReportPrereqs]
    [Prereqs::FromCPANfile]
    
    [Git::Commit]
    [Git::Tag]
    [Git::Push]

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


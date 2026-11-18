package Dist::Zilla::Plugin::Author::GETTY::GitHubRelease;
# ABSTRACT: Create a GitHub release as draft, attach the tarball, then publish it
use Moose;
extends 'Dist::Zilla::Plugin::GitHub::CreateRelease';

use Config::Identity;
use Pithub::Repos::Releases;

our $VERSION = '0.328';


has make_latest => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    my ($self) = @_;
    return (grep { $_->isa('Dist::Zilla::Plugin::Author::GETTY::Binary') } @{ $self->zilla->plugins }) ? 0 : 1;
  },
);

sub _create_release {
  my ($self, $tag, $branch, $title, $notes, $filename, $cpan_tar) = @_;

  my @fields = ("login", "token");
  my %identity = Config::Identity->load_check($self->{org_id}, \@fields);

  my $org = $self->{org_id} ? $self->{org_id} : "github";
  die "Unable to load github token from ~/.$org-identity or ~/.$org" if (! defined $identity{token});

  my $releases = Pithub::Repos::Releases->new(
    user  => $self->{repo_owner} || $self->_get_repo_owner() || $identity{login} || $self->{username},
    repo  => $self->{repo} || $self->_get_repo_name(),
    token => $identity{token},
  );
  die "Unable to instantiate Pithub::Repos::Releases" if (! defined $releases);

  my $release = $releases->create(
    data => {
      tag_name         => "$tag",
      target_commitish => $branch,
      name             => $title,
      body             => $notes,
      draft            => \1,
      prerelease       => $self->zilla->is_trial ? \1 : \0,
      generate_release_notes => $self->{github_notes} ? \1 : \0,
    }
  );
  die "Discussion category name is invalid" if ($release->code eq '404');
  die "Validation failed, or the endpoint has been spammed." if ($release->code eq '422');
  die "login ($identity{login}) or token invalid for the specified repository ($releases->{repo})\n"
      if ($release->code eq '403');

  my $release_id = $release->content->{id};
  die "Unable to create GitHub release\n" unless defined $release_id;
  $self->log("Draft release created at $releases->{repo} for $identity{login}");

  my $asset = $releases->assets->create(
    release_id   => $release_id,
    name         => $filename,
    data         => $cpan_tar,
    content_type => 'application/gzip',
  );
  die "could not attach $filename to the GitHub release $tag (HTTP " . $asset->code
    . "); draft release left in place for inspection\n"
    unless $asset->code eq '201';
  $self->log("CPAN archive appended to GitHub release: $tag");

  my $published = $releases->update(
    release_id => $release_id,
    data       => {
      draft       => \0,
      make_latest => $self->make_latest ? 'true' : 'false',
    },
  );
  die "could not publish the GitHub release $tag (HTTP " . $published->code . ")\n"
    unless $published->code eq '200';
  $self->log("GitHub release published: $tag");

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::GETTY::GitHubRelease - Create a GitHub release as draft, attach the tarball, then publish it

=head1 VERSION

version 0.328

=head1 DESCRIPTION

A subclass of L<Dist::Zilla::Plugin::GitHub::CreateRelease> that creates the
release as a draft, uploads the CPAN tarball to it and only then publishes it.
A failed upload dies loudly and leaves the draft in place for inspection,
instead of publishing a release that lacks its tarball. The release is
published with C<make_latest> true, or false when the distribution declares
binaries (a L<Dist::Zilla::Plugin::Author::GETTY::Binary> plugin is present):
the binary workflow marks it afterwards, see the C<Binaries> section of
L<Dist::Zilla::PluginBundle::Author::GETTY>. Added by that bundle in place of
L<Dist::Zilla::Plugin::GitHub::CreateRelease> unless C<no_github> or
C<no_github_release> is set.

=head1 ATTRIBUTES

=head2 make_latest

Whether the published release is marked as the latest one. Default: true, false
when the distribution declares binaries.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

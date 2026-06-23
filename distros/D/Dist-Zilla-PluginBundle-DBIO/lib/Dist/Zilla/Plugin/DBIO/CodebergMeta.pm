package Dist::Zilla::Plugin::DBIO::CodebergMeta;
# ABSTRACT: Add Codeberg (or any git forge) repository metadata to META.{json,yml}
use Moose;
with 'Dist::Zilla::Role::MetaProvider';



has remote => (
  is      => 'ro',
  isa     => 'Str',
  default => 'origin',
);


has host => (
  is      => 'ro',
  isa     => 'Str',
  default => 'codeberg.org',
);


has repo => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);


has issues => (
  is      => 'ro',
  isa     => 'Bool',
  default => 1,
);


has homepage => (
  is      => 'ro',
  isa     => 'Str',
  default => 'repo',
);

has _remote_info => (
  is      => 'ro',
  isa     => 'Maybe[HashRef]',
  lazy    => 1,
  builder => '_build_remote_info',
);

sub _build_remote_info {
  my ($self) = @_;
  my $remote = $self->remote;
  chomp(my $url = `git config --get remote.$remote.url 2>/dev/null` // '');
  return undef unless length $url;
  return $self->_parse_remote_url($url);
}

# Parse a git remote URL into { host => ..., slug => 'owner/repo' }, or undef.
# Pure helper (no git), kept separate so the regex can be unit-tested.
sub _parse_remote_url {
  my ($self, $url) = @_;
  # git@host:owner/repo.git | https://host/owner/repo(.git) | ssh://git@host/owner/repo.git
  my ($host, $slug) = $url =~ m{
    (?: ^ \w+ :// (?: [^/\@]+ \@ )? | ^ [^/\@]+ \@ )   # scheme[//user@] or user@
    ( [^/:]+ )                                         # host
    [:/]+
    ( .+? )                                            # owner/repo...
    (?: \.git )? /? $
  }x;
  return undef unless $host && $slug;
  return { host => $host, slug => $slug };
}

# Resolve the owner/repo slug for $self->host. An explicit repo= override is
# trusted; otherwise the git remote must point at the expected host. Returns
# undef (no usable target) if there is no remote or it points elsewhere.
sub _slug {
  my ($self) = @_;
  return $self->repo if defined $self->repo && length $self->repo;

  my $info = $self->_remote_info or return undef;
  return undef unless $info->{host} eq $self->host;
  return $info->{slug};
}

sub metadata {
  my ($self) = @_;

  my $slug = $self->_slug;
  unless (defined $slug) {
    $self->log_debug('no meta target found -- skipping repository metadata');
    return {};
  }

  return {
    resources => $self->_build_resources(
      host      => $self->host,
      slug      => $slug,
      issues    => $self->issues,
      homepage  => $self->homepage,
      dist_name => $self->zilla->name,
    ),
  };
}

# Pure assembly of the resources hashref. Kept free of zilla/git so it can be
# unit-tested as a class method.
sub _build_resources {
  my ($self, %a) = @_;
  my $web = "https://$a{host}/$a{slug}";

  my %resources = (
    repository => {
      type => 'git',
      url  => "$web.git",
      web  => $web,
    },
  );

  $resources{bugtracker} = { web => "$web/issues" } if $a{issues};

  if ($a{homepage} eq 'repo') {
    $resources{homepage} = $web;
  }
  elsif ($a{homepage} eq 'metacpan') {
    $resources{homepage} = "https://metacpan.org/release/$a{dist_name}";
  }
  # 'none' -> leave homepage unset

  return \%resources;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::CodebergMeta - Add Codeberg (or any git forge) repository metadata to META.{json,yml}

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

Derives the C<repository>, C<bugtracker>, and C<homepage> META resources from
the distribution's git remote URL. Works fully offline: no API token and no
network access, unlike the external L<Dist::Zilla::Plugin::Codeberg::Meta>
(which additionally targets the GitLab API and does not actually work against
Codeberg's Forgejo API).

This plugin is Codeberg-only by design. The C<owner/repo> slug is taken from
the git remote and the URLs are built for L<host|/host> (C<codeberg.org> by
default). If the remote does not point at that host (or there is no usable
remote and no L<repo|/repo> override), no target is found and the plugin adds
B<no> resources at all -- it never emits metadata for the wrong forge.

=head1 ATTRIBUTES

=head2 remote

Name of the git remote to read the repository URL from. Default: C<origin>.

=head2 host

The forge host the URLs are built for, and the host the git remote is required
to point at. Default: C<codeberg.org>. Only override this for a self-hosted
Forgejo/Gitea instance.

=head2 repo

Override the C<owner/repo> slug. Must be given in C<owner/repo> form. By
default the slug is extracted from the git remote URL.

=head2 issues

Set the C<bugtracker> resource to the repository's issues page. Default: true.

=head2 homepage

What to put in the C<homepage> resource: C<repo> (the forge repository page,
the default), C<metacpan> (the metacpan.org release page), or C<none>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

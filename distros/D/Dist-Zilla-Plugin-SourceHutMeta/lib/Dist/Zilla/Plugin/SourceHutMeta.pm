package Dist::Zilla::Plugin::SourceHutMeta;

our $VERSION = '1.004'; # VERSION
# ABSTRACT: Automatically include SourceHut meta information in META.yml

use strict;
use warnings;
use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use MooseX::Types::URI qw[Uri];
use Cwd;
use Try::Tiny;
use File::pushd 'pushd';

use namespace::autoclean;

has 'homepage' => (
  is => 'ro',
  isa => Uri,
  coerce => 1,
);

has 'remote' => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub {  [ 'origin' ]  },
);

has 'bugtracker' => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);

has 'user' => (
  is  => 'rw',
  isa => 'Str',
  predicate => '_has_user',
);

has 'repo' => (
  is  => 'rw',
  isa => 'Str',
  predicate => '_has_repo',
);

sub mvp_multivalue_args { qw(remote) }

sub _acquire_repo_info {
  my ($self) = @_;

  my $wd = pushd $self->zilla->root;

  return if $self->_has_user and $self->_has_repo;

  return unless _under_git();

  require IPC::Cmd;
  return unless IPC::Cmd::can_run('git');

  {
    my $gitver = `git version`;
    my ($ver) = $gitver =~ m!git version ([0-9.]+(\.msysgit)?[0-9.]+)!;
    $ver =~ s![^\d._]!!g;
    $ver =~ s!\.$!!;
    $ver =~ s!\.+!.!g;
    chomp $gitver;
    require version;
    my $ver_obj = try { version->parse( $ver ) }
      catch { die "'$gitver' not parsable as '$ver': $_" };
    if ( $ver_obj < version->parse('1.5.0') ) {
      warn "$gitver is too low, 1.5.0 or above is required\n";
      return;
    }
  }

  my $git_url;
  remotelist: for my $remote (@{ $self->remote }) {
    # Missing remotes expand to the same value as they were input
    # ( git version 1.7.7 -- kentnl -- 2011-10-08 )
    unless ( $git_url = $self->_url_for_remote($remote) and $remote ne $git_url ) {
      $self->log(
        ['A remote named \'%s\' was specified, but does not appear to exist.', $remote ]
      );
      undef $git_url;
      next remotelist;
    }
    last if $git_url =~ m!\bgit\.sr\.ht[:/]!; # Short Circuit on Github repository

    # Not a Github Repository?
    $self->log( [
        'Specified remote \'%s\' expanded to \'%s\', which is not a SourceHut repository URL',
        $remote, $git_url,
    ] );

    undef $git_url;
  }

  return unless $git_url;

  my ($user, $repo) = $git_url =~ m{
    git\.sr\.ht              # the domain
    [:/]~ ([^/]+)            # the username (: for ssh, / for http)
    /    ([^/]+?) (?:\.git)? # the repo name
    $
  }ix;

  $self->log(['No user could be discerned from URL: \'%s\'', $git_url ]) unless defined $user ;
  $self->log(['No repository could be discerned from URL: \'%s\'', $git_url ]) unless defined $repo;

  return unless defined $user and defined $repo;

  $self->user($user) unless $self->_has_user;
  $self->repo($repo) unless $self->_has_repo;
}

sub metadata {
  my $self = shift;

  $self->_acquire_repo_info;

  unless ( $self->_has_user and $self->_has_repo ){
    $self->log(['skipping meta.resources.repository creation'] );
    return;
  }

  my $srht_url = sprintf 'https://git.sr.ht/~%s/%s', $self->user, $self->repo;
  my $home_url = $self->homepage ? $self->homepage->as_string : $srht_url;

  my $bugtracker;
  if (!$self->bugtracker && $self->zilla->authors) {
    $bugtracker = {
      mailto => $self->zilla->authors->[0]
    };
  }
  elsif ($self->bugtracker eq 'auto') {
    $bugtracker = {
      web => sprintf 'https://todo.sr.ht/~%s/%s', $self->user, $self->repo
    };
  }
  else {
    $bugtracker = {
      web => $self->bugtracker,
    }
  }

  return {
    resources => {
      homepage   => $home_url,
      repository => {
        type => 'git',
        url  => $srht_url,
        web  => $srht_url,
      },
      bugtracker => $bugtracker,
      foo=>1,
    }
  };
}

sub _url_for_remote {
  my ($self, $remote) = @_;
  local $ENV{LC_ALL}='C';
  local $ENV{LANG}='C';
  my @remote_info = `git remote show -n $remote`;
  for my $line (@remote_info) {
    chomp $line;
    if ($line =~ /^\s*(?:Fetch)?\s*URL:\s*(.*)/) {
      return $1;
    }
  }
  return;
}

sub _under_git {
  return 1 if -e '.git';
  my $cwd = getcwd;
  my $last = $cwd;
  my $found = 0;
  while (1) {
    chdir '..' or last;
    my $current = getcwd;
    last if $last eq $current;
    $last = $current;
    if ( -e '.git' ) {
       $found = 1;
       last;
    }
  }
  chdir $cwd;
  return $found;
}

__PACKAGE__->meta->make_immutable;
no Moose;

q{ listening to: The New Eves - The New Eve Is Rising};

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::SourceHutMeta - Automatically include SourceHut meta information in META.yml

=head1 VERSION

version 1.004

=head1 SYNOPSIS

  # in dist.ini

  [SourceHutMeta]

  # to override the homepage

  [SourceHutMeta]
  homepage = http://some.sort.of.url/project/

  # to override the remote repo (defaults to 'origin')
  [SourceHutMeta]
  remote = sr.ht

=head1 DESCRIPTION

Dist::Zilla::Plugin::SourceHutMeta is a L<Dist::Zilla> plugin to include SourceHut L<https://sr.ht> meta
information in C<META.yml> and C<META.json>.

It automatically detects if the distribution directory is under C<git> version control and whether the
C<origin> is a SourceHut repository and will set the C<repository> and C<homepage> meta in C<META.yml> to the
appropriate URLs for SourceHut.

Copy/pasted and slightly adapted from L<Dist::Zilla::Plugin::GithubMeta>

=head2 ATTRIBUTES

=over

=item C<remote>

The SourceHut remote repo can be overridden with this attribute. If not
provided, it defaults to C<origin>.  You can provide multiple remotes to
inspect.  The first one that looks like a SourceHut remote is used.

=item C<homepage>

You may override the C<homepage> setting by specifying this attribute. This
should be a valid URL as understood by L<MooseX::Types::URI>.

=item C<bugtracker>

Define the URL of the SourceHut "ticket tracking service", aka C<todo>, which will be used as the C<bugtracker> value in C<META.json>. Use the special value C<auto> to calculate the bugtracker URL from the repo name. But as SourceHut by default does not provide linking between the code repo (name) and the todo area, you have to make sure that the URL actually exists.

If not set will use the first author as a C<mailto> bugtracker value (because if no value for C<bugtracker> is set, metacpan will link to RT).

=item C<user>

If given, the C<user> parameter overrides the username found in the SourceHut
repository URL.  This is useful if many people might release from their own
workstations, but the distribution metadata should always point to one user's
repo.

=item C<repo>

If give, the C<repo> parameter overrides the repository name found in the
SourceHut repository URL.

=back

=head2 METHODS

=over

=item C<metadata>

Required by L<Dist::Zilla::Role::MetaProvider>

=back

=for Pod::Coverage mvp_multivalue_args

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::Plugin::GithubMeta>

=head1 CONTRIBUTING

See file C<CONTRIBUTING.md>

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@plix.at>

=item *

Chris Williams <chris@bingosnet.co.uk>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Thomas Klausner, Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

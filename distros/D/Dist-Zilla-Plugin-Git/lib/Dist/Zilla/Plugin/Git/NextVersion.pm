#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::NextVersion;
# ABSTRACT: Provide a version number by bumping the last git release tag

our $VERSION = '2.042';

use Dist::Zilla 4 ();
use version 0.80 ();

use Moose;
use namespace::autoclean 0.09;
use Path::Tiny;
use Try::Tiny;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(Str RegexpRef Bool ArrayRef);

use constant _cache_fn => '.gitnxtver_cache';

with 'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::AfterRelease',
    'Dist::Zilla::Role::FilePruner',
    'Dist::Zilla::Role::VersionProvider',
    'Dist::Zilla::Role::Git::Repo';

# -- attributes

use constant _CoercedRegexp => do {
    my $tc = subtype as RegexpRef;
    coerce $tc, from Str, via { qr/$_/ };
    $tc;
};

has version_regexp  => ( is => 'ro', isa=> _CoercedRegexp, coerce => 1,
                         default => sub { qr/^v(.+)$/ } );

has first_version  => ( is => 'ro', isa=>Str, default => '0.001' );

has version_by_branch  => ( is => 'ro', isa=>Bool, default => 0 );

sub _versions_from_tags {
  my ($regexp, $tags) = @_;

  # WARNING: The quotes in "$1" are necessary, because version doesn't
  # call get magic properly.
  return [ sort map { /$regexp/ ? try { version->parse("$1") } : () } @$tags ];
} # end _versions_from_tags

has _all_versions => (
  is => 'ro',  isa=>ArrayRef,  init_arg => undef,  lazy => 1,
  default => sub {
    my $self = shift;
    my $v = _versions_from_tags($self->version_regexp, [ $self->git->tag ]);
    if ($self->logger->get_debug) {
      $self->log_debug("Found version $_") for @$v;
    }
    $v;
  }
);

sub _max_version {
  my $versions = shift;  # arrayref of versions sorted in ascending order

  return $versions->[-1]->stringify if @$versions;

  return undef;
} # end _max_version

sub _last_version {
  my ($self) = @_;

  my $last_ver;
  my $by_branch = $self->version_by_branch;
  my $git       = $self->git;

  local $/ = "\n"; # Force record separator to be single newline

  if ($by_branch) {
    my $head;
    my $cachefile = path(_cache_fn);
    if (-f $cachefile) {
      ($head) = $git->rev_parse('HEAD');
      return $1 if $cachefile->slurp =~ /^\Q$head\E (.+)/;
    }
    try {
      # Note: git < 1.6.1 doesn't understand --simplify-by-decoration or %d
      my @tags;
      for ($git->rev_list(qw(--simplify-by-decoration --pretty=%d HEAD))) {
        /^\s*\((.+)\)/ or next;
        push @tags, split /,\s*/, $1;
      } # end for lines from git log
      s/^tag:\s+// for @tags;   # Git 1.8.3 says "tag: X" instead of "X"
      my $versions = _versions_from_tags($self->version_regexp, \@tags);
      if ($self->logger->get_debug) {
        $self->log_debug("Found version $_ on branch") for @$versions;
      }
      $last_ver = _max_version($versions);
    };
    if (defined $last_ver) {
      ($head) = $git->rev_parse('HEAD') unless $head;
      print { $cachefile->openw } "$head $last_ver\n";
      return $last_ver;
    }
  } # end if version_by_branch

  # Consider versions from all branches:
  $last_ver = _max_version($self->_all_versions);

  $self->log("WARNING: Unable to find version on current branch")
      if defined($last_ver) and $by_branch;

  return $last_ver;
}

# -- role implementation

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        (map { $_ => $self->$_ } qw(version_regexp first_version)),
        version_by_branch => $self->version_by_branch ? 1 : 0,
    };

    return $config;
};

sub before_release {
  my $self = shift;

  # Make sure we're not duplicating a version:
  my $version = version->parse( $self->zilla->version );

  $self->log_fatal("version $version has already been tagged")
      if grep { $_ == $version } @{ $self->_all_versions };
}

sub after_release {
  my $self = shift;

  # Remove the cache file, just in case:
  path($self->zilla->root)->child(_cache_fn)->remove;
}

sub provide_version {
  my ($self) = @_;

  # override (or maybe needed to initialize)
  return $ENV{V} if exists $ENV{V};

  my $last_ver = $self->_last_version;

  return $self->first_version
    unless defined $last_ver;

  require Version::Next;
  my $new_ver  = Version::Next::next_version($last_ver);
  $self->log("Bumping version from $last_ver to $new_ver");

  return "$new_ver";
}

sub prune_files {
  my $self = shift;

  for my $file (@{ $self->zilla->files }) {

    # Ensure we don't distribute .gitnxtver_cache:
    next unless $file->name eq _cache_fn;

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
} # end prune_files

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::NextVersion - Provide a version number by bumping the last git release tag

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::NextVersion]
    first_version = 0.001       ; this is the default
    version_by_branch = 0       ; this is the default
    version_regexp  = ^v(.+)$   ; this is the default

=head1 DESCRIPTION

This does the L<VersionProvider|Dist::Zilla::Role::VersionProvider> role.
It finds the last version number from your Git tags, increments it
using L<Version::Next>, and uses the result as the C<version> parameter
for your distribution.

In addition, when making a release, it ensures that the version being
released has not already been tagged.  (The
L<Git::Tag|Dist::Zilla::Plugin::Git::Tag> plugin has a similar check,
but Git::Tag only checks for an exact match on the tag.  Since
Git::NextVersion knows how to extract version numbers from tags, it
can find duplicates that Git::Tag would miss.)

The plugin accepts the following options:

=over

=item *

C<first_version> - if the repository has no tags at all, this version
is used as the first version for the distribution.  It defaults to "0.001".

=item *

C<version_by_branch> - if true, consider only tags on the current
branch when looking for the previous version.  If you have a
maintenance branch for stable releases and a development branch for
trial releases, you should set this to 1.  (You'll also need git
version 1.6.1 or later.)  The default is to look at all tags, because
finding the tags reachable from a branch is a more expensive operation
than simply listing all tags.

=item *

C<version_regexp> - regular expression that matches a tag containing
a version.  It must capture the version into $1.  Defaults to ^v(.+)$
which matches the default C<tag_format> from the
L<Git::Tag|Dist::Zilla::Plugin::Git::Tag> plugin.
If you change C<tag_format>, you B<must> set a corresponding C<version_regexp>.

=back

You can also set the C<V> environment variable to override the new version.
This is useful if you need to bump to a specific version.  For example, if
the last tag is 0.005 and you want to jump to 1.000 you can set V = 1.000.

  $ V=1.000 dzil release

Because tracing history takes time, if you use the
C<version_by_branch> option, Git::NextVersion will create a
F<.gitnxtver_cache> file in your repository to track the highest
version number that is an ancestor of the HEAD revision.  You should
add F<.gitnxtver_cache> to your F<.gitignore> file.  It will
automatically be pruned from the distribution.

=for Pod::Coverage provide_version
    prune_files
    before_release
    after_release

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

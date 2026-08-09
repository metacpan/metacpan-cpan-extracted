#
# This file is part of Dist-Zilla-PluginBundle-Git-CheckFor
#
# This software is Copyright (c) 2026 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Role::Git::Repo::More;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Dist::Zilla::Role::Git::Repo::More::VERSION = '0.015';
# ABSTRACT: A little more than Dist::Zilla::Role::Git::Repo

use Moose::Role;
use namespace::autoclean;

with
    'Dist::Zilla::Role::Git::Repo',
    ;

has _repo => (is => 'ro', lazy => 1, builder => '_build__repo', isa => 'Git::Wrapper');
sub _build__repo {
  require Git::Wrapper;
  Git::Wrapper->new(shift->repo_root)
}


# -- attributes

#has version_regexp => (is => 'rwp', isa=>'Str', lazy => 1, predicate => 1, builder => sub { '^v(.+)$' });
#has first_version  => (is => 'rwp', isa=>'Str', lazy => 1, predicate => 1, default => sub { '0.001' });

has _previous_versions => (

    traits  => ['Array'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build__previous_versions',
    isa     => 'ArrayRef[Str]',
    handles => {

        has_previous_versions => 'count',
        previous_versions     => 'elements',
        earliest_version      => [ get =>  0 ],
        last_version          => [ get => -1 ],
    },
);

sub _build__previous_versions {
  my ($self) = @_;

  local $/ = "\n"; # Force record separator to be single newline

  require Git::Wrapper;
  my $git  = Git::Wrapper->new( $self->repo_root );
  my $regexp = $self->version_regexp;

  my @tags = $git->tag;
  @tags = map { /$regexp/ ? $1 : () } @tags;

  # find tagged versions; sort least to greatest
  my @versions =
    sort { version->parse($a) <=> version->parse($b) }
    grep { eval { version->parse($_) }  }
    @tags;

  return [ @versions ];
}

# -- role implementation

#sub provide_version {
  #my ($self) = @_;

  ## override (or maybe needed to initialize)
  #return $ENV{V} if exists $ENV{V};

  #return $self->first_version
    #unless $self->has_previous_versions;

  #my $last_ver = $self->last_version;
  #my $new_ver  = Version::Next::next_version($last_ver);
  #$self->log("Bumping version from $last_ver to $new_ver");

  #return "$new_ver";
#}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Christian Doherty Etheridge Karen Mengué Mike Olivier Walde

=head1 NAME

Dist::Zilla::Role::Git::Repo::More - A little more than Dist::Zilla::Role::Git::Repo

=head1 VERSION

This document describes version 0.015 of Dist::Zilla::Role::Git::Repo::More - released August 08, 2026 as part of Dist-Zilla-PluginBundle-Git-CheckFor.

=head1 SYNOPSIS

    # ta-da!
    with 'Dist::Zilla::Role::Git::Repo::More';

=head1 DESCRIPTION

This is a role that extends L<Dist::Zilla::Role::Git::Repo> to provide an
additional private attribute.  There's probably nothing here you'd be terribly
interested in.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::PluginBundle::Git::CheckFor|Dist::Zilla::PluginBundle::Git::CheckFor>

=item *

L<Dist::Zilla::Role::Git::Repo>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rsrchboy/dist-zilla-pluginbundle-git-checkfor/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

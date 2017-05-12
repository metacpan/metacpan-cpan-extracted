use strict;
use warnings;
package Dist::Zilla::Plugin::BumpVersionFromGit;
# ABSTRACT: DEPRECATED -- use Dist::Zilla::Plugin::Git::NextVersion instead

our $VERSION = '0.010';

use Dist::Zilla 4 ();
use Git::Wrapper;
use version 0.80 ();

use Moose;
use namespace::autoclean 0.09;

with 'Dist::Zilla::Role::VersionProvider';

# -- attributes

has version_regexp  => ( is => 'ro', isa=>'Str', default => '^v(.+)$' );

has first_version  => ( is => 'ro', isa=>'Str', default => '0.001' );

# -- role implementation

sub provide_version {
  my ($self) = @_;

  require Version::Next;

  # override (or maybe needed to initialize)
  return $ENV{V} if exists $ENV{V};

  my $git  = Git::Wrapper->new('.');
  my $regexp = $self->version_regexp;

  my @tags = $git->tag;
  return $self->first_version unless @tags;

  # find highest version from tags
  my ($last_ver) =  sort { version->parse($b) <=> version->parse($a) }
  grep { eval { version->parse($_) }  }
  map  { /$regexp/ ? $1 : ()          } @tags;

  $self->log_fatal("Could not determine last version from tags")
  unless defined $last_ver;

  my $new_ver = Version::Next::next_version($last_ver);
  $self->log("Bumping version from $last_ver to $new_ver");

  $self->zilla->version("$new_ver");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::BumpVersionFromGit - DEPRECATED -- use Dist::Zilla::Plugin::Git::NextVersion instead

=head1 VERSION

version 0.010

=head1 SYNOPSIS

In your F<dist.ini>:

    [BumpVersionFromGit]
    first_version = 0.001       ; this is the default
    version_regexp  = ^v(.+)$   ; this is the default

=head1 DESCRIPTION

B<NOTE> This distribution is B<deprecated>.  The module has been
reborn as L<Dist::Zilla::Plugin::Git::NextVersion> and included in the
L<Dist::Zilla::Plugin::Git> distribution.

=for Pod::Coverage provide_version

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-BumpVersionFromGit/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-BumpVersionFromGit>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-BumpVersionFromGit.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

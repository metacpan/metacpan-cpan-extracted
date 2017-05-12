#===============================================================================
#         FILE:  Dist::Zilla::Plugin::VersionFromScript
#     ABSTRACT:  run command line script to provide version number
# DERIVED FROM:  Dist::Zilla::Plugin::AutoVersion by Ricardo SIGNES <rjbs@cpan.org>
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
our $VERSION = '0.017'; #      VERSION:  1.0
#      CREATED:  12/02/2010 08:51:22 AM PST
#===============================================================================

use 5.002;
use strict;
use warnings;

package Dist::Zilla::Plugin::VersionFromScript;

use Moose;
with(
  'Dist::Zilla::Role::VersionProvider',
  'Dist::Zilla::Role::TextTemplate',
);

our $VERSION = '0.017'; # VERSION

has script => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

sub provide_version {
  my ($self) = @_;

  my $script = $self->script;
  my $version = `$script`;
  chomp $version;

  $self->log_debug([ 'providing version %s', $version ]);

  return $version;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;



=pod

=head1 NAME

Dist::Zilla::Plugin::VersionFromScript - run command line script to provide version number

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This plugin performs the Dist::Zilla::Role::VersionProvider role.  It
runs a user-provided shell script and uses the output as Dist::Zilla's
version.

This module installs a couple of small perl scripts by way of example.

svnversion.pl gets the current Subversion version of your project and
adjusts it to be a useful version number.  To use it, add this to your
dist.ini file:

    [VersionFromScript]
    script = svnversion.pl

git-logs2version.pl counts the number of git log entries (commits) to
find the version number.  This versioning scheme can work in certain
limited workflows.  Add this to dist.ini:

    [VersionFromScript]
    script = git-logs2version.pl

Both svnversion.pl and git-logs2version.pl can take arguments of:

    --major  number   # add a major revision number
    --offset number   # add offset to the minor revision

So for example, if you are at revision 50, calling

    [VersionFromScript]
    script = svnversion.pl --major 3 --offset 22

produces 3.072 as the version number.

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__



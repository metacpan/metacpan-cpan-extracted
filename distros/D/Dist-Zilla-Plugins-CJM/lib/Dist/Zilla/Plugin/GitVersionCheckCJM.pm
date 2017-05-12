#---------------------------------------------------------------------
package Dist::Zilla::Plugin::GitVersionCheckCJM;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 15 Nov 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Ensure version numbers are up-to-date
#---------------------------------------------------------------------

our $VERSION = '4.27';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)


use version 0.77 ();
use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::ModuleInfo',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ qw(:InstallModules :IncModules :ExecFiles) ],
  },
);


has single_version => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

# RECOMMEND PREREQ: Git::Wrapper
use Git::Wrapper ();            # AutoPrereqs skips this

#---------------------------------------------------------------------
# Helper sub to run a git command and split on NULs:

sub _git0
{
  my ($git, $command, @args) = @_;

  my ($result) = do { local $/; $git->$command(@args) };

  return unless defined $result;

  split(/\0/, $result);
} # end _git0

#---------------------------------------------------------------------
# Main entry point:

sub munge_files {
  my ($self) = @_;

  # Get the released versions:
  my $git = Git::Wrapper->new( $self->zilla->root->stringify );

  my %released = map { /^v?([\d._]+)$/ ? ($1, 1) : () } $git->tag;

  # Get the list of modified but not-checked-in files:
  my %modified = map { $self->log_debug("mod: $_"); $_ => 1 } (
    # Files that need to be committed:
    _git0($git, qw( diff_index -z HEAD --name-only )),
    # Files that are not tracked by git yet:
    _git0($git, qw( ls_files -oz --exclude-standard )),
  );

  # Get the list of modules:
  my $files = $self->found_files;

  # Check each module:
  my $errors = 0;
  foreach my $file (@{ $files }) {
    ++$errors if $self->munge_file($file, $git, \%modified, \%released);
  } # end foreach $file

  die "Stopped because of errors\n" if $errors;
} # end munge_files

#---------------------------------------------------------------------
# Check the version of a module:

sub munge_file
{
  my ($self, $file, $git, $modifiedRef, $releasedRef) = @_;

  # Extract information from the module:
  my $pmFile  = $file->name;
  $self->log_debug("checking $pmFile");
  my $pm_info = $self->get_module_info($file);

  my $version = $pm_info->version
      or $self->log_fatal("ERROR: Can't find version in $pmFile");

  my $distver = version->parse($self->zilla->version);

  # If module version matches dist version, it's current:
  #   (unless that dist has already been released)
  if ($version == $distver) {
    return unless $releasedRef->{$version};
  }

  # If the module version is greater than the dist version, that's a problem:
  if ($version > $distver) {
    $self->log("ERROR: $pmFile: $version exceeds dist version $distver");
    return 1;
  }

  # If all modules must have the same version,
  # and the module version is less than the dist version, that's a problem:
  if ($self->single_version and $version < $distver) {
    $self->log("ERROR: $pmFile: $version needs to be updated");
    return 1;
  }

  # If the module hasn't been committed yet, it needs updating:
  #   (since it doesn't match the dist version)
  if ($modifiedRef->{$pmFile}) {
    if ($version == $distver) {
      $self->log("ERROR: $pmFile: dist version $version needs to be updated");
    } else {
      $self->log("ERROR: $pmFile: $version needs to be updated");
    }
    return 1;
  }

  # If the module's version doesn't match the dist, and that version
  # hasn't been released, that's a problem:
  unless ($releasedRef->{$version}) {
    $self->log("ERROR: $pmFile: $version does not seem to have been released, but is not current");
    return 1;
  }

  # See if we checked in the module without updating the version:
  my ($lastChangedRev) = $git->rev_list(qw(-n1 HEAD --) => $pmFile);

  my ($inRelease) = $git->name_rev(
    qw(--refs), "refs/tags/$version",
    $lastChangedRev
  );

  # We're ok if the last change was part of the indicated release:
  return if $inRelease =~ m! tags/\Q$version\E!;

  if ($version == $distver) {
    $self->log("ERROR: $pmFile: dist version $version needs to be updated");
  } else {
    $self->log("ERROR: $pmFile: $version needs to be updated");
  }
  return 1;
} # end munge_file

#---------------------------------------------------------------------
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::GitVersionCheckCJM - Ensure version numbers are up-to-date

=head1 VERSION

This document describes version 4.27 of
Dist::Zilla::Plugin::GitVersionCheckCJM, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 SYNOPSIS

In your F<dist.ini>:

  [GitVersionCheckCJM]

=head1 DESCRIPTION

This plugin makes sure that module version numbers are updated as
necessary.  In a distribution with multiple module, I like to update a
module's version only when a change is made to that module.  In other
words, a module's version is the version of the last distribution
release in which it was modified.

This plugin checks each module in the distribution, and makes sure
that it matches one of two conditions:

=over

=item 1.

There is a tag matching the version, and the last commit on that
module is included in that tag.

=item 2.

The version matches the distribution's version, and that version has
not been tagged yet (i.e., the distribution has not been released).

=back

If neither condition holds, it prints an error message.  After
checking all modules, it aborts the build if any module had an error.


=for Pod::Coverage
munge_file
munge_files

=head1 ATTRIBUTES

=head2 finder

This FileFinder provides the list of modules that will be checked.
The default is C<:InstallModules>.  The C<finder> attribute may be
listed any number of times.


=head2 single_version

If set to a true value, all modules in the distribution must have
the distribution's version.  The default is false, which allows
unchanged modules to retain the version of the distribution in which
they were last changed.

=head1 DEPENDENCIES

GitVersionCheckCJM requires L<Dist::Zilla> (4.300009 or later).
It also requires L<Git::Wrapper>, although it
is only listed as a recommended dependency for the distribution (to
allow people who don't use Git to use the other plugins.)

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-Plugins-CJM AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugins-CJM >>.

You can follow or contribute to Dist-Zilla-Plugins-CJM's development at
L<< https://github.com/madsen/dist-zilla-plugins-cjm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

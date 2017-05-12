package File::Find::Object::Rule::VCS;

=pod

=head1 NAME

File::Find::Object::Rule::VCS - Exclude files/directories for Version Control
Systems

=head1 SYNOPSIS

  use File::Find::Object::Rule      ();
  use File::Find::Object::Rule::VCS ();

  # Find all files smaller than 10k, ignoring version control files
  my @files = File::Find::Object::Rule->ignore_vcs
                                      ->file
                                      ->size('<10Ki')
                                      ->in( $dir );

=head1 DESCRIPTION

Many tools need to be equally useful both on ordinary files, and on code
that has been checked out from revision control systems.

B<File::Find::Object::Rule::VCS> provides quick and convenient methods to
exclude the version control directories of several major Version
Control Systems (currently CVS, subversion, and Bazaar).

B<File::Find::Object::Rule::VCS> implements methods to ignore the following:

=over 4

=item B<CVS>

=item B<Subversion>

=item B<Bazaar>

=back

In addition, the following version control systems do not create
directories in the checkout and do not require the use of any
ignore methods

=over 4

=item B<SVK>

=item B<Git>

=back

=head1 METHODS

=cut

use 5.008;

use strict;
use warnings;

use UNIVERSAL;
use Carp                  ();
use Text::Glob       0.08 ();
use File::Find::Object::Rule ();

use vars qw{$VERSION @ISA @EXPORT};

$VERSION = '0.0.3';

use base 'File::Find::Object::Rule';

my $FFOR = 'File::Find::Object::Rule';

# In some Windows SVN implementations, it uses _svn instead of
# .svn, so use both on Win32.
my @svn = ($^O eq 'MSWin32') ? ('.svn', '_svn') : ('.svn');

#####################################################################
# File::Find::Object::Rule Method Addition

=pod

=head2 ignore_vcs

  # Ignore all common version control systems
  $find->ignore_vcs;

  # Ignore a specific named version control systems
  $find->ignore_vcs($name);

  # Ignore nothing (silent pass-through)
  $find->ignore_vcs('');

The C<ignore_vcs> method excludes the files for a named Version Control
System from your L<File::Find::Object::Rule> search.

If passed, the name of the version control system is case in-sensitive.
Names currently supported are 'cvs', 'svn', 'subversion', 'bzr', and
'bazaar'.

As a convenience for high-level APIs, if the VCS name is the defined
null string B<''> then the call will be treated as a nullop.

If no params at all are passed, this method will ignore all supported
version control systems. If ignoring every version control system,
please note that any legitimate directories called "CVS" or files
starting with .# will be ignored, which is not always desirable.

In widely-distributed code, you instead should try to detect the specific
version control system used and call ignore_vcs with the specific name.

Passing C<undef>, or an unsupported name, will throw an exception.

=cut

sub File::Find::Object::Rule::ignore_vcs {
	my $find = $_[0]->_force_object;

	# Handle special cases
	unless ( @_ ) {
		# Logically combine all the ignores. This will be much
		# faster than just calling them all one after the other.
		return $find->or(
			$FFOR->name(@svn, '.bzr', '.git', 'CVS')->directory->prune->discard,
			$FFOR->name(qr/^\.\#/)->file->discard,
			$FFOR->new,
			);
	}
	unless ( defined $_[1] ) {
		Carp::croak("->ignore_vcs: No version control system name provided");
	}

        # As a convenience for higher-level APIs
        # we treat a defined null string as a nullop
	my $vcs = lc $_[1];
        return $find if $vcs eq '';

	# Hand off to the rules for each VCS
	return $find->ignore_cvs if $vcs eq 'cvs';
	return $find->ignore_svn if $vcs eq 'svn';
	return $find->ignore_svn if $vcs eq 'subversion';
	return $find->ignore_bzr if $vcs eq 'bzr';
	return $find->ignore_bzr if $vcs eq 'bazaar';
	return $find->ignore_git if $vcs eq 'git';
	Carp::croak("->ignore_vcs: '$vcs' is not supported");
}

=pod

=head2 ignore_cvs

The C<ignore_cvs> method excluding all CVS directories from your
L<File::Find::Object::Rule> search.

It will also exclude all the files left around by CVS after an
automated merge that start with C<'.#'> (dot-hash).

=cut

sub File::Find::Object::Rule::ignore_cvs {
	my $find = $_[0]->_force_object;
	return $find->or(
		$FFOR->name('CVS')->directory->prune->discard,
		$FFOR->name(qr/^\.\#/)->file->discard,
		$FFOR->new,
		);
}

=pod

=head2 ignore_svn

The C<ignore_svn> method excluding all Subversion (C<.svn>) directories
from your L<File::Find::Object::Rule> search.

=cut

sub File::Find::Object::Rule::ignore_svn {
	my $find = $_[0]->_force_object;
	return $find->or(
		$FFOR->name(@svn)->directory->prune->discard,
		$FFOR->new,
		);
}

=pod

=head2 ignore_bzr

The C<ignore_bzr> method excluding all Bazaar (C<.bzr>) directories
from your L<File::Find::Object::Rule> search.

=cut

sub File::Find::Object::Rule::ignore_bzr {
	my $find = $_[0]->_force_object;
	return $find->or(
		$FFOR->name('.bzr')->directory->prune->discard,
		$FFOR->new,
		);
}

=pod

=head2 ignore_git

The C<ignore_git> method excluding all Git (C<.git>) directories
from your L<File::Find::Object::Rule> search.

=cut

sub File::Find::Object::Rule::ignore_git {
	my $find = $_[0]->_force_object;
	return $find->or(
		$FFOR->name('.git')->directory->prune->discard,
		$FFOR->new,
		);
}

1;

=pod

=head1 TO DO

- Add support for other version control systems.

- Add other useful VCS-related methods

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rule-VCS>

For other issues, contact the maintainer

=head1 AUTHOR

=head2 ORIGINAL AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head2 MAINTAINER

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 SEE ALSO

L<http://ali.as/>, L<File::Find::Object::Rule>

Note: this code originated from Adam Kennedy's L<File::Find::Rule::VCS>
and was span-off/forked with his permission.

=head1 COPYRIGHT

Copyright 2005 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head2 Modification Disclaimer

Modified by Shlomi Fish, 2009. All rights disclaimed.

=cut

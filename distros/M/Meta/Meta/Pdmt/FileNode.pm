#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::FileNode;

use strict qw(vars refs subs);
use Meta::Pdmt::Md5Node qw();
use Meta::Utils::File::File qw();
use Meta::Class::MethodMaker qw();
use Meta::Utils::File::Time qw();
use Meta::Digest::MD5 qw();

our($VERSION,@ISA);
$VERSION="0.04";
@ISA=qw(Meta::Pdmt::Md5Node);

#sub BEGIN();
#sub md5($);
#sub exists($);
#sub remove($);
#sub mtime($);
#sub TEST($);

#__DATA__

our($patho)=Meta::Baseline::Aegis::search_path_object();

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_path",
	);
}

sub md5($) {
	my($self)=@_;
	return(Meta::Digest::MD5::get_filename_digest($self->get_path()));
}

sub exists($) {
	my($self)=@_;
	return($patho->exists($self->get_path()));
}

sub remove($) {
	my($self)=@_;
	return(Meta::Utils::File::File::rm($self->get_path()));
}

sub mtime($) {
	my($self)=@_;
	return($patho->mtime($self->get_path()));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::FileNode - a node representing a file.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: FileNode.pm
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::FileNode qw();
	my($object)=Meta::Pdmt::FileNode->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This is a node in the PDMT graph representing a file in the file system.

=head1 FUNCTIONS

	BEGIN()
	md5($)
	exists($)
	remove($)
	mtime($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This initialization method sets up a default constructor and accessor methods
for the following attributes:
1. path - path of the file in the file system.

=item B<md5($)>

This method overrides the abstract interface in the parent Md5Node and implement
a regular file md5 algorithm.

=item B<exists($)>

This method returns whether the file exists or not.

=item B<remove($)>

This file removes the current file ("make clean").

=item B<mtime($)>

This method returns the modification date of the current file. 0 means that
the file doesn't exist (or very old).

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Pdmt::Md5Node(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV bring movie data
	0.03 MV teachers project
	0.04 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Digest::MD5(3), Meta::Pdmt::Md5Node(3), Meta::Utils::File::File(3), Meta::Utils::File::Time(3), strict(3)

=head1 TODO

Nothing.

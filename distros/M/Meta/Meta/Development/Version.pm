#!/bin/echo This is a perl module and should not be run

package Meta::Development::Version;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub BEGIN();
#sub get_major($);
#sub set_major($$);
#sub get_minor($);
#sub set_minor($$);
#sub get_patch($);
#sub set_patch($$);
#sub get_rep_module($);
#sub get_rep_dll($);
#sub get_rep_rpm($);
#sub is_compatible($$);
#sub is_incompatible($$);
#sub next_major($$);
#sub next_minor($$);
#sub next_patch($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_major",
		-java=>"_minor",
		-java=>"_patch",
	);
}

sub get_rep_module($) {
	my($self)=@_;
	return(join(".",$self->get_major(),$self->get_minor(),$self->get_patch()));
}

sub get_rep_dll($) {
	my($self)=@_;
	return(join(".",$self->get_major(),$self->get_minor(),$self->get_patch()));
}

sub get_rep_rpm($) {
	my($self)=@_;
	return(join(".",$self->get_major(),$self->get_minor(),$self->get_patch()));
}

sub is_compatible($$) {
	my($self,$obje)=@_;
	if($self->get_major()!=$obje->get_major()) {
		return(0);
	}
	if($self->get_minor()>$obje->get_minor()) {
		return(1);
	}
	return(0);
}

sub is_incompatible($$) {
	my($self,$obje)=@_;
	return(!($self->is_compatible($obje)));
}

sub next_major($) {
	my($self)=@_;
	$self->set_major($self->get_major()+1);
}

sub next_minor($) {
	my($self)=@_;
	$self->set_minor($self->get_minor()+1);
}

sub next_patch($) {
	my($self)=@_;
	$self->set_patch($self->get_patch()+1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Development::Version - handle a version number in development.

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

	MANIFEST: Version.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Development::Version qw();
	my($object)=Meta::Development::Version->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module assumes that when you assign a version number (to a file,
a package etc...) you're not doing it for commercial reasons but rather
for technical reasons. In open/free source this is indeed the case. If
that is the case then you can deduce various information for different
version number. This module is here to help you with doing that.

The basic assumption is that a version number for a module/a piecew of
software etc... is made up of several components:
0. The major number.
1. The minor number.
2. The patch level.
Two packages carrying the same version except patch level are compatible
both ways (anything you can do with the one you can do with the other).
The patch level is assumed to be there for fixing bugs and thats it.
Two packages carrying the same major number are expected to be backward
compatible (meaning that you can replace the older with the newer but
the inverse is not neccessarily true).
Two packages carrying different major numbers are assumed to be
incompatible in every way (the package is still hopefully serving the same
general pupose but in a totaly different way).

This module can read version numbers of different objects:
perl modules, dlls, rpms, tar.gz source files etc...
It can then answer questions like: Are these two compatible ?

When using this package one must keep in mind that the conventions mentioned
earlier are the common ones used in the free/open source community. That does
not mean that every package out there keeps these rules and in many case even
package maintainers which mean to abide by the rules release a new version
of a product with only a minor bump while  a major bump would have been
more appropriate (they do not notice that they are breaking compatibility).

Also one must keep in mind that compatiblity is not just one thing. There is
source compatibility and target compatibility. Source compatibility means that
using the new package does not cause the code to stop compiling. Target
compatibility means that using the new package does not cause the binary to
stop running. These are totaly different things which do not follow one from
the other in any direction.

Keeping that in mind I hope you like the module...:)

=head1 FUNCTIONS

	BEGIN()
	get_rep_module($)
	get_rep_dll($)
	get_rep_rpm($)
	is_compatible($$)
	is_incompatible($$)
	next_major($$)
	next_minor($$)
	next_patch($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This block takes care of setting accessors for the following
attributes: major, minor, patch.

=item B<get_rep_module($)>

This method will return a string which can be used as a perl
module version.

=item B<get_rep_dll($)>

This method will return a string which can be used as a UNIX
shared library version.

=item B<get_rep_rpm($)>

This method will return a string which can be used as an RPM
version number.

=item B<is_compatible($$)>

This method receives a two version object and returns true iff the
first one is compatible with the second one.

=item B<is_incompatible($$)>

This method returns the exact opposite of the is_compatible method.

=item B<next_major($)>

This method will increase the major number of the version.

=item B<next_minor($)>

This method will increase the minor number of the version.

=item B<next_patch($)>

This method will advance the version to a version which is just a patch
level above the current.

=item B<TEST($)>

Test suite for this model.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more database issues
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV movies and small fixes
	0.05 MV thumbnail project basics
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site development
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

-add methods like: parse_rpm, parse_dll, parse_targz, parse_any etc...

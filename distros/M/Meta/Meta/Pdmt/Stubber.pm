#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Stubber;

use strict qw(vars refs subs);
use Meta::Pdmt::TargetFileNode qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Utils qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Pdmt::TargetFileNode);

#sub build($$);
#sub TEST($);

#__DATA__

sub build($$) {
	my($node,$pdmt)=@_;
	my($path)=$node->get_path();
	Meta::Utils::Output::print("doing [".$path."]\n");
	Meta::Baseline::Utils::mkdir_emblem($path);
	return(1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Stubber - rule to just leave stub files as targets.

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

	MANIFEST: Stubber.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Stubber qw();
	my($object)=Meta::Pdmt::Stubber->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This node type just leave small stub files as output.
Use this for testing.

=head1 FUNCTIONS

	build($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<build($$)>

This is the actual method which leaves the stub files.

=item B<TEST($)>

This is a testing suite for the Meta::Pdmt::Stubber module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Meta::Pdmt::TargetFileNode(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Utils(3), Meta::Pdmt::TargetFileNode(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Nodes::PerlPod;

use strict qw(vars refs subs);
use Meta::Pdmt::TargetFileNode qw();
use Pod::Man qw();
use Meta::Utils::File::Mkdir qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Pdmt::TargetFileNode);

#sub build($$);
#sub TEST($);

#__DATA__

sub build($$) {
	my($node,$pdmt)=@_;
	my($targ)=$node->get_path();
	my($source_node)=$pdmt->get_single_succ($node);
	my($name)=$source_node->get_name();
	my($path)=$source_node->get_path();
	my($abs_path)=Meta::Baseline::Aegis::which($path);
	#my($scod)=Meta::Utils::System::system_shell_nodie("pod2man ".$buil->get_srcx()." > ".$buil->get_targ());
	Meta::Utils::File::Mkdir::mkdir_p_check_file($targ);
	my($parser)=Pod::Man->new();
	my($scod)=$parser->parse_from_file($abs_path,$targ);
	return($scod);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Nodes::PerlPod - PDMT node to convert documented perl code (POD) to manual pages.

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

	MANIFEST: PerlPod.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Nodes::PerlPod qw();
	my($object)=Meta::Pdmt::Nodes::PerlPod->new();
	my($result)=$object->method();

=head1 DESCRIPTION

Put a lot of documentation here to show what your class does.

=head1 FUNCTIONS

	new($)
	method($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Pdmt::Nodes::PerlPod object.

=item B<method($)>

This is an object method.

=item B<TEST($)>

This is a testing suite for the Meta::Pdmt::Nodes::PerlPod module.
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

Meta::Pdmt::TargetFileNode(3), Meta::Utils::File::Mkdir(3), Pod::Man(3), strict(3)

=head1 TODO

Nothing.

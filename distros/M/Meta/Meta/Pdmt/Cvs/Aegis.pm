#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Cvs::Aegis;

use strict qw(vars refs subs);
use Meta::Pdmt::Cvs qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Meta::Pdmt::SourceFileNode qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Pdmt::Cvs);

#sub add_all_nodes($$);
#sub TEST($);

#__DATA__

sub add_all_nodes($$) {
	my($self,$graph)=@_;
	#Meta::Utils::Output::print("started reading sources from SCCS\n");
	my($list)=Meta::Baseline::Aegis::source_files_list(1,1,0,1,1,0);
	#Meta::Utils::Output::print("finished reading sources from SCCS\n");
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		#Meta::Utils::Output::print("curr is [".$curr."]\n");
		my($node)=Meta::Pdmt::SourceFileNode->new();
		$node->set_name($curr);
		$node->set_path($curr);
		$graph->add_vertex($node);
	}
	return(1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Cvs::Aegis - implement Pdmt interface to Aegis.

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

	MANIFEST: Aegis.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Cvs::Aegis qw();
	my($object)=Meta::Pdmt::Cvs::Aegis->new();
	my($ok)=$object->add_all_nodes($graph);

=head1 DESCRIPTION

This class implements a Pdmt interface to the Aegis source control system.
Currently it only implements the add_all_nodes method which retrieves all
the files in the project from the changes point of view by using the
Aegis module (Meta::Baseline::Aegis).

=head1 FUNCTIONS

	add_all_nodes($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<add_all_nodes($$)>

Over rides the abstract implementation and adds all source nodes that the
source control system knows about to the graph given to it.

=item B<TEST($)>

This is a testing suite for the Meta::Pdmt::Cvs::Aegis module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test does nothing.

=back

=head1 SUPER CLASSES

Meta::Pdmt::Cvs(3)

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

Meta::Baseline::Aegis(3), Meta::Pdmt::Cvs(3), Meta::Pdmt::SourceFileNode(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

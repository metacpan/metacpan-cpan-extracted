#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Handlers::Dtd2Html;

use strict qw(vars refs subs);
use Meta::Pdmt::Handler qw();
use Meta::Pdmt::Nodes::Dtd2Html qw();
use Meta::Utils::Utils qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Pdmt::Handler);

#sub add_node($$$);
#sub TEST($);

#__DATA__

sub add_node($$$) {
	my($self,$node,$graph)=@_;
	my($path)=$node->get_path();
	if(Meta::Utils::Utils::is_suffix($path,".dtd")) {
		my($new_file)="html/".Meta::Utils::Utils::remove_suffix($path).".html";
		my($new_node)=Meta::Pdmt::Nodes::Dtd2Html->new();
		$new_node->set_name($new_file);
		$new_node->set_path($new_file);
		#Meta::Utils::Output::print("going to add vertex [".$new_file."]\n");
		$graph->add_vertex($new_node);
		#Meta::Utils::Output::print("going to add edge from [".$new_file."] to [".$path."]\n");
		$graph->add_edge($new_node,$node);
		#Meta::Utils::Output::print("finished adding edge\n");
		return(1);
	} else {
		return(0);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Handlers::Dtd2Html - handle conversion of Dtd to HTML.

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

	MANIFEST: Dtd2Html.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Handlers::Dtd2Html qw();
	my($object)=Meta::Pdmt::Handlers::Dtd2Html->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will recognize Dtd files and add html nodes for them.

=head1 FUNCTIONS

	add_node($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<add_node($$$)>

This does the actual work.

=item B<TEST($)>

This is a testing suite for the Meta::Pdmt::Handlers::Dtd2Html module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Meta::Pdmt::Handler(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more pdmt stuff
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Pdmt::Handler(3), Meta::Pdmt::Nodes::Dtd2Html(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.

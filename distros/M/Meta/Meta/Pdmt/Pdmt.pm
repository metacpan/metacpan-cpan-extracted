#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Pdmt;

use strict qw(vars refs subs);
use Meta::Pdmt::Graph qw();
use Meta::Pdmt::Handlers qw();
use Meta::Pdmt::Listen qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub BEGIN();
#sub new($);
#sub listen($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_graph",
		-java=>"_handlers",
		-java=>"_cvs",
	);
}

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->set_graph(Meta::Pdmt::Graph->new());
	$self->get_graph()->set_pdmt($self);
	$self->set_handlers(Meta::Pdmt::Handlers->new());
	return($self);
}

sub add_files($) {
	my($self)=@_;
	$self->get_cvs()->add_all_nodes($self->get_graph());
}

sub listen($) {
	my($self)=@_;
	my($listen)=Meta::Pdmt::Listen->new();
	$listen->listen();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Pdmt - this is the pdmt object (master).

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

	MANIFEST: Pdmt.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Pdmt qw();
	my($object)=Meta::Pdmt::Pdmt->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This is the Pdmt main object which stores the graph handlers and all.

=head1 FUNCTIONS

	BEGIN()
	new($)
	listen($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap the class and create accessors to graph, handlers and cvs.

=item B<new($)>

This is a constructor for the Meta::Pdmt::Pdmt object.

=item B<listen($)>

This method will receive events and will handle them.
The events are: build [nodes],print_graph.

=item B<TEST($)>

Test suite for this module.

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

	0.00 MV misc fixes
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV teachers project
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Pdmt::Graph(3), Meta::Pdmt::Handlers(3), Meta::Pdmt::Listen(3), strict(3)

=head1 TODO

Nothing.

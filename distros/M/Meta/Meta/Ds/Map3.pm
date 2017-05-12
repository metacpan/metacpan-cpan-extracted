#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Map3;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Utils::Output qw();
use Meta::Ds::Map qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sbu BEGIN();
#sub new($);
#sub insert($$$$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_map_a_b",
		-java=>"_map_a_c",
		-java=>"_map_b_c",
	);
}

sub new($) {
	my($class)=@_;
	my($self)={};
	CORE::bless($self,$class);
	$self->set_map_a_b(Meta::Ds::Map->new());
	$self->set_map_a_c(Meta::Ds::Map->new());
	$self->set_map_b_c(Meta::Ds::Map->new());
	return($self);
}

sub insert($$$$) {
	my($self,$a,$b,$c)=@_;
	my($map_a_b)=$self->get_map_a_b();
	my($map_a_c)=$self->get_map_a_c();
	my($map_b_c)=$self->get_map_b_c();
	if($map_a_b->has_a($a)) {
		throw Meta::Error::Simple("has elem a [".$a."]");
	}
	if($map_a_b->has_b($b)) {
		throw Meta::Error::Simple("has elem b [".$b."]");
	}
	if($map_a_c->has_b($c)) {
		throw Meta::Error::Simple("has elem c [".$c."]");
	}
	$map_a_b->insert($a,$b);
	$map_a_c->insert($a,$c);
	$map_b_c->insert($b,$c);
	return(1);
}

sub TEST($) {
	my($context)=@_;
	my($map)=__PACKAGE__->new();
	$map->insert("a1","b1","c1");
	$map->insert("a2","b2","c2");
	$map->insert("a3","b3","c3");
	Meta::Utils::Output::dump($map);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Map3 - a three way map.

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

	MANIFEST: Map3.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Map3 qw();
	my($object)=Meta::Ds::Map3->new();
	my($result)=$object->insert("1","014995815","Mark Veltzer");
	my($id)=$object->get_b_from_c("Mark Veltzer");
	# $id is now "014995815"

=head1 DESCRIPTION

This object allows you to store a three way map. Map between three
values which each comes from a unique domain where each map entry
connects three such values.
For instance: lets say that each worked in a factory has a:
1. serial number.
2. social security number.
3. security id within the factory.
Each of these is unique in it's domain. If you store all of your
employee information in a 3 way map you could get an combination
of the other 2 from any one piece of information quickly.

See the TEST() method to see it actually being used.

=head1 FUNCTIONS

	BEGIN()
	new($)
	insert($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to provide access to the following attributes:
0. map_a_b - maps a to b elements.
1. map_a_c - maps a to c elements.
2. map_b_c - maps b to c elements.

=item B<new($)>

This is a constructor for the Meta::Ds::Map3 object.

=item B<insert($$$$)>

This is the insertion method. It receives the a,b and c elements.

=item B<TEST($)>

This is a testing suite for the Meta::Ds::Map3 module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test just creates an object and dumps it.

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

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Ds::Map(3), Meta::Error::Simple(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

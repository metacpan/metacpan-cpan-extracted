#!/bin/echo This is a perl module and should not be run

package Meta::Info::Address;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.15";
@ISA=qw();

#sub BEGIN();
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_country",
		-java=>"_state",
		-java=>"_county",
		-java=>"_city",
		-java=>"_suburb",
		-java=>"_street",
		-java=>"_house_number",
		-java=>"_flat_number",
		-java=>"_floor_number",
		-java=>"_entrance_number",
		-java=>"_mail",
		-java=>"_phone",
		-java=>"_fax",
		-java=>"_postcode",
	);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::Address - Address information object.

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

	MANIFEST: Address.pm
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	package foo;
	use Meta::Info::Address qw();
	my($object)=Meta::Info::Address->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class provides address information.
You can write this in SGML format or parse it from SGML.
You can also write it in other formats.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method sets up attribute accessors to this object which are:
0. "country" - country of the address.
1. "state" - state of the address (US and countries with states only).
2. "county" - municipal county of the address.
3. "city" - city name.
4. "suburb" - suburb name.
5. "street" - street name.
6. "house_number" - house number.
7. "flat_number" - flat number.
8. "floor_number" - floor (high rise buildings only).
9. "entrance_number" - entrance number (buildings with several entries only).
10. "mail" - email at that location.
11. "phone" - land line at that location.
12. "fax" - fax at that location.
13. "postcode" - postal code at that location.

=item B<TEST($)>

Test suite for this module.

This test currently does nothing.

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

	0.00 MV perl packaging
	0.01 MV PDMT
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV more Class method generation
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site development
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV bring movie data
	0.14 MV finish papers
	0.15 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

-add more information here and track the Docbook DTD.

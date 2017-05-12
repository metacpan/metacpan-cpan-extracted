#!/bin/echo This is a perl module and should not be run

package Meta::Info::Enum;

use strict qw(vars refs subs);
use Meta::Ds::Ohash qw();
use Meta::Utils::Output qw();
use Meta::Xml::Parsers::Enum qw();
use Meta::Development::Module qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Ds::Ohash);

#sub BEGIN();
#sub new_file($$);
#sub new_modu($$);
#sub is_selected($$$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
		-java=>"_default",
	);
}

sub new_file($$) {
	my($class,$file)=@_;
	my($parser)=Meta::Xml::Parsers::Enum->new();
	$parser->parsefile($file);
	return($parser->get_result());
}

sub new_modu($$) {
	my($class,$modu)=@_;
	my($file)=$modu->get_abs_path();
	return(&new_file($class,$file));
}

sub is_selected($$$) {
	my($self,$selected,$val)=@_;
	if($self->hasnt($val)) {
		throw Meta::Error::Simple("value [".$val."] is not part of the enum");
	}
	return($selected eq $val);
}

sub TEST($) {
	my($context)=@_;
	my($enum)=__PACKAGE__->new();
	$enum->set_name("enum type");
	$enum->set_description("this is the description");
	$enum->insert("one","this is one");
	$enum->insert("two","this is two");
	$enum->insert("three","this is three");
	$enum->set_default("one");
	Meta::Utils::Output::dump($enum);
	my($module)=Meta::Development::Module->new_name("xmlx/enum/releaseinfo.xml");
	my($read_enum)=__PACKAGE__->new_modu($module);
	Meta::Utils::Output::dump($read_enum);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::Enum - This is a generic enumerated type that can be parsed from XML.

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

	MANIFEST: Enum.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Info::Enum qw();
	my($object)=Meta::Info::Enum->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This is a classic enumerated type that can be parsed from an XML file.

=head1 FUNCTIONS

	BEGIN()
	new_file($$)
	new_modu($$)
	is_selected($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a bootup method intended to setup the accessor methods for the following
attributes:
0. name - name of this enumerated type.
1. description - description of this enumerated type.
2. default - default value for this enumerated type.

=item B<new_file($$)>

Constructor from an XML/Enum file.

=item B<new_modu($$)>

Constructor from an XML/Enum module.

=item B<is_selected($$$)>

Give this method an Enum object and two values. One entered by some outside source
and one that your software wants to check it against. The method will return
whether they are the same. Why not use eq ? well - this method raises an exception
if the value in your source is not part of the enum...:)

=item B<TEST($)>

This is a testing suite for the Meta::Info::Enum module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Meta::Ds::Ohash(3)

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

Error(3), Meta::Development::Module(3), Meta::Ds::Ohash(3), Meta::Utils::Output(3), Meta::Xml::Parsers::Enum(3), strict(3)

=head1 TODO

Nothing.

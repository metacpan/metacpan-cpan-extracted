#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Perl::Perlpkgs;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();
use Meta::Xml::Parsers::Perlpkgs qw();
use Meta::Utils::Output qw();
use Data::Dumper qw();

our($VERSION,@ISA);
$VERSION="0.16";
@ISA=qw(Meta::Ds::Array);

#sub new_file($$);
#sub new_modu($$);
#sub add_deps($$$);
#sub TEST($);

#__DATA__

sub new_file($$) {
	my($class,$file)=@_;
#	Meta::Utils::Output::print("before creating object\n");
	my($parser)=Meta::Xml::Parsers::Perlpkgs->new();
#	Meta::Utils::Output::print("before parsing\n");
	my($res)=$parser->parsefile($file);
#	Meta::Utils::Output::print("res is [".$res."]\n");
	return($parser->get_result());
}

sub new_modu($$) {
	my($class,$modu)=@_;
	return(&new_file($class,$modu->get_abs_path()));
}

sub add_deps($$$) {
	my($self,$modu,$deps)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->getx($i)->add_deps($modu,$deps);
	}
}

sub TEST($) {
	my($context)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/temp/xmlx/perlpkgs/meta.xml");
	my($object)=Meta::Lang::Perl::Perlpkgs->new_modu($module);
	Meta::Utils::Output::print(Data::Dumper::Dumper($object));
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Perl::Perlpkgs - store information for a perl packages.

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

	MANIFEST: Perlpkgs.pm
	PROJECT: meta
	VERSION: 0.16

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Perl::Perlpkgs qw();
	my($object)=Meta::Lang::Perl::Perlpkgs->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module stores multiple perl package information.

=head1 FUNCTIONS

	new_file($$)
	new_modu($$)
	add_deps($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new_file($$)>

This method will read an XML file that contains Perlpkgs information
using the Meta::Xml::Parser::Perlpkgs parser.

=item B<new_modu($$)>

This method will create an instance with a development module.

=item B<add_deps($$$)>

This method will add dependency information for the set of perl
packages.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Array(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging
	0.01 MV perl packaging again
	0.02 MV perl packaging again
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV thumbnail project basics
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV bring movie data
	0.14 MV finish papers
	0.15 MV teachers project
	0.16 MV md5 issues

=head1 SEE ALSO

Data::Dumper(3), Meta::Ds::Array(3), Meta::Utils::Output(3), Meta::Xml::Parsers::Perlpkgs(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Type;

use strict qw(vars refs subs);
use Meta::Xml::Parsers::Base qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw(Meta::Xml::Parsers::Base);

#sub new($);
#sub get_result($);
#sub handle_doctype($$$$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=XML::Parser::Expat->new();
	if(!$self) {
		throw Meta::Error::Simple("didn't get a parser");
	}
	$self->setHandlers(
		'Doctype'=>\&handle_doctype,
	);
	bless($self,$class);
	$self->{TYPE}=defined;
	return($self);
}

sub get_result($$) {
	my($self)=@_;
	return($self->{TYPE});
}

sub handle_doctype($$$$$) {
	my($self,$name,$sysid,$pubid,$internal)=@_;
#	Meta::Utils::Output::print("in handle_doctype\n");
	$self->{TYPE}=$name;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Type - find type of an XML file.

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

	MANIFEST: Type.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Type qw();
	my($deps_parser)=Meta::Xml::Parsers::Type->new();
	$deps_parser->parsefile($file);
	my($deps)=$desp_parser->get_result();

=head1 DESCRIPTION

This is an Expat based parser who's sole purpose is to find the
type of certain XML file.

=head1 FUNCTIONS

	new($)
	get_result($)
	handle_doctype($$$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<get_result($)>

This will return the dependency object which is the result of the parse.

=item B<handle_doctype($$$$$)>

This method will handle the document type declarations and will add the
dependency on the dtd to the deps object.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Xml::Parsers::Base(3)

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
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Output(3), Meta::Xml::Parsers::Base(3), strict(3)

=head1 TODO

-couldnt we stop the parsing after we found the type ? (saves time).

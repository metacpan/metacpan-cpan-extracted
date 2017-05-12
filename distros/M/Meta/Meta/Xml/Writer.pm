#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Writer;

use strict qw(vars refs subs);
use XML::Writer qw();
use Meta::Lang::Docb::Params qw();
use IO::String qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.15";
@ISA=qw(XML::Writer);

#sub my_doctype($$$);
#sub base_comment($);
#sub TEST($);

#__DATA__

sub my_doctype($$$) {
	my($self,$name,$public)=@_;
	my($output)=$self->getOutput();
	$output->print("<!DOCTYPE ".$name." PUBLIC \"".$public."\" []>\n");
}

sub base_comment($) {
	my($self)=@_;
	$self->comment("Base generated document - DO NOT EDIT!");
}

sub TEST($) {
	my($context)=@_;
	my($var);
	my($io)=IO::String->new(\$var);
	my($xml)=__PACKAGE__->new(OUTPUT=>$io);
	$xml->xmlDecl();
	$xml->doctype(
		"section",
		Meta::Lang::Docb::Params::get_public(),
	);
	$xml->startTag("section");
	$xml->endTag("section");
	$xml->end();
	Meta::Utils::Output::print("result is [".$var."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Writer - XML::Writer with some extra stuff.

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

	MANIFEST: Writer.pm
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Writer qw();
	my($object)=Meta::Xml::Writer->new();
	my($result)=$object->my_doctype("book",[public]);

=head1 DESCRIPTION

This class extends the XML::Writer class which you can get from
CPAN. The idea is that in the Meta project you will only use
this class and thus I could add functionality to the writers
used in this project without changing their code (and also
fix bugs in the original XML::Writer).

=head1 FUNCTIONS

	my_doctype($$$)
	base_comment($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<my_doctype($$$)>

This is a replacement for the XML::Writer original method "doctype" to provide
ability not to put a system id.
I understand that writing this way may not be XML but rather SGML but I still
need the method.

=item B<base_comment($)>

This method will emit a comment saying that the file is auto generated and should
not be edited.

=item B<TEST($)>

Test suite for this module.
Currently it just initializes an object and writer some xml.

=back

=head1 SUPER CLASSES

XML::Writer(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV history change
	0.01 MV more data sets
	0.02 MV spelling and papers
	0.03 MV perl packaging
	0.04 MV md5 project
	0.05 MV database
	0.06 MV perl module versions in files
	0.07 MV movies and small fixes
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV move tests to modules
	0.14 MV teachers project
	0.15 MV md5 issues

=head1 SEE ALSO

IO::String(3), Meta::Lang::Docb::Params(3), Meta::Utils::Output(3), XML::Writer(3), strict(3)

=head1 TODO

Nothing.

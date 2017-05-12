#!/bin/echo This is a perl module and should not be run

package Meta::Xml::ValidWriter;

use strict qw(vars refs subs);
use XML::ValidWriter qw();
use IO qw();
use IO::String qw();
use XML::Doctype qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw(XML::ValidWriter);

#sub new_file($$$$$);
#sub new_string($$$$$);
#sub end($);
#sub TEST($);

#__DATA__

sub new_file($$$$$) {
	my($clas,$file,$dtdx,$elem,$pubi)=@_;
	my($dtd)=XML::Doctype->new();
	$dtd->parse_dtd_file($elem,Meta::Baseline::Aegis::which($dtdx));
	my($io)=IO::File->new("> ".$file);
	my($self)=XML::ValidWriter->new(OUTPUT=>$io,DOCTYPE=>$dtd);
	#my($self)=XML::ValidWriter->new(DOCTYPE=>$dtd);
	bless($self,$clas);
	#Meta::Utils::Output::print("self is [".$self."]\n");
	$self->xmlDecl();
	$self->doctype($elem,$pubi,$dtdx);
	$self->setDataMode(1);
	return($self);
}

sub new_string($$$$$) {
	my($clas,$stri,$dtdx,$elem,$pubi)=@_;
	my($dtd)=XML::Doctype->new();
	$dtd->parse_dtd_file($elem,Meta::Baseline::Aegis::which($dtdx));
	my($io)=IO::String->new($$stri);
	my($self)=XML::ValidWriter->new(OUTPUT=>$io,DOCTYPE=>$dtd);
	#my($self)=XML::ValidWriter->new(DOCTYPE=>$dtd);
	bless($self,$clas);
	#Meta::Utils::Output::print("self is [".$self."]\n");
	$self->xmlDecl();
	$self->doctype($elem,$pubi,$dtdx);
	$self->setDataMode(1);
	return($self);
}

sub end($) {
	my($self)=@_;
	#Meta::Utils::Output::print("self is [".$self."]\n");
	my($io)=$self->getOutput();
	$self->SUPER::end();
	$io->close();
}

sub TEST($) {
	my($context)=@_;
	my($result);
	my($xml)=__PACKAGE__->new_string(\$result,"dtdx/impo/xml/docbookx.dtd","email","-//OASIS//DTD DocBook XML V4.1.2//EN");
	$xml->dataElement("email","foo\@bar.com");
	$xml->end();
	Meta::Utils::Output::print("result is [".$result."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::ValidWriter - extend XML::ValidWriter.

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

	MANIFEST: ValidWriter.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::ValidWriter qw();
	my($object)=Meta::Xml::ValidWriter->new();
	my($result)=$object->method();

=head1 DESCRIPTION

These are some extensions to the standard XML::ValidWriter class.

=head1 FUNCTIONS

	new_file($$$$$)
	new_string($$$$$)
	end($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new_file($$$$$)>

This is a constructor for the Meta::Xml::ValidWriter object.

=item B<new_string($$$$$)>

This is a constructor for the Meta::Xml::ValidWriter object.
This will write into a string you give it.

=item B<end($)>

This method overrides the native end implementation and closes the IO stream too.

=item B<TEST($)>

Test suite for this module.
Currently it just initializes an object and writes some xml.

=back

=head1 SUPER CLASSES

XML::ValidWriter(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more Perl packaging
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV movies and small fixes
	0.05 MV graph visualization
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV teachers project
	0.12 MV md5 issues

=head1 SEE ALSO

IO(3), IO::String(3), Meta::Utils::Output(3), XML::Doctype(3), XML::ValidWriter(3), strict(3)

=head1 TODO

Nothing.

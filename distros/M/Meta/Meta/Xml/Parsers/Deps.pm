#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Deps;

use strict qw(vars refs subs);
use Meta::Xml::Parsers::Base qw();
use Meta::Development::Deps qw();
use Meta::Utils::Output qw();
use Meta::Class::MethodMaker qw();
use URI qw();
use Meta::Baseline::Aegis qw();

our($VERSION,@ISA);
$VERSION="0.19";
@ISA=qw(Meta::Xml::Parsers::Base);

#sbu BEGIN();
#sub new($);
#sub get_root($);
#sub set_root($$);
#sub handle_doctype($$$$$);
#sub handle_externent($$$$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_doctype_prefix",
		-java=>"_do_doctype",
		-java=>"_externent_prefix",
		-java=>"_do_externent",
		-java=>"_deps",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=XML::Parser::Expat->new(ParseParamEnt=>0);
	$self->{ROOT}=defined;
	if(!$self) {
		throw Meta::Error::Simple("couldn't get a parser");
	}
	$self->setHandlers(
		'Doctype'=>\&handle_doctype,
		'ExternEnt'=>\&handle_externent,
	);
	bless($self,$class);
	$self->set_deps(Meta::Development::Deps->new());
	return($self);
}

sub get_root($) {
	my($self)=@_;
	return($self->{ROOT});
}

sub set_root($$) {
	my($self,$val)=@_;
	$self->{ROOT}=$val;
	$self->get_deps()->node_insert($val);
}

sub handle_doctype($$$$$) {
	my($self,$name,$sysid,$pubid,$internal)=@_;
#	Meta::Utils::Output::print("in handle_doctype\n");
#	Meta::Utils::Output::print("name is [".$name."]\n");
#	Meta::Utils::Output::print("sysid is [".$sysid."]\n");
#	Meta::Utils::Output::print("pubid is [".$pubid."]\n");
#	Meta::Utils::Output::print("internal is [".$internal."]\n");
	my($uri)=URI->new($sysid);
	if(!defined($uri->scheme())) {
		if($self->get_do_doctype()) {
			my($name)=$self->get_doctype_prefix().$sysid;
			$self->get_deps()->node_insert($name);
			$self->get_deps()->edge_insert($self->get_root(),$name);
		}
	}
	#this does not work,I don't know why
	#return($self->SUPER::handle_doctype($name,$sysid,$pubid,$internal));
}

sub handle_externent($$$$) {
	my($self,$base,$sysid,$pubid)=@_;
#	Meta::Utils::Output::print("in handle_externent\n");
#	Meta::Utils::Output::print("base is [".$base."]\n");
#	Meta::Utils::Output::print("sysid is [".$sysid."]\n");
#	Meta::Utils::Output::print("pubid is [".$pubid."]\n");
	my($uri)=URI->new($sysid);
	if(!defined($uri->scheme())) {
		if($self->get_do_externent()) {
			my($name)=$self->get_externent_prefix().$sysid;
			$self->get_deps()->node_insert($name);
			$self->get_deps()->edge_insert($self->get_root(),$name);
		}
	}
	return($self->SUPER::handle_externent($base,$sysid,$pubid));
}

sub TEST($) {
	my($context)=@_;
	my($parser)=Meta::Xml::Parsers::Deps->new();
	my($source)="temp/sgml/papers/computing/code_improvement.temp";
	$parser->set_root($source);
	my($file)=Meta::Baseline::Aegis::which($source);
	$parser->parsefile($file);
	my($deps)=$parser->get_deps();
	Meta::Utils::Output::dump($deps);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Deps - dependency analyzer for XML files.

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

	MANIFEST: Deps.pm
	PROJECT: meta
	VERSION: 0.19

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Deps qw();
	my($deps_parser)=Meta::Xml::Parsers::Deps->new();
	$deps_parser->parsefile($file);
	my($deps)=$deps_parser->get_deps();

=head1 DESCRIPTION

This is an expat based parser whose sole purpose is finiding dependencies
for xml files.

=head1 FUNCTIONS

	BEGIN()
	new($)
	get_root($)
	set_root($$)
	handle_doctype($$$$$)
	handle_externent($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap the class and add methods for "externent_prefix" and "doctype_prefix".

=item B<new($)>

This gives you a new object for a parser.

=item B<get_root($)>

This method will retrieve the root node for the dependency object.
This method is not built using Class::MethodMaker since setting
the root involves changing the graph and thus root is not a standard
attribute.

=item B<set_root($$)>

This will set the root node that the deps will be attached to.

=item B<handle_doctype($$$$$)>

This method will handle the document type declarations and will add the
dependency on the dtd to the deps object.

=item B<handle_externent($$$$)>

This method will handle external entities.
Remember that in a Deps parser we do not wish to process the external
entity (if we had access to the graph we would have made sure that
the file existed in the graph but since we dont we just omit it as
dependency).

=item B<TEST($)>

Test suite for this module.
Currently it will just read an sgml file and will print out the deps.

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

	0.00 MV real deps for docbook files
	0.01 MV fix up xml parsers
	0.02 MV spelling and papers
	0.03 MV finish lit database and convert DocBook to SGML
	0.04 MV XML rules
	0.05 MV perl packaging
	0.06 MV perl packaging
	0.07 MV PDMT
	0.08 MV md5 project
	0.09 MV database
	0.10 MV perl module versions in files
	0.11 MV movies and small fixes
	0.12 MV thumbnail user interface
	0.13 MV more thumbnail issues
	0.14 MV website construction
	0.15 MV web site automation
	0.16 MV SEE ALSO section fix
	0.17 MV finish papers
	0.18 MV teachers project
	0.19 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Class::MethodMaker(3), Meta::Development::Deps(3), Meta::Utils::Output(3), Meta::Xml::Parsers::Base(3), URI(3), strict(3)

=head1 TODO

Nothing.

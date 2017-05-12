#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Xml::Xml;

use strict qw(vars refs subs);
use XML::Checker::Parser qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::System qw();
use Meta::Development::Deps qw();
use XML::DOM qw();
use Meta::Xml::Parsers::Deps qw();
use Meta::Utils::Output qw();
use Meta::Utils::Parse::Text qw();
use Meta::Xml::Parsers::Type qw();
use Meta::Xml::Parsers::Checker qw();
use Meta::Utils::Env qw();
use Meta::Utils::File::Patho qw();
use Meta::IO::File qw();

our($VERSION,@ISA);
$VERSION="0.10";
@ISA=qw();

#sub catalog_setup();
#sub get_prefix();
#sub get_search_list($);
#sub setup($);
#sub setup_path();
#sub fail_check($);
#sub check($);
#sub c2deps($);
#sub c2chun($);
#sub chunk($);
#sub odeps($$$$);
#sub resolve_dtd($);
#sub resolve_xml($);
#sub get_type($);
#sub BEGIN();
#sub TEST($);

#__DATA__

our($errors);

sub catalog_setup() {
#	if(Meta::Baseline::Aegis::have_aegis()) {
#		my($path)=Meta::Baseline::Aegis::search_path_list();
#		my($value)=$path->get_catenate(":","dtdx/CATALOG");
#		Meta::Utils::Env::set("XML_CATALOG_FILES",$value);
#	} else {
		Meta::Utils::Env::set("XML_CATALOG_FILES","/local/tools/htdocs/dtdx/CATALOG");
#	}
}

sub get_prefix() {
	return("");
}

sub get_search_list($) {
	my($path)=@_;
	my(@search_path)=split('\:',$path);
	my(@list);
	for(my($i)=0;$i<=$#search_path;$i++) {
		my($curr)=$search_path[$i];
		#Meta::Utils::Output::print("adding [".$curr."]\n");
		#push(@list,$curr);
		#push(@list,$curr."/sgml");
		#push(@list,$curr."/xmlx");
		push(@list,$curr."/dtdx");
		#push(@list,$curr."/dslx");
		#push(@list,$curr."/chun/sgml");
	}
	return(\@list);
}

sub setup($) {
	my($path)=@_;
	my($list)=&get_search_list($path);
	XML::Checker::Parser::set_sgml_search_path(@$list);
}

sub setup_path() {
	my($patho);
#	if(Meta::Baseline::Aegis::have_aegis()) {
#		$patho=Meta::Baseline::Aegis::search_path_object();
#	} else {
	#	$patho=Meta::Utils::File::Patho->new();
	#	$patho->push("/local/tools/htdocs");
#	}
#	$patho->append("/dtdx");
#	my($list)=$patho->list();
#	XML::Checker::Parser::set_sgml_search_path(@$list);
}

sub fail_check($) {
	my($code)=shift;
	XML::Checker::print_error($code,@_);
	$errors++;
}

sub check($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($path)=$buil->get_path();
	&setup($path);
	my($parser)=Meta::Xml::Parsers::Checker->new();
	$errors=0;
	eval {
		local($XML::Checker::FAIL)=\&fail_check;
		$parser->parsefile($srcx);
	};
	if($@) {
		Meta::Utils::Output::print("unknown error [".$@."]\n");
		return(0);
	}
	if($errors>0) {
		return(0);
	} else {
		return(1);
	}
}

sub c2deps($) {
	my($buil)=@_;
	my($parser)=Meta::Xml::Parsers::Deps->new();
	$parser->set_doctype_prefix("dtdx/");
	$parser->set_do_doctype(1);
	$parser->set_externent_prefix(&get_prefix());
	$parser->set_do_externent(1);
	$parser->set_root($buil->get_modu());
	$parser->parsefile($buil->get_srcx());
	return($parser->get_deps());
}

sub c2chun($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($parser)=Meta::Utils::Parse::Text->new();
	$parser->init_file($srcx);
	my($found_doctype)=0;
	my($found_xml)=0;
	my($io)=Meta::IO::File->new_writer($targ);
	while(!$parser->get_over()) {
		my($line)=$parser->get_line();
		if($line=~/^\<\!DOCTYPE/) {
			$found_doctype=1;
		} else {
			if($line=~/^\<\?xml version/) {
				$found_xml=1;
			} else {
				print $io $line."\n";
			}
		}
		$parser->next();
	}
	$parser->fini();
	$io->close();
	if(!$found_doctype) {
		Meta::Utils::Output::print("unable to find DOCTYPE in document\n");
	}
	if(!$found_xml) {
		Meta::Utils::Output::print("unable to find xml version in document\n");
	}
	return($found_doctype && $found_xml);
}

sub chunk($) {
	my($srcx)=@_;
	my($parser)=Meta::Utils::Parse::Text->new();
	$parser->init_file($srcx);
	my($found_doctype)=0;
	my($found_xml)=0;
	my($res)="";
	while(!$parser->get_over()) {
		my($line)=$parser->get_line();
		if($line=~/^\<\!DOCTYPE/) {
			$found_doctype=1;
		} else {
			if($line=~/^\<\?xml version/) {
				$found_xml=1;
			} else {
				$res.=$line."\n";
			}
		}
		$parser->next();
	}
	$parser->fini();
	if(!$found_doctype) {
		Meta::Utils::Output::print("unable to find DOCTYPE in document\n");
	}
	if(!$found_xml) {
		Meta::Utils::Output::print("unable to find xml version in document\n");
	}
	return($res);
}

sub odeps($$$$) {
	my($modu,$srcx,$targ,$path)=@_;
	&setup_path();

	my($graph)=Meta::Development::Deps->new();
	$graph->node_insert($modu);

	my($parser)=XML::DOM::Parser->new();
	my($doc)=$parser->parsefile($srcx);
	if(!defined($doc)) {
		Meta::Utils::Output::print("unable to parse [".$doc."]\n");
		return(undef);
	}
	my($type)=$doc->getDoctype();
	if(defined($type)) {#there is a type to the xml document
		my($system_id)=$type->getSysId();
#		Meta::Utils::Output::print($system_id);
		my($a_system_id)=&resolve_dtd($system_id);
#		Meta::Utils::Output::print($a_system_id);
		$graph->node_insert($a_system_id);
		$graph->edge_insert($modu,$a_system_id);
		my($entities);
		$entities=$type->getEntities();
		for(my($i)=0;$i<$entities->getLength();$i++) {
			my($entity)=$entities->item($i);
			my($system_id)=$entity->getSysId();
#			Meta::Utils::Output::print($system_id);
			my($a_system_id)=&resolve_xml($system_id);
#			Meta::Utils::Output::print($a_system_id);
			$graph->node_insert($a_system_id);
			$graph->edge_insert($modu,$a_system_id);
			if(!defined($system_id)) {
				throw Meta::Error::Simple("no system id");
			}
		}
	}
	return($graph);
}

sub resolve_dtd($) {
	my($id)=@_;
	return("dtdx/".$id);
}

sub resolve_xml($) {
	my($id)=@_;
	return("xmlx/".$id);
}

sub get_type($) {
	my($srcx)=@_;
	my($parser)=Meta::Xml::Parsers::Type->new();
	$parser->parsefile($srcx);
	return($parser->get_result());
}

sub BEGIN() {
	setup_path();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Xml::Xml - help you with xml related tasks.

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

	MANIFEST: Xml.pm
	PROJECT: meta
	VERSION: 0.10

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Xml::Xml qw();
	my($object)=Meta::Lang::Xml::Xml->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class will help you with xml related tasks.
0. checking an xml file for correctness according to dtd.
1. setting up the search path for xml parser to find dtds.
2. extracting dependencies from XML files.
3. resolving dtds and xmls.
4. give you the type (root element) of XML files.
5. setup search path for XML CATALOG files.
6. Be able to strip all from XML file but content.

=head1 FUNCTIONS

	catalog_setup()
	get_prefix()
	get_search_list($)
	setup($)
	setup_path()
	fail_check($)
	check($$$)
	c2deps($)
	c2chun($)
	chunk($)
	odeps($$$$)
	resolve_dtd($)
	resolve_xml($)
	get_type($)
	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<$errors>

This is a package variable used to count the errors (no other elegant way that I
found to count the errors).

=item B<catalog_setup()>

This method will set the XML_CATALOG_FILES envrionment files according to the
Aegis development hierarchy as some XML tools need this variable set to know
where to find XML catalog files.

=item B<get_prefix()>

This method returns the prefix for xml related material in the baseline.

=item B<get_search_list($)>

This method gives you the search list for XML processing.
The input is the original path.

=item B<setup($)>

This method gets a path and sets up the search path according to this path.

=item B<setup_path()>

This method will setup path for validating parsers accoding to the baseline.

=item B<fail_check($)>

This method will be called by the XML::Checker::Parser if there is an error.
We just print the error message and thats it. We dont die!!! (remmember we
dont die in any routine as it is bad practice...).

=item B<check($)>

This method checks an XML file for structure according to a DTD. This is
achieved by using the XML::Checker::Parser class which is a validating parser
to parse the file. The parser will print the errors to STDERR if any are
encountered (which is good for us) and will return the number of errros
encountered via the global varialbe $errors.

=item B<c2deps($)>

This method reads a source xml file and produces a deps object which describes
the dependencies for that file.
This method uses an Expat parser to do it which is quite cheap.

=item B<c2chun($)>

This method receives an XML file and removes the DOCTYPE declarations from it so
it could be included in another SGML file.
This also removes the xml version declaration. This method need to be improved
since it does not really do correct XML parsing but just uses non accurate perl
regexps.

=item B<chunk($)>

Remove the xml declarations from a file and return the result string.

=item B<odeps($$$$)>

This method reads a source xml file and produces a deps object which describes
the dependencies for that file. This method is doing it using a DOM parser
which is quite expensive (it stores the entire docbument in RAM and other
problems...).

=item B<resolve_dtd($)>

This method recevies a system id of a dtd file and resolves it to a physical
file. This method should (potentialy) also check that the dtd is a member
of the project.

=item B<resolve_xml($)>

This method recevies a system id of an xml file and resolves it to a physical
file. This method should (potentialy) also check that the xml is a member
of the project.

=item B<get_type($)>

This method receives a file name of an XML document and returns the type
of the document (the highest element in it).

=item B<BEGIN()>

This block will be executed whenever you use this module and it will setup
the XML search path for you.

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

	0.00 MV more Class method generation
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV move tests into modules
	0.07 MV web site development
	0.08 MV finish papers
	0.09 MV teachers project
	0.10 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Development::Deps(3), Meta::IO::File(3), Meta::Utils::Env(3), Meta::Utils::File::Patho(3), Meta::Utils::Output(3), Meta::Utils::Parse::Text(3), Meta::Utils::System(3), Meta::Xml::Parsers::Checker(3), Meta::Xml::Parsers::Deps(3), Meta::Xml::Parsers::Type(3), XML::Checker::Parser(3), XML::DOM(3), strict(3)

=head1 TODO

-the way im counting errros here is not nice since I'm using a global variable. This could be pretty bad for multi-threading etc... Try to make that nicer and dump the global var. You could see the errors global variable in the vars section. 

-make the setup path (which everybody calls before starting to use this module) part of a BEGIN block (if it is at all needed). Think about it.

-the way I'm cutting full xmls into chunks using perl regexps is not right. Use a real XML parser and emit everything except the stuff I'm removing now.

-c2chun and chunk have same code. Unify it using IO:: objects.

-find all modules who use setup_path and make them stop it. (we have it in our begin block).

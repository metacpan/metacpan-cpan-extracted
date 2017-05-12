#!/bin/echo This is a perl module and should not be run

package Meta::Development::Module;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Lang::Lily::InfoParser qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Dir qw();
use Meta::Xml::Parsers::Dom qw();
use Meta::Baseline::Lang::Temp qw();
use Meta::Utils::Text::Counter qw();
use Meta::Lang::Xml::Xml qw();
use Meta::Xml::Dom qw();
use XML::XPath qw();
use XML::Parser qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.09";
@ISA=qw();

#sub BEGIN();
#sub new_name($$);
#sub get_abs_path($);
#sub get_sgml_name($);
#sub get_temp_sgml_tag($$);
#sub get_basename($);
#sub get_xml_def_name($);
#sub get_lily_filename($);
#sub get_lily_title($);
#sub get_lily_subtitle($);
#sub get_lily_composer($);
#sub get_lily_enteredby($);
#sub get_lily_copyright($);
#sub get_lily_style($);
#sub get_lily_source($);
#sub linkit($$$$);
#sub get_self_link($$);
#sub get_link($$$);
#sub get_2_link($$$$);
#sub get_3_link($$$$$);
#sub get_pgn_games($);
#sub get_xml_num_elems($$);
#sub get_xml_sum_elems($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
	);
	Meta::Class::MethodMaker->print(
		[
			"name",
		]
	);
}

sub new_name($$) {
	my($clas,$name)=@_;
	my($ret)=&new($clas);
	$ret->set_name($name);
	return($ret);
}

sub get_abs_path($) {
	my($self)=@_;
#	if(Meta::Baseline::Aegis::have_aegis()) {
	if(1) {
		return(Meta::Baseline::Aegis::which($self->get_name()));
	} else {
		# FIXME this only deals with apache and is hardcoded
		return("/local/tools/htdocs/".$self->get_name());
	}
}

sub get_sgml_name($) {
	my($self)=@_;
	my($file_name)=$self->get_abs_path();
	my($parser)=Meta::Xml::Parsers::Dom->new();
	my($doc)=$parser->parsefile($file_name);
	my($article)=$doc->getDocumentElement();
	if(!defined($article)) {
		throw Meta::Error::Simple("cant get article");
	}
	my($title);
	$title=$article->getElementsByTagName("title",0);
	if(!defined($title)) {
		throw Meta::Error::Simple("cant get name");
	}
	if($title->getLength()!=1) {
		throw Meta::Error::Simple("bad length");
	}
	my($ret)=$title->[0]->getFirstChild()->getData();
	return($ret);
}

sub get_temp_sgml_tag($$) {
	my($self,$tag)=@_;
	my($self)=@_;
	my($file_name)=$self->get_abs_path();
	my($text)=Meta::Baseline::Lang::Temp::ram_process($self->get_name(),$file_name);
	my($par)=XML::Parser->new();
	if(!defined($par)) {
		throw Meta::Error::Simple("unable to create XML::Parser");
	}
	my($xp)=XML::XPath->new(xml=>$text,parser=>$par);
	my($nodeset)=$xp->find($tag);
	if($nodeset->size()!=1) {
		throw Meta::Error::Simple("found !=1 nodes [".$nodeset->size()."] in module [".$self->get_name()."]");
	}
	return($nodeset->get_node(0)->getChildNode(1)->getValue());
}

sub get_basename($) {
	my($self)=@_;
	my($name)=$self->get_name();
	return(Meta::Utils::Utils::basename($name));
}

sub get_basename($) {
	my($self)=@_;
	my($name)=$self->get_name();
	return(Meta::Utils::Utils::basename($name));
}

sub get_xml_def_name($) {
	my($self)=@_;
	my($file_name)=$self->get_abs_path();
	my($parser)=Meta::Xml::Parsers::Dom->new();
	my($doc)=$parser->parsefile($file_name);
	my($def);
	$def=$doc->getDocumentElement();
	if(!defined($def)) {
		throw Meta::Error::Simple("cant get def");
	}
	my($name);
	$name=$def->getElementsByTagName("name",0);
	if(!defined($name)) {
		throw Meta::Error::Simple("cant get name");
	}
	if($name->getLength()!=1) {
		throw Meta::Error::Simple("bad length");
	}
	my($ret)=$name->[0]->getFirstChild()->getData();
	return($ret);
}

sub get_lily_filename($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_filename());
}

sub get_lily_title($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_title());
}

sub get_lily_subtitle($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_subtitle());
}

sub get_lily_composer($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_composer());
}

sub get_lily_enteredby($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_enteredby());
}

sub get_lily_copyright($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_copyright());
}

sub get_lily_style($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_style());
}

sub get_lily_source($) {
	my($self)=@_;
	my($info)=Meta::Lang::Lily::InfoParser->new();
	$info->parse($self->get_abs_path());
	return($info->get_source());
}

sub linkit($$$$) {
	my($name,$dire,$suff,$modu)=@_;
	my($nname)=$dire."/".Meta::Utils::Utils::remove_suffix($name).".".$suff;
	my($path)=Meta::Utils::File::Dir::get_relative_path($modu,$nname);
	return("<a href=\"".$path."\">".$suff."</a>");
#	return("<a href=\"http://www.veltzer.org/".$dire."/".$nname.".".$suff."\">".$suff."</a>");
}

sub get_self_link($$) {
	my($self,$modu)=@_;
	my($suff)=Meta::Utils::Utils::get_suffix($self->get_name());
	my($path)=Meta::Utils::File::Dir::get_relative_path($modu,$self->get_name());
	return("<a href=\"".$path."\">".$suff."</a>");
#	return($suff."-".$modu);
#	return("<a href=\"http://www.veltzer.org/".$self->get_name()."\">".$suff."</a>");
}

our(%directories)=(
	"tex"=>"texx",
	"ps"=>"psxx",
	"rtf"=>"rtfx",
	"pdf"=>"pdfx",
	"dvi"=>"dvix",
	"midi"=>"midi",
	"temp"=>"temp",
	"sgml"=>"sgml",
	"html"=>"html",
	"txt"=>"txtx",
	"xml"=>"xmlx",
	"chun"=>"chun",
	"lyx"=>"lyxx",
	"info"=>"info",
	"mif"=>"mifx",
	"man"=>"manx",
	"latex"=>"latex",
	"gz"=>"gzxx",
	"ly"=>"lily",
	"dtd"=>"dtdx",
);

sub get_link($$$) {
	my($self,$suff,$modu)=@_;
	if(!exists($directories{$suff})) {
		throw Meta::Error::Simple("unable to find suffix [".$suff."]");
	}
	my($dire)=$directories{$suff};
	return(linkit($self->get_name(),$dire,$suff,$modu));
}

sub get_2_link($$$$) {
	my($self,$suff1,$suff2,$modu)=@_;
	if(!exists($directories{$suff1})) {
		throw Meta::Error::Simple("unable to find suffix [".$suff1."]");
	}
	if(!exists($directories{$suff2})) {
		throw Meta::Error::Simple("unable to find suffix [".$suff2."]");
	}
	my($dire1)=$directories{$suff1};
	my($dire2)=$directories{$suff2};
	my($dire)=$dire2."/".$dire1;
	my($suff);
	if($suff2 eq "gz") {
		$suff=$suff1.".".$suff2;
	} else {
		$suff=$suff2;
	}
	return(linkit($self->get_name(),$dire,$suff,$modu));
}

sub get_3_link($$$$$) {
	my($self,$suff1,$suff2,$suff3,$modu)=@_;
	if(!exists($directories{$suff1})) {
		throw Meta::Error::Simple("unable to find suffix [".$suff1."]");
	}
	if(!exists($directories{$suff2})) {
		throw Meta::Error::Simple("unable to find suffix [".$suff2."]");
	}
	if(!exists($directories{$suff3})) {
		throw Meta::Error::Simple("unable to find suffix [".$suff3."]");
	}
	my($dire1)=$directories{$suff1};
	my($dire2)=$directories{$suff2};
	my($dire3)=$directories{$suff3};
	my($dire)=$dire3."/".$dire2."/".$dire1;
	my($suff);
	if($suff3 eq "gz") {
		$suff=$suff2.".".$suff3;
	} else {
		$suff=$suff3;
	}
	return(linkit($self->get_name(),$dire,$suff,$modu));
}

sub get_pgn_games($) {
	my($self)=@_;
	my($path)=$self->get_abs_path();
	return(Meta::Utils::Text::Counter::count($path,"Event"));
}

sub get_xml_num_elems($$) {
	my($self,$elem)=@_;
	my($file)=$self->get_abs_path();
	my($parser)=Meta::Xml::Dom->new_vali(0);
	my($doc)=$parser->parsefile($file);
	my($elem_number)=$doc->getElementsByTagName($elem)->getLength();
	return($elem_number);
}

sub get_xml_sum_elems($$) {
	my($self,$elem)=@_;
	my($file)=$self->get_abs_path();
	my($parser)=Meta::Xml::Dom->new_vali(0);
	my($doc)=$parser->parsefile($file);
	my($elems);
	my($sum)=0;
	$elems=$doc->getElementsByTagName($elem);
	for(my($i)=0;$i<$elems->getLength();$i++) {
		my($curr)=$elems->[$i];
		$sum+=$curr->getFirstChild()->getData();
	}
	return($sum);
}

sub TEST($) {
	my($context)=@_;
	my($module)=__PACKAGE__->new();
	$module->set_name("temp/sgml/papers/biology/neo_conflict.temp");
	my($releaseinfo)=$module->get_temp_sgml_tag('/article/title');
	Meta::Utils::Output::print("releaseinfo is [".$releaseinfo."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Development::Module - a single development module.

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

	MANIFEST: Module.pm
	PROJECT: meta
	VERSION: 0.09

=head1 SYNOPSIS

	package foo;
	use Meta::Development::Module qw();
	my($object)=Meta::Development::Module->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class serves as an abstractization of a development module.
Each class wanting to deal with development modules must go through
this class. The class provides a module name, revision information and
absolute path to the current file containing the module.

future plans: this class will provide the modules content and the module
itself could be stored inside an RDBMS.

=head1 FUNCTIONS

	BEGIN()
	new_name($$);
	get_abs_path($)
	get_sgml_name($)
	get_temp_sgml_tag($$)
	get_xml_def_name($)
	get_lily_filename($)
	get_lily_title($)
	get_lily_subtitle($)
	get_lily_composer($)
	get_lily_enteredby($)
	get_lily_copyright($)
	get_lily_style($)
	get_lily_source($)
	linkit($$$$)
	get_self_link($$)
	get_link($$$)
	get_2_link($$$$)
	get_3_link($$$$$)
	get_pgn_games($)
	get_xml_num_elems($$)
	get_xml_sum_elems($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Intializer method which sets up accessor methods for the following attributes:
1. name - the name of the module.

=item B<new_name($$)>

Constructor which also accepts a name for the module.

=item B<get_abs_path($)>

This method retrieves the path to the file that containts the current version
of the module.

=item B<get_sgml_name($)>

Retreives the name of the document from an SGML/Docbook document.

=item B<get_temp_sgml_tag($$)>

This method retrieves a specific tag from an SGML file according to
an XPath expression. You have to make sure to create an XPath expression
which returns just a single element.

=item B<get_xml_def_name($)>

This method retrieve the name of the XML/DEF database from the actual
XML file.

=item B<get_lily_filename($)>

This method retrieves the lilypond filename of the current module.

=item B<get_lily_title($)>

This method retrieves the lilypond title of the current module.

=item B<get_lily_subtitle($)>

This method retrieves the lilypond subtitle of the current module.

=item B<get_lily_composer($)>

This method retrieves the lilypond composer of the current module.

=item B<get_lily_enteredby($)>

This method retrieves the lilypond enteredby of the current module.

=item B<get_lily_copyright($)>

This method retrieves the lilypond copyright of the current module.

=item B<get_lily_style($)>

This method retrieves the lilypond style of the current module.

=item B<get_lily_source($)>

This method retrieves the lilypond source of the current module.

=item B<linkit($$$$)>

Generate a general purpose link.

=item B<get_self_link($$)>

This method retrieves a link suitable for html for the current module.

=item B<get_link($$$)>

This method retrieves a link suitable for html for the current modules
transformation to the specified suffix.

=item B<get_2_link($$$$)>

This method retrieves a link suitable for html for the current moduels
2 times transformation to the specified suffix number 1 and then to
the specified suffix number 2.

=item B<get_3_link($$$$$)>

This method retrieves a link suitable for html for the current moduels
3 times transformation to the specified suffix number 1, then to
the specified suffix number 2 and then to the specified suffix number 3.

=item B<get_pgn_games($)>

This method will retrieve how many pgn games are stored in the current
file. The method is just to grep for the "Event" string in the file
and count the appearances.

=item B<get_xml_num_elems($$)>

This method will count how many times a specific element appears in an XML file.

=item B<get_xml_sum_elems($$)>

This method will count the sum of all content in a specific element in an XML file
(under the assumption that it is numeric ofcourse).

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

	0.00 MV web site development
	0.01 MV more web page stuff
	0.02 MV web site automation
	0.03 MV SEE ALSO section fix
	0.04 MV put all tests in modules
	0.05 MV move tests into modules
	0.06 MV web site development
	0.07 MV weblog issues
	0.08 MV more pdmt stuff
	0.09 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Lang::Temp(3), Meta::Class::MethodMaker(3), Meta::Lang::Lily::InfoParser(3), Meta::Lang::Xml::Xml(3), Meta::Utils::File::Dir(3), Meta::Utils::Text::Counter(3), Meta::Utils::Utils(3), Meta::Xml::Dom(3), Meta::Xml::Parsers::Dom(3), XML::Parser(3), XML::XPath(3), strict(3)

=head1 TODO

-make caching of the lilypond parsing information so that I wont have to parse each time again.

-move the linkit routine out of here!!! (where the &%*^?)

-the routine get_sgml_temp_tag returns the tag content without processing. Add text processing option to it (text wrapping etc...).

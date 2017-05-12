#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Temp;

use strict qw(vars refs subs);
use Meta::Baseline::Utils qw();
use Meta::Template qw();
use Meta::Baseline::Aegis qw();
use Meta::Tool::Aegis qw();
use Meta::Utils::Hash qw();
use Meta::Utils::List qw();
use Meta::Development::Module qw();
use Meta::Info::Authors qw();
use Meta::Lang::Tt::Tt qw();
use Meta::Baseline::Cook qw();
use Meta::Utils::Text::Checker qw();
use Meta::Utils::File::File qw();
use Meta::Lang::Xml::Xml qw();

our($VERSION,@ISA);
$VERSION="0.22";
@ISA=qw(Meta::Baseline::Lang);

#sub c2chec($);
#sub c2deps($);
#sub get_vars($);
#sub c2some($);
#sub mac_devfile($);
#sub mac_devfile_rel($);
#sub mac_devfile_abs($);
#sub mac_devlist_reg($);
#sub mac_include_sgml($);
#sub mac_include_xml($);
#sub my_file($$);
#sub ram_process($$);
#sub TEST($);

#__DATA__

our($curr_modu);

sub c2chec($) {
	my($buil)=@_;
	my($resu);
	if($buil->get_modu()=~/^temp\/sgml\//) {
		$resu=Meta::Utils::Text::Checker::length_check($buil->get_srcx(),80);
	} else {
		$resu=1;
	}
	if($resu) {
		Meta::Baseline::Utils::file_emblem($buil->get_targ());
	}
	return($resu);
}

sub c2deps($) {
	my($buil)=@_;
	#Meta::Baseline::Utils::file_emblem($buil->get_targ());
	my($deps)=Meta::Lang::Tt::Tt::c2deps($buil);
	Meta::Baseline::Cook::print_deps($deps,$buil->get_targ());
	return(1);
}

sub get_vars($) {
	my($modu)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($module);
	my($author)=$authors->get_default();
	my($copy)=$author->get_html_copyright();
	my($html_info)=$author->get_html_info();
	my($hist)=Meta::Tool::Aegis::history($modu,$authors);
	my($vars)={
		"docbook_revhistory"=>$hist->docbook_revhistory(),
		"docbook_edition"=>$hist->docbook_edition(),
		"docbook_date"=>$hist->docbook_date(),
		"docbook_copyright"=>$hist->docbook_copyright($author),
		"docbook_author"=>$author->get_docbook_author(),
		"docbook_address"=>$author->get_docbook_address(),
		"docbook_trademarks"=>\&mac_docbook_trademarks,
		"html_last"=>$hist->html_last(),
		"html_copyright"=>"<p><small>".$copy."</small></p>",
		"html_info"=>$html_info,
		"devfile"=>\&mac_devfile,
		"devfile_rel"=>\&mac_devfile_rel,
		"devfile_abs"=>\&mac_devfile_abs,
		"devlist_reg"=>\&mac_devlist_reg,
		"include_sgml"=>\&mac_include_sgml,
		"include_xml"=>\&mac_include_xml,
		"dtd_copyright"=>$hist->dtd_copyright($author),
		"dtd_history"=>$hist->dtd_history(),
		"module"=>$modu,
	};
	$curr_modu=$modu;
	return($vars);
}

sub c2some($) {
	my($buil)=@_;
	my($template)=Meta::Template->new(
		INCLUDE_PATH=>Meta::Baseline::Aegis::search_path(),
		RELATIVE=>1,
		ABSOLUTE=>1,
	);
	my($modu)=$buil->get_modu();
	my($vars)=get_vars($modu);
	# add target of the build for substitution
	$vars->{"target"}=$buil->get_targ();
	$template->process($buil->get_srcx(),$vars,$buil->get_targ());
	return(1);
}

sub mac_docbook_trademarks($) {
	#my($devf)=@_;
	#my($abso)=Meta::Baseline::Aegis::which($devf);
	# now load the trademarks
	# find which are participating in the current document
	#this is a hack for now
	return(&mac_include_sgml("sgml/deve/include/trademarks.sgml"));
}

sub mac_devfile($) {
	my($name)=@_;
	my($module)=Meta::Development::Module->new();
	$module->set_name($name);
	return($module);
}

sub mac_devfile_rel($) {
	my($input)=@_;
	#return($input);
	#return(Meta::Baseline::Aegis::which($input));
	my(@list)=split('/',$curr_modu);
	my($ret)="";
	for(my($i)=0;$i<=$#list;$i++) {
		$ret.="../";
	}
	return($ret.$input);
}

sub mac_devfile_abs($) {
	my($input)=@_;
	return(Meta::Baseline::Aegis::which($input));
}

sub mac_devlist_reg($) {
	my($rege)=@_;
	#my($list)=Meta::Baseline::Aegis::project_files_list(1,1,0);
	#$list=Meta::Utils::List::filter_regexp($list,$rege,1);
	#return($list);
	#Meta::Utils::Output::print("rege is [".$rege."]\n");
	my($set)=Meta::Baseline::Aegis::source_files_set(1,1,0,1,1,0);
	$set=$set->filter_regexp($rege);
	#$hash=Meta::Utils::Hash::filter_regexp($hash,$rege,1);
	#first version - just return the hash
	#return(%$hash);
	#second version - turn hash into a list
	#my($list)=Meta::Utils::Hash::to_list($hash);
	#return($list);
	#third version - return a list of modules
	my(@list);
	for(my($i)=0;$i<$set->size();$i++) {
		my($value)=$set->elem($i);
		my($curr)=Meta::Development::Module->new();
		$curr->set_name($value);
		push(@list,$curr);
	}
	return(\@list);
}

sub mac_include_sgml($) {
	my($file)=@_;
	my($real)=Meta::Baseline::Aegis::which($file);
	#return(Meta::Utils::File::File::load_deve($file));
	my($res)=Meta::Lang::Xml::Xml::chunk($real);
	return($res);
}

sub mac_include_xml($) {
	my($file)=@_;
	my($real)=Meta::Baseline::Aegis::which($file);
	#return(Meta::Utils::File::File::load_deve($file));
	my($res)=Meta::Lang::Xml::Xml::chunk($real);
	return($res);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^temp\/.*\.temp$/) {
		return(1);
	}
	return(0);
}

sub ram_process($$) {
	my($modu,$file)=@_;
	my($template)=Meta::Template->new(
		INCLUDE_PATH=>Meta::Baseline::Aegis::search_path(),
		RELATIVE=>1,
		ABSOLUTE=>1,
	);
	my($vars)=get_vars($modu);
	my($ret);
	$template->process($file,$vars,\$ret);
	return($ret);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Temp - doing Template specific stuff in the baseline.

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

	MANIFEST: Temp.pm
	PROJECT: meta
	VERSION: 0.22

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Temp qw();
	my($resu)=Meta::Baseline::Lang::Temp::env();

=head1 DESCRIPTION

This package contains stuff specific to Templates in the baseline:
0. Checks the template files.
1. Created dependencies for the template files.
2. Converts the template files to docbook documents.

=head1 FUNCTIONS

	c2chec($)
	c2deps($)
	get_vars()
	c2some($)
	mac_devfile($)
	mac_devfile_rel($)
	mac_devfile_abs($)
	mac_devlist_reg($)
	mac_include_sgml($)
	mac_include_xml($)
	my_file($$)
	ram_process($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2chec($)>

This routine verifies template source files.
Currently it does nothing.

=item B<c2deps($)>

This routine will print out dependencies in cook fashion for template sources.
Currently it does nothing.

=item B<get_vars()>

This will get all the variables for Template processing.

=item B<c2some($)>

This routine will convert Template files to DocBook files.
Currently it does nothing.

=item B<mac_devfile($)>

This method will return a development module object according to module name.

=item B<mac_devfile_rel($)>

This method will translate a module name to a relative name (for html relative links).

=item B<mac_devfile_abs($)>

This method will translate a module name to an absolute file name.

=item B<mac_devlist_reg($)>

This method will return all development files who's names match a certain regexp.

=item B<mac_include_sgml($)>

This method will load a development file and will include only it's markup section (no
declaration).

=item B<mac_include_xml($)>

This method will load a development file and will include only it's markup section (no
declaration).

=item B<my_file($$)>

This method will return true if the file received should be handled by this
module.

=item B<ram_process($$)>

This will process a file on disk and will return the result in RAM.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Baseline::Lang(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV Revision in DocBook files stuff
	0.01 MV PDMT stuff
	0.02 MV C++ and temp stuff
	0.03 MV perl packaging
	0.04 MV BuildInfo object change
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV movies and small fixes
	0.09 MV thumbnail user interface
	0.10 MV more thumbnail issues
	0.11 MV md5 project
	0.12 MV website construction
	0.13 MV web site development
	0.14 MV more web page stuff
	0.15 MV web site automation
	0.16 MV SEE ALSO section fix
	0.17 MV bring movie data
	0.18 MV move tests into modules
	0.19 MV weblog issues
	0.20 MV finish papers
	0.21 MV teachers project
	0.22 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Cook(3), Meta::Baseline::Utils(3), Meta::Development::Module(3), Meta::Info::Authors(3), Meta::Lang::Tt::Tt(3), Meta::Lang::Xml::Xml(3), Meta::Template(3), Meta::Tool::Aegis(3), Meta::Utils::File::File(3), Meta::Utils::Hash(3), Meta::Utils::List(3), Meta::Utils::Text::Checker(3), strict(3)

=head1 TODO

-because of the use og global vars here then the moudle is not multi-thread safe.

-add a root variable to the substitutin and a root_rel (relative path to the root).

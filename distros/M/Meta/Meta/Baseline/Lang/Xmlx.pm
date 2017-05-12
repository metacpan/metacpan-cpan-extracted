#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Xmlx;

use strict qw(vars refs subs);
use Meta::Baseline::Lang qw();
use Meta::Baseline::Utils qw();
use Meta::Baseline::Cook qw();
use Meta::Lang::Xml::Xml qw();
use Meta::Tool::Aegis qw();
use Meta::Db::Ops qw();
use Meta::Db::Def qw();
use Meta::Db::Connections qw();
use Meta::Lang::Docb::Params qw();
use Meta::Xml::Writer qw();
use Meta::Utils::Output qw();
use Meta::Xml::Parsers::Links qw();
use Meta::Lang::Perl::Perlpkgs qw();
use Meta::Utils::File::File qw();
use Meta::Archive::Tar qw();
#use Meta::Archive::MyTar qw();
use Meta::Tool::Onsgmls qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Utils::Utils qw();
use Meta::Utils::String qw();
use Meta::Info::Authors qw();
use Meta::Development::Module qw();
use Meta::Xml::LibXML qw();

our($VERSION,@ISA);
$VERSION="0.47";
@ISA=qw(Meta::Baseline::Lang);

#sub c2deps($);
#sub c2chec($);
#sub c2sgml($);
#sub c2dbxx($);
#sub c2targ($);
#sub c2rule($);
#sub c2perl($);
#sub c2chun($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2deps($) {
	my($buil)=@_;
	my($deps)=Meta::Lang::Xml::Xml::c2deps($buil);
	my($type)=Meta::Lang::Xml::Xml::get_type($buil->get_srcx());
	if($type eq "perlpkgs") {#add perl packages deps here
		my($pkgs)=Meta::Lang::Perl::Perlpkgs->new_file($buil->get_srcx());
		$pkgs->add_deps($buil->get_modu(),$deps);
	}
	if($type eq "def") {#add def deps here
		Meta::Db::Def::add_deps($buil->get_modu(),$deps,$buil->get_srcx());
	}
	Meta::Baseline::Cook::print_deps($deps,$buil->get_targ());
	return(1);
}

sub c2chec($) {
	my($buil)=@_;
	my($resu)=1;
	#my($cod0)=Meta::Lang::Xml::Xml::check($buil);
	#if(!$cod0) {
	#	$resu=0;
	#}
	#my($cod1)=Meta::Tool::Onsgmls::dochec($srcx,$path);
	#if(!$cod1) {
	#	$resu=0;
	#}
	my($parser)=Meta::Xml::LibXML->new_aegis();
	$parser->validation(1);
	$parser->pedantic_parser(1);
	$parser->load_ext_dtd(1);
	my($cod2)=$parser->check_file($buil->get_srcx());
	if(!$cod2) {
		$resu=0;
	}
	if($resu) {
		Meta::Baseline::Utils::file_emblem($buil->get_targ());
	}
	return($resu);
}

sub c2sgml($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($type)=Meta::Lang::Xml::Xml::get_type($srcx);
	#Meta::Utils::Output::print("type is [".$type."]\n");
	if($type eq "def") {
		my($obje)=Meta::Db::Def->new_file($srcx);
		open(FILE,"> ".$targ) || throw Meta::Error::Simple("unable to open file [".$targ."]");
		# UNSAFE is bad but cant be helped since Xml::Writer refused to write mixed content
		# elements in a safe mode if DATA_MODE is on and we have to have DATA_MODE on to keep
		# the output readable.
		my($writ)=Meta::Xml::Writer->new(OUTPUT=>*FILE,DATA_INDENT=>1,DATA_MODE=>1,UNSAFE=>1);
		$writ->xmlDecl();
		$writ->comment(Meta::Lang::Docb::Params::get_comment());
		$writ->doctype(
			"section",
			Meta::Lang::Docb::Params::get_public(),
			Meta::Lang::Docb::Params::get_system()
		);
		$writ->startTag("section");
		$writ->startTag("sectioninfo");
		my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
		my($authors)=Meta::Info::Authors->new_modu($module);
		my($revision)=Meta::Tool::Aegis::history($modu,$authors);
		$revision->docbook_revhistory_print($writ);
		$writ->endTag("sectioninfo");
		$obje->printd($writ);
		$writ->endTag("section");
		$writ->end();
		close(FILE) || throw Meta::Error::Simple("unable to close file [".$targ."]");
		return(1);
	}
	if($type eq "connections") {
		Meta::Baseline::Utils::file_emblem($targ);
		return(1);
	}
	if($type eq "dbdata") {
		Meta::Baseline::Utils::file_emblem($targ);
		return(1);
	}
	throw Meta::Error::Simple("what kind of xml type is [".$type."]");
	return(0);
}

sub c2dbxx($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($type)=Meta::Lang::Xml::Xml::get_type($srcx);
	#Meta::Utils::Output::print("type is [".$type."]\n");
	if($type eq "def") {
		my($odef)=Meta::Db::Def->new_file($srcx);
		my($module)=Meta::Development::Module->new_name("xmlx/connections/connections.xml");
		my($cobj)=Meta::Db::Connections->new_modu($module);
		my($scod)=1;
		for(my($i)=0;$i<$cobj->size();$i++) {
			my($ccon)=$cobj->elem($i);
			#Meta::Utils::Output::print("creating database [".$i."]\n");
			my($ccod)=Meta::Db::Ops::create_db($ccon,$odef);
			if(!$ccod) {
				$scod=0;
			}
		}
		if($scod) {
			Meta::Baseline::Utils::file_emblem($targ);
		}
		return($scod);
	}
	if($type eq "connections") {
		Meta::Baseline::Utils::file_emblem($targ);
		return(1);
	}
	if($type eq "dbdata") {
		my($scod)=Meta::Db::Ops::import($srcx);
		if($scod) {
			Meta::Baseline::Utils::file_emblem($targ);
		}
		return($scod);
	}
	throw Meta::Error::Simple("what kind of xml type is [".$type."]");
	return(0);
}

sub c2targ($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($type)=Meta::Lang::Xml::Xml::get_type($srcx);
	if($type eq "links") {
		my($link)=Meta::Xml::Parsers::Links->new();
		$link->parsefile($srcx);
		my($olink)=$link->get_result();
		my($name)=$olink->getx(0)->get_name("name");
		my(@list);
		my($platforms)=$olink->getx(0)->get_platforms();
		for(my($i)=0;$i<$platforms->size();$i++) {
			my($curr)=$platforms->getx($i);
			my($arch)=Meta::Baseline::Arch->new();
			$arch->analyze($curr);
			my($dire)=$arch->get_dire();
			push(@list,"rule/".$dire."/".$name.".rule");
		}
		my($string)="base_xmlx_file_objx_link+=".join(" ",@list).";\n";
		Meta::Utils::File::File::save($targ,$string);
		return(1);
		#for(my($i)=0;$i<=$#list;$i++) {
		#	my($curr)=$list[$i];
		#	print FILE $curr.": ".$modu.";\n";
		#}
	}
	if($type eq "perlpkgs") {
		my($pkgs)=Meta::Lang::Perl::Perlpkgs->new_file($srcx);
		my($string);
		for(my($i)=0;$i<$pkgs->size();$i++) {
			my($curr)=$pkgs->getx($i);
			$string.="base_xmlx_file_objx_perl+=".$curr->get_pack_file_name().";\n";
			$string.=$curr->get_pack_file_name().": ".$modu."\n";
			$string.="\t[base_tool_depx]\n";
			$string.="\tset cascade\n";
			$string.="\thost-binding [base_host_scr]\n";
			$string.="{\n";
			$string.="function base_doit [base_tool] [base_protect [head [need]]] [base_protect [resolve [head [need]]]] [base_protect [targets]] [base_search_path] --type perl --lang xmlx;\n";
			$string.="}\n";
		}
		Meta::Utils::File::File::save($targ,$string);
		return(1);
	}
	throw Meta::Error::Simple("what kind of xml type is [".$type."]");
	return(0);
}

sub c2rule($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	open(FILE,"> ".$targ) || throw Meta::Error::Simple("unable to open file [".$targ."]");
	Meta::Baseline::Utils::cook_emblem_print(*FILE);
	my($link)=Meta::Xml::Parsers::Links->new();
	$link->parsefile($srcx);
	my($olink)=$link->get_result();
	my($arch_o)=Meta::Baseline::Arch->new();
	my(@part)=split('\/',$targ);
	my($dire)=$part[1]."/".$part[2];
	$arch_o->from_dire($dire);

	for(my($j)=0;$j<$olink->size();$j++) {
		my($curr_link)=$olink->getx($j);
		my($name)=$curr_link->get_name();
		my($objs)=$curr_link->get_objects();
		my($libs)=$curr_link->get_libraries();
		my($elibs)=$curr_link->get_elibraries();

		my($type)=$arch_o->get_flagset_primary();
		if($type eq "dll") {
			$name="lib".$name.".so";
		}
		if($type eq "lib") {
			$name=$name.".a";
		}
		if($type eq "bin") {
			$name=$name.".bin";
		}
		$dire=$arch_o->get_dire();
		my($arch)=$arch_o->get_string();

		$arch_o->set_flagset_primary("obj");
		my($cdir)=$arch_o->get_dire();

		my(@list);
		for(my($i)=0;$i<$objs->size();$i++) {
			my($curr)=$objs->getx($i);
			push(@list,$cdir."/".$curr.".o");
		}
		my($acti)=join(" ",@list);

		$arch_o->set_flagset_primary("dll");
		$cdir=$arch_o->get_dire();

		my(@llis);
		for(my($i)=0;$i<$libs->size();$i++) {
			my($curr)=$libs->getx($i);
			$curr="lib".$curr.".so";
			push(@llis,$cdir."/".$curr);
		}
		my($lact)=join(" ",@llis);

		my(@elis);
		for(my($i)=0;$i<$elibs->size();$i++) {
			my($curr)=$elibs->getx($i);
			push(@elis,$curr);
		}
		my($ejoi)=join(" ",@elis);

		print FILE "proc=".$arch.";\n";
		print FILE "trg0=".$dire."/".$name.";\n";
		print FILE "src0=".$acti.";\n";
		print FILE "src1=".$lact.";\n";
		print FILE "prm0=".$ejoi.";\n";
		print FILE "prm1="."".";\n";
	}
	close(FILE) || throw Meta::Error::Simple("unable to close file [".$targ."]");
	return(1);
}

sub c2perl($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($type)=Meta::Lang::Xml::Xml::get_type($srcx);
	if($type eq "perlpkgs") {
		my($pkgs)=Meta::Lang::Perl::Perlpkgs->new_file($srcx);
		#my($archive)=Meta::Archive::MyTar->new();
		my($archive)=Meta::Archive::Tar->new();
		$archive->set_type("gzip");
		my($pkg)=$pkgs->getx(0);
		$archive->set_uname($pkg->get_uname());
		$archive->set_use_uname(1);
		$archive->set_gname($pkg->get_gname());
		$archive->set_use_gname(1);
		my($ext_modules)={};
		my($modules)=$pkg->get_modules_dep_list(1,1);
		$modules->sort(\&Meta::Utils::String::compare);
		for(my($i)=0;$i<$modules->size();$i++) {
			my($curr)=$modules->elem($i);
			if(Meta::Lang::Perl::Deps::is_internal($curr)) {
				my($name)=$pkg->get_pack()."/".Meta::Lang::Perl::Perl::remove_prefix($curr);
				#my($name)=$pkg->get_pack()."/".$curr;
				$archive->add_deve($name,$curr);
			} else {
				$ext_modules->{$curr}=defined;
			}
		}
		my($scripts)=$pkg->get_scripts_dep_list(1,1);
		$scripts->sort(\&Meta::Utils::String::compare);
		for(my($i)=0;$i<$scripts->size();$i++) {
			my($curr)=$scripts->elem($i);
			if(Meta::Lang::Perl::Deps::is_internal($curr)) {
				my($name)=$pkg->get_pack()."/".Meta::Lang::Perl::Perl::remove_prefix($curr);
				#my($name)=$pkg->get_pack()."/".$curr;
				$archive->add_deve($name,$curr);
			} else {
				$ext_modules->{$curr}=defined;
			}
		}
		my($tests)=$pkg->get_tests_dep_list(1,1);
		$tests->sort(\&Meta::Utils::String::compare);
		for(my($i)=0;$i<$tests->size();$i++) {
			my($curr)=$tests->elem($i);
			if(Meta::Lang::Perl::Deps::is_internal($curr)) {
				my($name)=$pkg->get_pack()."/".Meta::Lang::Perl::Perl::remove_prefix($curr);
				#my($name)=$pkg->get_pack()."/".$curr;
				$archive->add_deve($name,$curr);
			} else {
				$ext_modules->{$curr}=defined;
			}
		}
		my($files)=$pkg->get_files();
		#sort these files according to target
		for(my($i)=0;$i<$files->size();$i++) {
			my($curr)=$files->getx($i)->get_source();
			$archive->add_deve($pkg->get_pack()."/".$files->getx($i)->get_target(),$curr);
		}
		#EXE_FILES string creation
		my($exe_string);
		my($exe_files_list)=$pkg->get_scripts();
		for(my($i)=0;$i<$exe_files_list->size();$i++) {
			my($curr)=$exe_files_list->getx($i)->get_source();
			#Meta::Utils::Output::print("curr is [".$curr."]\n");
			my($name)=Meta::Lang::Perl::Perl::remove_prefix($curr);
			$exe_string.="\t\t'".$name."',\n";
		}
		#external modules string.
		my($ext_string);
		while(my($key,$val)=each(%$ext_modules)) {
			my($version)=Meta::Lang::Perl::Perl::get_version_mm_unix($key);
			my($module)=Meta::Lang::Perl::Deps::extfile_to_module($key);
			$ext_string.="\t\t'".$module."',".$version.",\n";
		}
		#add Makefile.PL
		my($string);
		$string.="use ExtUtils::MakeMaker;\n";
		$string.="WriteMakefile(\n";
		$string.="\t'NAME'=>'".$pkg->get_name()."',\n";
		$string.="\t'VERSION'=>'".$pkg->get_version()."',\n";
		$string.="\t'ABSTRACT'=>'".$pkg->get_description()."',\n";
		$string.="\t'AUTHOR'=>'".$pkg->get_author()->get_perl_makefile()."',\n";
		$string.="\t'PREREQ_PM'=>"."{\n".$ext_string."\t}".",\n";
		$string.="\t'EXE_FILES'=>"."[\n".$exe_string."\t]".",\n";
		$string.=");\n";
		$archive->add_data($pkg->get_pack()."/Makefile.PL",$string);
		#add README from the description in the perlpkg XML file
		$archive->add_data($pkg->get_pack()."/README",$pkg->get_longdescription());
		#add COPYRIGHT according to author of the package
		$archive->add_data($pkg->get_pack()."/COPYRIGHT",$pkg->get_author()->get_perl_copyright());
		#add MANIFEST
		my(@list)=$archive->list_files();
		for(my($i)=0;$i<=$#list;$i++) {
			$list[$i]=Meta::Utils::Utils::minus($list[$i],$pkg->get_pack()."/");
		}
		my($mani)=join("\n",@list,"MANIFEST");
		$archive->add_data($pkg->get_pack()."/MANIFEST",$mani);
		#write the archive
		$archive->write($targ);
		return(1);
	}
	throw Meta::Error::Simple("what kind of xml type is [".$type."]");
	return(0);
}

sub c2chun($) {
	my($buil)=@_;
	return(Meta::Lang::Xml::Xml::c2chun($buil));
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^xmlx\/.*\.xml$/) {
		return(1);
	}
	return(0);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Xmlx - language for XML files.

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

	MANIFEST: Xmlx.pm
	PROJECT: meta
	VERSION: 0.47

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Xmlx qw();
	my($resu)=Meta::Baseline::Lang::Xmlx::env();

=head1 DESCRIPTION

This package contains stuff specific to Xmlx in the baseline.
This package knows how to validate xml files and find xml dependencies.

=head1 FUNCTIONS

	c2deps($)
	c2chec($)
	c2sgml($)
	c2dbxx($)
	c2targ($)
	c2rule($)
	c2perl($)
	c2chun($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($)>

This method will create a cook type dependency file for the source xml in
question. It will do this using the xml language module.

=item B<c2chec($)>

This method will run various verifications on the xml source.
It will do so using the Lang::Xml module.

=item B<c2sgml($)>

This method will convert the source xml to docbook format according
to the type of document the xml is.

=item B<c2dbxx($)>

This method will convert the source xml to database stamp -
meaning it will do work on the database server according to
the xml type.

=item B<c2targ($)>

This method converts a link file to targets file.

=item B<c2rule($)>

This method converts a link file to rule file.

=item B<c2perl($)>

This method will create perl packages.

=item B<c2chun($)>

This method will xml chunks (no DTD information) from xml files.

=item B<my_file($$)>

This method will return true if the file received should be handled by this
module.

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

	0.00 MV better general cook schemes
	0.01 MV revision for perl files and better sanity checks
	0.02 MV languages.pl test online
	0.03 MV good xml support
	0.04 MV real deps for docbook files
	0.05 MV more on data sets
	0.06 MV move def to xml directory
	0.07 MV automatic data sets
	0.08 MV html site update
	0.09 MV fix up cook files
	0.10 MV Revision in DocBook files stuff
	0.11 MV PDMT stuff
	0.12 MV finish lit database and convert DocBook to SGML
	0.13 MV XML rules
	0.14 MV perl packaging
	0.15 MV more perl packaging
	0.16 MV perl packaging
	0.17 MV BuildInfo object change
	0.18 MV more perl packaging
	0.19 MV perl packaging again
	0.20 MV perl packaging again
	0.21 MV more Perl packaging
	0.22 MV validate writing
	0.23 MV XSLT, website etc
	0.24 MV more personal databases
	0.25 MV xml encoding
	0.26 MV data sets
	0.27 MV PDMT
	0.28 MV some chess work
	0.29 MV fix database problems
	0.30 MV more database issues
	0.31 MV md5 project
	0.32 MV database
	0.33 MV perl module versions in files
	0.34 MV movies and small fixes
	0.35 MV more Class method generation
	0.36 MV thumbnail user interface
	0.37 MV more thumbnail issues
	0.38 MV website construction
	0.39 MV web site automation
	0.40 MV SEE ALSO section fix
	0.41 MV move tests to modules
	0.42 MV bring movie data
	0.43 MV move tests into modules
	0.44 MV weblog issues
	0.45 MV finish papers
	0.46 MV teachers project
	0.47 MV md5 issues

=head1 SEE ALSO

Meta::Archive::Tar(3), Meta::Baseline::Cook(3), Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), Meta::Db::Connections(3), Meta::Db::Def(3), Meta::Db::Ops(3), Meta::Development::Module(3), Meta::Info::Authors(3), Meta::Lang::Docb::Params(3), Meta::Lang::Perl::Perl(3), Meta::Lang::Perl::Perlpkgs(3), Meta::Lang::Xml::Xml(3), Meta::Tool::Aegis(3), Meta::Tool::Onsgmls(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), Meta::Utils::String(3), Meta::Utils::Utils(3), Meta::Xml::LibXML(3), Meta::Xml::Parsers::Links(3), Meta::Xml::Writer(3), strict(3)

=head1 TODO

-fix the 2targ routine to take into account many link targets.

-fix the 2rule routine to not use the target as infomation about what arch that is.

-get the MANIFEST creation out of here and into somewhere more general (the tar class ?)

-don't put the INSTALL,COPYRIGHT,LICENSE in package generation here since then there is no dependency working here (if the LICENSE gets updated the package doesnt get rebuilt...)

#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Switch;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();
use Meta::Utils::System qw();
use Meta::Baseline::Lang::Aspe qw();
use Meta::Baseline::Lang::Temp qw();
use Meta::Baseline::Lang::Ccxx qw();
use Meta::Baseline::Lang::Cxxx qw();
use Meta::Baseline::Lang::Sgml qw();
use Meta::Baseline::Lang::Java qw();
use Meta::Baseline::Lang::Lily qw();
use Meta::Baseline::Lang::Perl qw();
use Meta::Baseline::Lang::Pyth qw();
use Meta::Baseline::Lang::Rule qw();
use Meta::Baseline::Lang::Txtx qw();
use Meta::Baseline::Lang::Data qw();
use Meta::Baseline::Lang::Rcxx qw();
use Meta::Baseline::Lang::Patc qw();
use Meta::Baseline::Lang::Ascx qw();
use Meta::Baseline::Lang::Html qw();
use Meta::Baseline::Lang::Cssx qw();
use Meta::Baseline::Lang::Dirx qw();
use Meta::Baseline::Lang::Cook qw();
use Meta::Baseline::Lang::Aegi qw();
use Meta::Baseline::Lang::Xmlx qw();
use Meta::Baseline::Lang::Xslt qw();
use Meta::Baseline::Lang::Pngx qw();
use Meta::Baseline::Lang::Pgnx qw();
use Meta::Baseline::Lang::Jpgx qw();
use Meta::Baseline::Lang::Epsx qw();
use Meta::Baseline::Lang::Awkx qw();
use Meta::Baseline::Lang::Conf qw();
use Meta::Baseline::Lang::Targ qw();
use Meta::Baseline::Lang::Texx qw();
use Meta::Baseline::Lang::Deps qw();
use Meta::Baseline::Lang::Chec qw();
use Meta::Baseline::Lang::Clas qw();
use Meta::Baseline::Lang::Dvix qw();
use Meta::Baseline::Lang::Chun qw();
use Meta::Baseline::Lang::Objs qw();
use Meta::Baseline::Lang::Psxx qw();
use Meta::Baseline::Lang::Info qw();
use Meta::Baseline::Lang::Rtfx qw();
use Meta::Baseline::Lang::Mifx qw();
use Meta::Baseline::Lang::Midi qw();
use Meta::Baseline::Lang::Bins qw();
use Meta::Baseline::Lang::Dlls qw();
use Meta::Baseline::Lang::Libs qw();
use Meta::Baseline::Lang::Pyob qw();
use Meta::Baseline::Lang::Dtdx qw();
use Meta::Baseline::Lang::Swig qw();
use Meta::Baseline::Lang::Gzxx qw();
use Meta::Baseline::Lang::Pack qw();
use Meta::Baseline::Lang::Dslx qw();
use Meta::Baseline::Lang::Pdfx qw();
use Meta::Baseline::Lang::Dbxx qw();
use Meta::Baseline::Lang::Manx qw();
use Meta::Baseline::Lang::Nrfx qw();
use Meta::Baseline::Lang::Bdbx qw();
use Meta::Baseline::Lang::Late qw();
use Meta::Baseline::Lang::Lyxx qw();
use Meta::Info::Enum qw();
use Meta::Utils::Output qw();
use Meta::Pdmt::BuildInfo qw();
use Meta::Tool::Gzip qw();
use Meta::Tool::Ps2Pdf qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.57";
@ISA=qw();

#sub get_count($);
#sub get_own($);
#sub get_module($);
#sub get_type_enum();
#sub get_lang_enum();
#sub run_module($$$$$$);
#sub TEST($);

my($arra);

BEGIN {
	$arra=Meta::Ds::Array->new();
	$arra->push("Meta::Baseline::Lang::Aspe");
	$arra->push("Meta::Baseline::Lang::Temp");
	$arra->push("Meta::Baseline::Lang::Ccxx");
	$arra->push("Meta::Baseline::Lang::Cxxx");
	$arra->push("Meta::Baseline::Lang::Sgml");
	$arra->push("Meta::Baseline::Lang::Java");
	$arra->push("Meta::Baseline::Lang::Lily");
	$arra->push("Meta::Baseline::Lang::Perl");
	$arra->push("Meta::Baseline::Lang::Pyth");
	$arra->push("Meta::Baseline::Lang::Rule");
	$arra->push("Meta::Baseline::Lang::Txtx");
	$arra->push("Meta::Baseline::Lang::Data");
	$arra->push("Meta::Baseline::Lang::Rcxx");
	$arra->push("Meta::Baseline::Lang::Patc");
	$arra->push("Meta::Baseline::Lang::Ascx");
	$arra->push("Meta::Baseline::Lang::Html");
	$arra->push("Meta::Baseline::Lang::Cssx");
	$arra->push("Meta::Baseline::Lang::Dirx");
	$arra->push("Meta::Baseline::Lang::Cook");
	$arra->push("Meta::Baseline::Lang::Aegi");
	$arra->push("Meta::Baseline::Lang::Xmlx");
	$arra->push("Meta::Baseline::Lang::Xslt");
	$arra->push("Meta::Baseline::Lang::Pngx");
	$arra->push("Meta::Baseline::Lang::Pgnx");
	$arra->push("Meta::Baseline::Lang::Jpgx");
	$arra->push("Meta::Baseline::Lang::Epsx");
	$arra->push("Meta::Baseline::Lang::Awkx");
	$arra->push("Meta::Baseline::Lang::Conf");
	$arra->push("Meta::Baseline::Lang::Targ");
	$arra->push("Meta::Baseline::Lang::Texx");
	$arra->push("Meta::Baseline::Lang::Deps");
	$arra->push("Meta::Baseline::Lang::Chec");
	$arra->push("Meta::Baseline::Lang::Clas");
	$arra->push("Meta::Baseline::Lang::Dvix");
	$arra->push("Meta::Baseline::Lang::Chun");
	$arra->push("Meta::Baseline::Lang::Objs");
	$arra->push("Meta::Baseline::Lang::Psxx");
	$arra->push("Meta::Baseline::Lang::Info");
	$arra->push("Meta::Baseline::Lang::Rtfx");
	$arra->push("Meta::Baseline::Lang::Mifx");
	$arra->push("Meta::Baseline::Lang::Midi");
	$arra->push("Meta::Baseline::Lang::Bins");
	$arra->push("Meta::Baseline::Lang::Dlls");
	$arra->push("Meta::Baseline::Lang::Libs");
	$arra->push("Meta::Baseline::Lang::Pyob");
	$arra->push("Meta::Baseline::Lang::Dtdx");
	$arra->push("Meta::Baseline::Lang::Swig");
	$arra->push("Meta::Baseline::Lang::Gzxx");
	$arra->push("Meta::Baseline::Lang::Pack");
	$arra->push("Meta::Baseline::Lang::Dslx");
	$arra->push("Meta::Baseline::Lang::Pdfx");
	$arra->push("Meta::Baseline::Lang::Dbxx");
	$arra->push("Meta::Baseline::Lang::Manx");
	$arra->push("Meta::Baseline::Lang::Nrfx");
	$arra->push("Meta::Baseline::Lang::Bdbx");
	$arra->push("Meta::Baseline::Lang::Late");
	$arra->push("Meta::Baseline::Lang::Lyxx");
}

#__DATA__

sub get_count($) {
	my($modu)=@_;
#	Meta::Utils::Output::print("arra is [".$Meta::Baseline::Switch::arra."]\n");
	my($count)=0;
	for(my($i)=0;$i<$arra->size();$i++) {
		my($curr)=$arra->getx($i);
		if($curr->my_file($modu)) {
			$count++;
		}
	}
	return($count);
}

sub get_own($) {
	my($modu)=@_;
#	Meta::Utils::Output::print("arra is [".$Meta::Baseline::Switch::arra."]\n");
	my(@arra);
	for(my($i)=0;$i<$arra->size();$i++) {
		my($curr)=$arra->getx($i);
		if($curr->my_file($modu)) {
			push(@arra,$curr);
		}
	}
	return(\@arra);
}

sub get_module($) {
	my($modu)=@_;
#	Meta::Utils::Output::print("arra is [".$Meta::Baseline::Switch::arra."]\n");
	for(my($i)=0;$i<$arra->size();$i++) {
		my($curr)=$arra->getx($i);
		if($curr->my_file($modu)) {
			return($curr);
		}
	}
	throw Meta::Error::Simple("havent found module for [".$modu."]");
	return(undef);
}

sub get_type_enum() {
	my($enum)=Meta::Info::Enum->new();
	$enum->insert("aspe","aspe");
	$enum->insert("temp","temp");
	$enum->insert("ccxx","ccxx");
	$enum->insert("cxxx","cxxx");
	$enum->insert("sgml","sgml");
	$enum->insert("chun","chun");
	$enum->insert("java","java");
	$enum->insert("lily","lily");
	$enum->insert("perl","perl");
	$enum->insert("pyth","pyth");
	$enum->insert("rule","rule");
	$enum->insert("txtx","txtx");
	$enum->insert("data","data");
	$enum->insert("rcxx","rcxx");
	$enum->insert("patc","patc");
	$enum->insert("ascx","ascx");
	$enum->insert("html","html");
	$enum->insert("cssx","cssx");
	$enum->insert("dirx","dirx");
	$enum->insert("cook","cook");
	$enum->insert("aegi","aegi");
	$enum->insert("xmlx","xmlx");
	$enum->insert("xslt","xslt");
	$enum->insert("pngx","pngx");
	$enum->insert("jpgx","jpgx");
	$enum->insert("epsx","epsx");
	$enum->insert("awkx","awkx");
	$enum->insert("conf","conf");
	$enum->insert("targ","targ");
	$enum->insert("texx","texx");
	$enum->insert("deps","deps");
	$enum->insert("chec","chec");
	$enum->insert("clas","clas");
	$enum->insert("dvix","dvix");
	$enum->insert("chun","chun");
	$enum->insert("objs","objs");
	$enum->insert("psxx","psxx");
	$enum->insert("info","info");
	$enum->insert("rtfx","rtfx");
	$enum->insert("mifx","mifx");
	$enum->insert("midi","midi");
	$enum->insert("bins","bins");
	$enum->insert("dlls","dlls");
	$enum->insert("libs","libs");
	$enum->insert("pyob","pyob");
	$enum->insert("dtdx","dtdx");
	$enum->insert("swig","swig");
	$enum->insert("gzxx","gzxx");
	$enum->insert("pack","pack");
	$enum->insert("dslx","dslx");
	$enum->insert("pdfx","pdfx");
	$enum->insert("dbxx","dbxx");
	$enum->insert("manx","manx");
	$enum->insert("nrfx","nrfx");
	$enum->insert("bdbx","bdbx");
	$enum->insert("late","late");
	$enum->insert("lyxx","lyxx");
	$enum->set_default(undef);
	return($enum);
}

sub get_lang_enum() {
	return(&get_type_enum());
}

sub run_module($$$$$$) {
	my($modu,$srcx,$targ,$path,$type,$lang)=@_;
	my($buil)=Meta::Pdmt::BuildInfo->new();
	$buil->set_modu($modu);
	$buil->set_srcx($srcx);
	$buil->set_targ($targ);
	$buil->set_path($path);
	if(0) {
		Meta::Utils::Output::print("modu is [".$modu."]\n");
		Meta::Utils::Output::print("srcx is [".$srcx."]\n");
		Meta::Utils::Output::print("targ is [".$targ."]\n");
		Meta::Utils::Output::print("path is [".$path."]\n");
		Meta::Utils::Output::print("type is [".$type."]\n");
		Meta::Utils::Output::print("lang is [".$lang."]\n");
	}
	my($scod);
	my($foun)=0;
	if($lang eq "aspe") {
	}
	if($lang eq "temp") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Temp::c2deps($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Temp::c2chec($buil);
			$foun=1;
		}
		if($type eq "sgml") {
			$scod=Meta::Baseline::Lang::Temp::c2some($buil);
			$foun=1;
		}
		if($type eq "html") {
			$scod=Meta::Baseline::Lang::Temp::c2some($buil);
			$foun=1;
		}
		if($type eq "xmlx") {
			$scod=Meta::Baseline::Lang::Temp::c2some($buil);
			$foun=1;
		}
		if($type eq "dtdx") {
			$scod=Meta::Baseline::Lang::Temp::c2some($buil);
			$foun=1;
		}
	}
	if($lang eq "ccxx") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Ccxx::c2deps($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Ccxx::c2chec($buil);
			$foun=1;
		}
		if($type eq "html") {
			$scod=Meta::Baseline::Lang::Ccxx::c2html($buil);
			$foun=1;
		}
		if($type eq "objs") {
			$scod=Meta::Baseline::Lang::Ccxx::c2objs($buil);
			$foun=1;
		}
	}
	if($lang eq "cxxx") {
	}
	if($lang eq "sgml") {
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Sgml::c2chec($buil);
			$foun=1;
		}
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Sgml::c2deps($buil);
			$foun=1;
		}
		if($type eq "texx") {
			$scod=Meta::Baseline::Lang::Sgml::c2texx($buil);
			$foun=1;
		}
		if($type eq "dvix") {
			$scod=Meta::Baseline::Lang::Sgml::c2dvix($buil);
			$foun=1;
		}
		if($type eq "psxx") {
			$scod=Meta::Baseline::Lang::Sgml::c2psxx($buil);
			$foun=1;
		}
		if($type eq "txtx") {
			$scod=Meta::Baseline::Lang::Sgml::c2txtx($buil);
			$foun=1;
		}
		if($type eq "html") {
			$scod=Meta::Baseline::Lang::Sgml::c2html($buil);
			$foun=1;
		}
		if($type eq "rtfx") {
			$scod=Meta::Baseline::Lang::Sgml::c2rtfx($buil);
			$foun=1;
		}
		if($type eq "manx") {
			$scod=Meta::Baseline::Lang::Sgml::c2manx($buil);
			$foun=1;
		}
		if($type eq "mifx") {
			$scod=Meta::Baseline::Lang::Sgml::c2mifx($buil);
			$foun=1;
		}
		if($type eq "info") {
			$scod=Meta::Baseline::Lang::Sgml::c2info($buil);
			$foun=1;
		}
		if($type eq "pdfx") {
			$scod=Meta::Baseline::Lang::Sgml::c2pdfx($buil);
			$foun=1;
		}
		if($type eq "chun") {
			$scod=Meta::Baseline::Lang::Sgml::c2chun($buil);
			$foun=1;
		}
		if($type eq "xmlx") {
			$scod=Meta::Baseline::Lang::Sgml::c2xmlx($buil);
			$foun=1;
		}
		if($type eq "late") {
			$scod=Meta::Baseline::Lang::Sgml::c2late($buil);
			$foun=1;
		}
		if($type eq "lyxx") {
			$scod=Meta::Baseline::Lang::Sgml::c2lyxx($buil);
			$foun=1;
		}
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "chun") {
	}
	if($lang eq "java") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Java::c2deps($buil);
			$foun=1;
		}
		if($type eq "clas") {
			$scod=Meta::Baseline::Lang::Java::c2clas($buil);
			$foun=1;
		}
		if($type eq "html") {
			$scod=Meta::Baseline::Lang::Java::c2html($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Java::c2chec($buil);
			$foun=1;
		}
	}
	if($lang eq "lily") {
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Lily::c2chec($buil);
			$foun=1;
		}
		if($type eq "midi") {
			$scod=Meta::Baseline::Lang::Lily::c2midi($buil);
			$foun=1;
		}
		if($type eq "texx") {
			$scod=Meta::Baseline::Lang::Lily::c2texx($buil);
			$foun=1;
		}
		if($type eq "psxx") {
			$scod=Meta::Baseline::Lang::Lily::c2psxx($buil);
			$foun=1;
		}
		if($type eq "dvix") {
			$scod=Meta::Baseline::Lang::Lily::c2dvix($buil);
			$foun=1;
		}
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Lily::c2deps($buil);
			$foun=1;
		}
	}
	if($lang eq "perl") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Perl::c2deps($buil);
			$foun=1;
		}
		if($type eq "objs") {
			$scod=Meta::Baseline::Lang::Perl::c2objs($buil);
			$foun=1;
		}
		if($type eq "manx") {
			$scod=Meta::Baseline::Lang::Perl::c2manx($buil);
			$foun=1;
		}
		if($type eq "nrfx") {
			$scod=Meta::Baseline::Lang::Perl::c2nrfx($buil);
			$foun=1;
		}
		if($type eq "html") {
			$scod=Meta::Baseline::Lang::Perl::c2html($buil);
			$foun=1;
		}
		if($type eq "late") {
			$scod=Meta::Baseline::Lang::Perl::c2late($buil);
			$foun=1;
		}
		if($type eq "txtx") {
			$scod=Meta::Baseline::Lang::Perl::c2txtx($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Perl::c2chec($buil);
			$foun=1;
		}
	}
	if($lang eq "pyth") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Pyth::c2deps($buil);
			$foun=1;
		}
		if($type eq "pyob") {
			$scod=Meta::Baseline::Lang::Pyth::c2objs($buil);
			$foun=1;
		}
		if($type eq "html") {
			$scod=Meta::Baseline::Lang::Pyth::c2html($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Pyth::c2chec($buil);
			$foun=1;
		}
	}
	if($lang eq "rule") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Rule::c2deps($buil);
			$foun=1;
		}
	}
	if($lang eq "txtx") {
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Txtx::c2chec($buil);
			$foun=1;
		}
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "data") {
	}
	if($lang eq "rcxx") {
	}
	if($lang eq "patc") {
	}
	if($lang eq "ascx") {
	}
	if($lang eq "html") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Html::c2deps($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Html::c2chec($buil);
			$foun=1;
		}
	}
	if($lang eq "cssx") {
	}
	if($lang eq "dirx") {
	}
	if($lang eq "cook") {
	}
	if($lang eq "aegi") {
	}
	if($lang eq "xmlx") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Xmlx::c2deps($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Xmlx::c2chec($buil);
			$foun=1;
		}
		if($type eq "chun") {
			$scod=Meta::Baseline::Lang::Xmlx::c2chun($buil);
			$foun=1;
		}
		if($type eq "sgml") {
			$scod=Meta::Baseline::Lang::Xmlx::c2sgml($buil);
			$foun=1;
		}
		if($type eq "dbxx") {
			$scod=Meta::Baseline::Lang::Xmlx::c2dbxx($buil);
			$foun=1;
		}
		if($type eq "targ") {
			$scod=Meta::Baseline::Lang::Xmlx::c2targ($buil);
			$foun=1;
		}
		if($type eq "rule") {
			$scod=Meta::Baseline::Lang::Xmlx::c2rule($buil);
			$foun=1;
		}
		if($type eq "perl") {
			$scod=Meta::Baseline::Lang::Xmlx::c2perl($buil);
			$foun=1;
		}
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "xslt") {
	}
	if($lang eq "pngx") {
	}
	if($lang eq "jpgx") {
	}
	if($lang eq "epsx") {
	}
	if($lang eq "awkx") {
	}
	if($lang eq "conf") {
	}
	if($lang eq "targ") {
	}
	if($lang eq "texx") {
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Texx::c2chec($buil);
			$foun=1;
		}
		if($type eq "psxx") {
			$scod=Meta::Baseline::Lang::Texx::c2psxx($buil);
			$foun=1;
		}
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "deps") {
	}
	if($lang eq "chec") {
	}
	if($lang eq "clas") {
	}
	if($lang eq "dvix") {
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Dvix::c2chec($buil);
			$foun=1;
		}
		if($type eq "psxx") {
			$scod=Meta::Baseline::Lang::Dvix::c2psxx($buil);
			$foun=1;
		}
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "chun") {
	}
	if($lang eq "objs") {
	}
	if($lang eq "psxx") {
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
		if($type eq "pdfx") {
			$scod=Meta::Tool::Ps2Pdf::c2pdfx($buil);
			$foun=1;
		}
	}
	if($lang eq "info") {
	}
	if($lang eq "rtfx") {
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "mifx") {
	}
	if($lang eq "midi") {
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "bins") {
	}
	if($lang eq "dlls") {
	}
	if($lang eq "libs") {
	}
	if($lang eq "pyob") {
	}
	if($lang eq "dtdx") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Dtdx::c2deps($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Dtdx::c2chec($buil);
			$foun=1;
		}
		if($type eq "html") {
			$scod=Meta::Baseline::Lang::Dtdx::c2html($buil);
			$foun=1;
		}
	}
	if($lang eq "swig") {
		if($type eq "deps") {
			$scod=Meta::Baseline::Lang::Swig::c2deps($buil);
			$foun=1;
		}
		if($type eq "chec") {
			$scod=Meta::Baseline::Lang::Swig::c2chec($buil);
			$foun=1;
		}
		if($type eq "pmxx") {
			$scod=Meta::Baseline::Lang::Swig::c2pmxx($buil);
			$foun=1;
		}
		if($type eq "pmcc") {
			$scod=Meta::Baseline::Lang::Swig::c2pmcc($buil);
			$foun=1;
		}
	}
	if($lang eq "gzxx") {
	}
	if($lang eq "pack") {
	}
	if($lang eq "dslx") {
	}
	if($lang eq "pdfx") {
		if($type eq "gzxx") {
			$scod=Meta::Tool::Gzip::c2gzxx($buil);
			$foun=1;
		}
	}
	if($lang eq "dbxx") {
	}
	if($lang eq "manx") {
	}
	if($lang eq "nrfx") {
	}
	if($lang eq "bdbx") {
	}
	if($lang eq "late") {
	}
	if($lang eq "lyxx") {
	}
	if(!$foun) {
		throw Meta::Error::Simple("havent found module [".$lang."][".$type."]");
	}
	return($scod);
}

sub TEST($) {
	my($context)=@_;
	my($fil0)="perl/lib/my.pm";
	my($mod0)=Meta::Baseline::Switch::get_module($fil0);
	Meta::Utils::Output::print("modu for file [".$fil0."] is [".$mod0."]\n");
	my($fil1)="pyth/that.py";
	my($mod1)=Meta::Baseline::Switch::get_module($fil1);
	Meta::Utils::Output::print("modu for file [".$fil1."] is [".$mod1."]\n");
	my($fil2)="ccxx/other.tt";
	my($mod2)=Meta::Baseline::Switch::get_module($fil2);
	Meta::Utils::Output::print("modu for file [".$fil2."] is [".$mod2."]\n");
	my($fil3)="rule/law.rule";
	my($mod3)=Meta::Baseline::Switch::get_module($fil3);
	Meta::Utils::Output::print("modu for file [".$fil3."] is [".$mod3."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Switch - module to help to sort through all available languages.

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

	MANIFEST: Switch.pm
	PROJECT: meta
	VERSION: 0.57

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Switch qw();
	my($module)=Meta::Baseline::Switch::get_module("my.pm");

=head1 DESCRIPTION

This is the "switch" library between all language modules.

=head1 FUNCTIONS

	get_count($)
	get_own($)
	get_module($)
	get_type_enum()
	get_lang_enum()
	run_module($$$$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<get_count($)>

This will return the number of modules which report that the file given
is theirs.

=item B<get_own($)>

This method will return a perl list of all the modules which think they
own the file (mainly for debuggin purposes).

=item B<get_module($)>

This will look at a filename and will find the language responsible for
it or will die.

=item B<get_type_enum()>

This method will return an Enum type which has all the possible conversions.

=item B<get_lang_enum()>

This method will return an enum type which has all the possible languages.

=item B<run_module($$$$$$)>

This will run a module for you.

=item B<TEST($)>

Test suite for this module.
It currently just checks to see that it gets the perl module for "my.pm".

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

	0.00 MV perl quality change
	0.01 MV perl code quality
	0.02 MV more perl quality
	0.03 MV more perl quality
	0.04 MV get basic Simul up and running
	0.05 MV perl documentation
	0.06 MV more perl quality
	0.07 MV perl qulity code
	0.08 MV more perl code quality
	0.09 MV revision change
	0.10 MV better general cook schemes
	0.11 MV cook updates
	0.12 MV pictures in docbooks
	0.13 MV revision in files
	0.14 MV revision for perl files and better sanity checks
	0.15 MV languages.pl test online
	0.16 MV history change
	0.17 MV add rtf format to website,work on papers,add dtd lang
	0.18 MV introduce docbook xml and docbook deps
	0.19 MV cleanups
	0.20 MV good xml support
	0.21 MV more on data sets
	0.22 MV move def to xml directory
	0.23 MV bring back sgml to working condition
	0.24 MV automatic data sets
	0.25 MV web site and docbook style sheets
	0.26 MV write some papers and custom dssls
	0.27 MV spelling and papers
	0.28 MV fix docbook and other various stuff
	0.29 MV add zipping subsystem
	0.30 MV convert dtd to html
	0.31 MV PDMT/SWIG support
	0.32 MV Revision in DocBook files stuff
	0.33 MV PDMT stuff
	0.34 MV C++ and temp stuff
	0.35 MV finish lit database and convert DocBook to SGML
	0.36 MV update web site
	0.37 MV XML rules
	0.38 MV perl packaging
	0.39 MV perl packaging
	0.40 MV BuildInfo object change
	0.41 MV PDMT
	0.42 MV md5 project
	0.43 MV database
	0.44 MV perl module versions in files
	0.45 MV movies and small fixes
	0.46 MV graph visualization
	0.47 MV thumbnail user interface
	0.48 MV more thumbnail issues
	0.49 MV paper writing
	0.50 MV website construction
	0.51 MV improve the movie db xml
	0.52 MV web site automation
	0.53 MV SEE ALSO section fix
	0.54 MV move tests to modules
	0.55 MV finish papers
	0.56 MV teachers project
	0.57 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Lang::Aegi(3), Meta::Baseline::Lang::Ascx(3), Meta::Baseline::Lang::Aspe(3), Meta::Baseline::Lang::Awkx(3), Meta::Baseline::Lang::Bdbx(3), Meta::Baseline::Lang::Bins(3), Meta::Baseline::Lang::Ccxx(3), Meta::Baseline::Lang::Chec(3), Meta::Baseline::Lang::Chun(3), Meta::Baseline::Lang::Clas(3), Meta::Baseline::Lang::Conf(3), Meta::Baseline::Lang::Cook(3), Meta::Baseline::Lang::Cssx(3), Meta::Baseline::Lang::Cxxx(3), Meta::Baseline::Lang::Data(3), Meta::Baseline::Lang::Dbxx(3), Meta::Baseline::Lang::Deps(3), Meta::Baseline::Lang::Dirx(3), Meta::Baseline::Lang::Dlls(3), Meta::Baseline::Lang::Dslx(3), Meta::Baseline::Lang::Dtdx(3), Meta::Baseline::Lang::Dvix(3), Meta::Baseline::Lang::Epsx(3), Meta::Baseline::Lang::Gzxx(3), Meta::Baseline::Lang::Html(3), Meta::Baseline::Lang::Info(3), Meta::Baseline::Lang::Java(3), Meta::Baseline::Lang::Jpgx(3), Meta::Baseline::Lang::Late(3), Meta::Baseline::Lang::Libs(3), Meta::Baseline::Lang::Lily(3), Meta::Baseline::Lang::Lyxx(3), Meta::Baseline::Lang::Manx(3), Meta::Baseline::Lang::Midi(3), Meta::Baseline::Lang::Mifx(3), Meta::Baseline::Lang::Nrfx(3), Meta::Baseline::Lang::Objs(3), Meta::Baseline::Lang::Pack(3), Meta::Baseline::Lang::Patc(3), Meta::Baseline::Lang::Pdfx(3), Meta::Baseline::Lang::Perl(3), Meta::Baseline::Lang::Pgnx(3), Meta::Baseline::Lang::Pngx(3), Meta::Baseline::Lang::Psxx(3), Meta::Baseline::Lang::Pyob(3), Meta::Baseline::Lang::Pyth(3), Meta::Baseline::Lang::Rcxx(3), Meta::Baseline::Lang::Rtfx(3), Meta::Baseline::Lang::Rule(3), Meta::Baseline::Lang::Sgml(3), Meta::Baseline::Lang::Swig(3), Meta::Baseline::Lang::Targ(3), Meta::Baseline::Lang::Temp(3), Meta::Baseline::Lang::Texx(3), Meta::Baseline::Lang::Txtx(3), Meta::Baseline::Lang::Xmlx(3), Meta::Baseline::Lang::Xslt(3), Meta::Ds::Array(3), Meta::Info::Enum(3), Meta::Pdmt::BuildInfo(3), Meta::Tool::Gzip(3), Meta::Tool::Ps2Pdf(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-make the get_type_enum and get_lang_enum return variables which are prepared in BEGIN.

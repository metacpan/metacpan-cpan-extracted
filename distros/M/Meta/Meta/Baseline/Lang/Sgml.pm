#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Sgml;

use strict qw(vars refs subs);
use Meta::Baseline::Utils qw();
use Meta::Baseline::Lang qw();
use Meta::Tool::Onsgmls qw();
use Meta::Tool::Aspell qw();
#use Meta::Tool::Sgmltoolslite qw();
use Meta::Tool::Sgmltools qw();
use Meta::Lang::Xml::Xml qw();
use Meta::Lang::Sgml::Sgml qw();
use Meta::Baseline::Cook qw();
use Meta::Tool::Sgml2 qw();
use Meta::Tool::Docbook2 qw();
use Meta::Tool::Openjade qw();
use Meta::Xml::LibXML qw();

#tools that we are currently not using
#use Meta::Tool::Jade qw();
#use Meta::Tool::Nsgmls qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw(Meta::Baseline::Lang);

#sub c2chec($);
#sub c2deps($);
#sub c2texx($);
#sub c2dvix($);
#sub c2psxx($);
#sub c2txtx($);
#sub c2html($);
#sub c2rtfx($);
#sub c2manx($);
#sub c2mifx($);
#sub c2info($);
#sub c2pdfx($);
#sub c2chun($);
#sub c2xmlx($);
#sub c2late($);
#sub c2lyxx($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2chec($) {
	my($buil)=@_;
	my($resu)=1;
	my($cod0)=Meta::Tool::Onsgmls::dochec($buil);
	if(!$cod0) {
		$resu=0;
	}
	# check spelling using aspell sgml mode
	my($cod1)=Meta::Tool::Aspell::checksgml($buil);
	if(!$cod1) {
		$resu=0;
	}
	# check correctness usign XML
	#my($parser)=Meta::Xml::LibXML->new_aegis();
	#$parser->validation(1);
	#$parser->pedantic_parser(1);
	#$parser->load_ext_dtd(1);
	#my($cod0)=$parser->check_file($buil->get_srcx());
	#if(!$cod0) {
	#	$resu=0;
	#}
	# check sgml using onsgmls
	# check sgml using nsgmls
	#my($cod2)=Meta::Tool::Nsgmls::dochec($buil->get_srcx(),$buil->get_path());
	#if(!$cod2) {
	#	$resu=0;
	#}
	# check sgml using sgmltoolslite
	#my($cod4)=Meta::Tool::Sgmltoolslite::check($buil);
	#if(!$cod4) {
	#	$resu=0;
	#}
	if($resu) {
		Meta::Baseline::Utils::file_emblem($buil->get_targ());
	}
	return($resu);
}

sub c2deps($) {
	my($buil)=@_;
	my($deps)=Meta::Lang::Sgml::Sgml::c2deps($buil);
	Meta::Baseline::Cook::print_deps($deps,$buil->get_targ());
	return(1);
}

sub c2texx($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2texx($buil));
	return(Meta::Tool::Openjade::c2texx($buil));
}

sub c2dvix($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2dvix($buil));
	return(Meta::Tool::Openjade::c2dvix($buil));
}

sub c2psxx($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2psxx($buil));
	return(Meta::Tool::Openjade::c2psxx($buil));
}

sub c2txtx($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2txtx($buil));
	return(Meta::Tool::Openjade::c2txtx($buil));
}

sub c2html($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2html($buil));
	return(Meta::Tool::Openjade::c2html($buil));
}

sub c2rtfx($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2rtfx($buil));
	return(Meta::Tool::Openjade::c2rtfx($buil));
}

sub c2manx($) {
	my($buil)=@_;
#	return(Meta::Tool::Docbook2::c2manx($buil));
	return(Meta::Tool::Openjade::c2rtfx($buil));
}

sub c2mifx($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2mifx($buil));
	return(Meta::Tool::Openjade::c2mifx($buil));
}

sub c2info($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltools::c2info($buil));
#	return(Meta::Tool::Sgml2::c2info($buil));
	return(Meta::Tool::Openjade::c2info($buil));
}

sub c2pdfx($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltoolslite::c2pdfx($buil));
	return(Meta::Tool::Openjade::c2pdfx($buil));
}

sub c2chun($) {
	my($buil)=@_;
	return(Meta::Lang::Xml::Xml::c2chun($buil));
}

sub c2xmlx($) {
	my($buil)=@_;
#	return(Meta::Tool::Sgmltools::c2xmlx($buil));
	return(Meta::Tool::Openjade::c2xmlx($buil));
}

sub c2late($) {
	my($buil)=@_;
	return(Meta::Tool::Openjade::c2late($buil));
#	return(Meta::Tool::Sgmltools::c2late($buil));
}

sub c2lyxx($) {
	my($buil)=@_;
	return(Meta::Tool::Openjade::c2lyxx($buil));
#	return(Meta::Tool::Sgmltools::c2lyxx($buil));
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^sgml\/.*\.sgml$/) {
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

Meta::Baseline::Lang::Sgml - doing Sgml specific stuff in the baseline.

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

	MANIFEST: Sgml.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Sgml qw();
	my($resu)=Meta::Baseline::Lang::Sgml::env();

=head1 DESCRIPTION

This package contains stuff specific to Sgml in the baseline:
0. verifies docbook source files using nsgmls/onsgmls/DOM.
1. converts docbook sources to various formats (postscript,Rtf,Pdf,Dvi,HTML,
	multi HTML,plain text,Tex etc...) using various tools (jade,openjade,
	sgmltools,sgml2).
2. authorizes entry for docbook sources into the baseline.

It is better to do convertions directly through openjade and not through tools
for which the API is not yet stable like sgmltools or others.

=head1 FUNCTIONS

	c2chec($)
	c2deps($)
	c2texx($)
	c2dvix($)
	c2psxx($)
	c2txtx($)
	c2html($)
	c2rtfx($)
	c2manx($)
	c2mifx($)
	c2info($)
	c2pdfx($)
	c2chun($)
	c2xmlx($)
	c2late($)
	c2lyxx($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2chec($)>

This routine verifies docbook sources using the following methods:
0. runs nsgmls on it and checks the result.

=item B<c2deps($)>

This routine will print out dependencies in cook fashion for docbook sources.
It will use other perl module to do that (scan the external entities used
and print paths to them).
Currently it does nothing.

=item B<c2texx($)>

This routine will convert DocBook files to Tex.

=item B<c2dvix($)>

This routine will convert sgml DocBook files to Dvi.

=item B<c2psxx($)>

This routine will convert sgml DocBook files to Postscript.

=item B<c2txtx($)>

This routine will convert sgml DocBook files to text.

=item B<c2html($)>

This routine will convert sgml DocBook files to Html.

=item B<c2rtfx($)>

This routine will convert sgml DocBook files to Rtf.

=item B<c2manx($)>

This routine will convert sgml DocBook files to manual page format.

=item B<c2mifx($)>

This routine will convert sgml DocBook files to Mif.

=item B<c2info($)>

This routine will convert sgml DocBook files to GNU info.

=item B<c2pdfx($)>

This routine will convert sgml DocBook files to Pdf (Portable Documentation
Format from Adobe).

=item B<c2chun($)>

This routine will convert sgml DocBook files to files without DocBook headers
in them (DOCTYPE) etc... so they chould be included as chunks for other documents.

=item B<c2xmlx($)>

This routine will convert DocBook files to XML.

=item B<c2late($)>

This will convert DocBook files to Latex.

=item B<c2lyxx($)>

This will convert DocBook files to LyX.

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

	0.00 MV finish lit database and convert DocBook to SGML
	0.01 MV update web site
	0.02 MV perl packaging
	0.03 MV perl packaging
	0.04 MV BuildInfo object change
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV movies and small fixes
	0.09 MV more Class method generation
	0.10 MV thumbnail user interface
	0.11 MV dbman package creation
	0.12 MV more thumbnail issues
	0.13 MV website construction
	0.14 MV web site automation
	0.15 MV SEE ALSO section fix
	0.16 MV bring movie data
	0.17 MV finish papers
	0.18 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Cook(3), Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), Meta::Lang::Sgml::Sgml(3), Meta::Lang::Xml::Xml(3), Meta::Tool::Aspell(3), Meta::Tool::Docbook2(3), Meta::Tool::Onsgmls(3), Meta::Tool::Openjade(3), Meta::Tool::Sgml2(3), Meta::Tool::Sgmltools(3), Meta::Xml::LibXML(3), strict(3)

=head1 TODO

-add the following sanity check to c2chec: that I never use sect1, sect2 etc but rather use section (the better way). Are there any other things I may want to check ? the KDE team said they have a restricted version of docbook that they use - check it out. Should I do it in Lang::Sgml or what ?!?

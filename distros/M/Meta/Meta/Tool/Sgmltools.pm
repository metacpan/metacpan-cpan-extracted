#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Sgmltools;

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Output qw();
use Meta::Utils::Text::Lines qw();
use Meta::Utils::File::Copy qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::File::Move qw();
use Meta::Utils::Utils qw();
use Meta::Utils::Chdir qw();

our($VERSION,@ISA);
$VERSION="0.21";
@ISA=qw();

#sub check($$);
#sub c2texx($);
#sub c2dvix($);
#sub c2psxx($);
#sub c2txtx($);
#sub c2html($);
#sub c2rtfx($);
#sub c2mifx($);
#sub c2info($);
#sub c2pdfx($);
#sub c2late($);
#sub c2lyxx($);
#sub tool($$$$);
#sub TEST($);

#__DATA__

sub check($$) {
	my($srcx,$path)=@_;
	return(1);
}

sub c2texx($) {
	my($buil)=@_;
	return(tool($buil,"tex","jadetex","sgml2tex"));
}

sub c2dvix($) {
	my($buil)=@_;
	return(tool($buil,"dvi","dvi","sgml2dvi"));
}

sub c2psxx($) {
	my($buil)=@_;
	return(tool($buil,"ps","ps","sgml2ps"));
}

sub c2txtx($) {
	my($buil)=@_;
	return(tool($buil,"txt","txt","sgml2txt"));
}

sub c2html($) {
	my($buil)=@_;
	return(tool($buil,"html","onehtml","sgml2html"));
}

sub c2rtfx($) {
	my($buil)=@_;
	return(tool($buil,"rtf","rtf","sgml2rtf"));
}

sub c2mifx($) {
	my($buil)=@_;
	return(tool($buil,"mif","mif","sgml2mif"));
}

sub c2info($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
	#return(tool($buil,"info","info","sgml2info"));
}

sub c2pdfx($) {
	my($buil)=@_;
	return(tool($buil,"pdf","pdf","sgml2pdf"));
}

sub c2late($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2lyxx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub tool($$$$) {
	my($buil,$suff,$back,$prog)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($file)=Meta::Utils::Utils::get_temp_file();
	my($resu)=$file."\.".$suff;
	Meta::Utils::File::Copy::copy($srcx,$file);
	Meta::Utils::Env::remove("SGML_CATALOG_FILES");
	Meta::Utils::Env::remove("SGML_PATH");
	my(@args);
	#push(@args,"--backend=".$back);
	#push(@args,"--output=".$back);
	my(@pths)=split(':',$path);
	my(@dirs);
	for(my($i)=0;$i<=$#pths;$i++) {
		my($curr)=$pths[$i];
		#add search directory for entire search path
		my($docb)=$curr."/chun/sgml";
		if(-d $docb) {
			push(@dirs,"-D".$docb);
			#push(@args,"--include".$docb);
		}
		#search for DTDs in the baseline
		my($dtdx)=$curr."/dtdx";
		if(-d $dtdx) {
			push(@dirs,"-D".$dtdx);
			#push(@args,"--include".$dtdx);
		}
		#search for DTDs in the baseline catalog
		my($dtdxcata)=$curr."/dtdx/CATALOG";
		if(-f $dtdxcata) {
			push(@dirs,"-c".$dtdxcata);
			#push(@args,"-c".$dtdxcata);
		}
		#search for DSLs in the baseline
		my($dslx)=$curr."/dslx";
		if(-d $dslx) {
			push(@dirs,"-D".$dslx);
			#push(@args,"--include".$dslx);
		}
		#search for DSLs in the baseline catalog
		my($dslxcata)=$curr."/dslx/CATALOG";
		if(-f $dslxcata) {
			push(@dirs,"-c".$dslxcata);
			#push(@args,"-c".$dslxcata);
		}
	}
	push(@args,"--pass=\'".join(" ",@dirs)."\'",$file);
	my($text);
	#Meta::Utils::Output::print("args are [".CORE::join(",",@args)."]\n");
	Meta::Utils::Chdir::chdir("/tmp");
	my($scod)=Meta::Utils::System::system_err(\$text,$prog,\@args);
	Meta::Utils::Chdir::popd();
	Meta::Utils::File::Remove::rm($file);
	if(!$scod) {#code is bad (there should be no result but we rm it still)
		Meta::Utils::Output::print($text);
		try {
			Meta::Utils::File::Remove::rm($resu);
		}
		catch Meta::Error::FileNotFound with {
			#dont do anything
		}
	} else {
		my($obj)=Meta::Utils::Text::Lines->new();
		$obj->set_text($text,"\n");
		$obj->remove_line_nre("\<OSFD\>");
		$text=$obj->get_text_fixed();
		if($text ne "") {#code is ok but there is error text
			$scod=0;
			Meta::Utils::Output::print($text);
			Meta::Utils::File::Remove::rm($resu);
		} else {#all is well - code is ok and no error text
			Meta::Utils::File::Move::mv($resu,$targ);
		}
	}
	return($scod);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Sgmltools - run sgmltools for you.

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

	MANIFEST: Sgmltools.pm
	PROJECT: meta
	VERSION: 0.21

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Sgmltools qw();
	my($object)=Meta::Tool::Sgmltools->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module is here to ease the job of running sgmltools for you if
you wish to use them (I think it's better to use the Jade.pm module
which runs jade or openjade directly).

Sgmltools is quite problematic:
1. Sgmltools has a --jade-opt option but you CANT specify several options this
	way - you have to join everything into one thing.

=head1 FUNCTIONS

	check($$)
	c2texx($)
	c2dvix($)
	c2psxx($)
	c2txtx($)
	c2html($)
	c2rtfx($)
	c2mifx($)
	c2info($)
	c2pdfx($)
	c2late($)
	c2lyxx($)
	tool($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<check($$)>

Run a check on the SGML document using the sgmlcheck utility.

=item B<c2texx($)>

This routine will convert sgml DocBook files to Tex.

=item B<c2dvix($)>

This routine will convert sgml DocBook files to Dvi.

=item B<c2psxx($)>

This routine will convert sgml DocBook files to Postscript.

=item B<c2txtx($)>

This routine will convert sgml DocBook files to Text.

=item B<c2html($)>

This routine will convert sgml DocBook files to HTML.

=item B<c2rtfx($)>

This routine will convert sgml DocBook files to Rtf (Rich Text Format).

=item B<c2mifx($)>

This routine will convert sgml DocBook files to Mif (Microsoft Interchange Format).
Currently this does not do the actual convertion because sgml tool do not
support this so it just put an emblem.

=item B<c2info($)>

This routine will convert sgml DocBook files to GNU info format.
These is no info backend to sgmltools at the moment (3.0) that I am
aware of. This means that this routine is broken. Do not use it.

=item B<c2pdfx($)>

This routine will convert sgml DocBook files to Pdf (Portable Documentation
Format).
This way of prducing pdfs seems to be broken (I have not been able to see
the resulting pdf using xpdf).
In any case - this backend IS supported by sgmltools altough you cannot see
this in the documentation.

=item B<c2late($)>

This method will convert SGML DocBook files to Latex.

=item B<c2lyxx($)>

This method will convert SGML DocBook files to Lyx.

=item B<tool($$$$)>

This is the actual wrapper code. We pass directory search paths to jade
via the option in sgmltools to pass options to jade...:)
The problem is that sgmltools does not allow the option to specify the
output file and so we do all the work using a temporary file and then
move the result.

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

	0.00 MV history change
	0.01 MV web site stuff
	0.02 MV real deps for docbook files
	0.03 MV remove old c++ files
	0.04 MV pics with db support
	0.05 MV bring back sgml to working condition
	0.06 MV write some papers and custom dssls
	0.07 MV spelling and papers
	0.08 MV fix docbook and other various stuff
	0.09 MV finish lit database and convert DocBook to SGML
	0.10 MV perl packaging
	0.11 MV BuildInfo object change
	0.12 MV md5 project
	0.13 MV database
	0.14 MV perl module versions in files
	0.15 MV movies and small fixes
	0.16 MV thumbnail user interface
	0.17 MV more thumbnail issues
	0.18 MV website construction
	0.19 MV web site automation
	0.20 MV SEE ALSO section fix
	0.21 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Chdir(3), Meta::Utils::File::Copy(3), Meta::Utils::File::Move(3), Meta::Utils::File::Remove(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Text::Lines(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-how can I stop jade from looking in /usr/lib/sgml and finding junk there ?

-remmember to restore SGML_CATALOG_FILES after invocation.

-do the actual code for c2info,c2pdfx

-try to use symlinks instead of the copies here (it will be faster).

-add a C<-o> option to sgmltools so I wont need to bypass them here.

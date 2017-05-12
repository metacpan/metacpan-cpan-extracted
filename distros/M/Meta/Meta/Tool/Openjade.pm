#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Openjade;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::Utils::System qw();
use Meta::Baseline::Utils qw();
use Meta::Baseline::Aegis qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw();

#sub c2psxx($);
#sub c2txtx($);
#sub c2html($);
#sub c2rtfx($);
#sub c2mifx($);
#sub c2pdfx($);
#sub c2xmlx($);
#sub c2texx($);
#sub c2dvix($);
#sub c2info($);
#sub c2late($);
#sub c2lyxx($);
#sub c2some($);
#sub TEST($);

#__DATA__

sub c2psxx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2txtx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2html($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2rtfx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2mifx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2pdfx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2xmlx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::xml_emblem($buil->get_targ());
	return(1);
}

sub c2texx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::xml_emblem($buil->get_targ());
	return(1);
	#return(c2some($buil));
}

sub c2dvix($) {
	my($buil)=@_;
	Meta::Baseline::Utils::xml_emblem($buil->get_targ());
	return(1);
}

sub c2info($) {
	my($buil)=@_;
	Meta::Baseline::Utils::xml_emblem($buil->get_targ());
	return(1);
}

sub c2late($) {
	my($buil)=@_;
	Meta::Baseline::Utils::xml_emblem($buil->get_targ());
	return(1);
}

sub c2lyxx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::xml_emblem($buil->get_targ());
	return(1);
}

sub c2some($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($prog)="openjade";
	my(@args);
	#use the tex backend
	push(@args,"-Vtex-backend");
	my(@pths)=split(':',$path);
	for(my($i)=0;$i<=$#pths;$i++) {
		my($curr)=$pths[$i];
		# where to find dtd catalogs
		my($cata)=$curr."/dtdx/CATALOG";
		if(-f $cata) {
			push(@args,"-c",$cata);
		}
		# where to find docbook include files
		my($dtdx)=$curr."/chun";
		if(-d $dtdx) {
			push(@args,"-D",$dtdx);
		}
	}
	#where is the print dsl
	my($dsl)=Meta::Baseline::Aegis::which("dslx/print.dsl");
	push(@args,"-d",$dsl);
	#output type is tex
	push(@args,"-t","tex");
	#what is the output file
	push(@args,"-o",$targ);
	#warn of all things
	push(@args,"-Wall");
	push(@args,$srcx);
	my($text);
	#Meta::Utils::Output::print("args are [".CORE::join(",",@args)."]\n");
	my($scod)=Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
	if(!$scod) {
		Meta::Utils::Output::print($text);
	} else {
		#filter $text here to see if there are any other errros
		my($prog)="tex";
		my(@args);
		push(@args,"&pdfjadetex");
		push(@args,$targ);
		my($text);
		Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
		Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
		Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
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

Meta::Tool::Openjade - run open jade for various stuff.

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

	MANIFEST: Openjade.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Openjade qw();
	my($object)=Meta::Tool::Openjade->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will hide the complexity of running Openjade from you.
This is the best way to work with sgml and not use other types of
wrapper like sgmltools sgmltools-lite sgml2x docbook-utils etc...
Openjade also supplies an sgml2xml converter and we use it.

=head1 FUNCTIONS

	c2psxx($)
	c2txtx($)
	c2html($)
	c2rtfx($)
	c2mifx($)
	c2pdfx($)
	c2xmlx($)
	c2texx($)
	c2dvix($)
	c2info($)
	c2late($)
	c2lyxx($)
	c2some($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2psxx($)>

This will run open jade and will convert it to postscript.

=item B<c2txtx($)>

This will run open jade and will convert it to plain text.

=item B<c2html($)>

This will run open jade and will convert it to a single html file.

=item B<c2rtfx($)>

This will run open jade and will convert it to a single rtf file.

=item B<c2mifx($)>

This will run open jade and will convert it to a single mif file.

=item B<c2pdfx($)>

This will run open jade on the given SGML file and will convert it to PDF
(Portable Documentation Format from Adobe) format.

=item B<c2xmlx($)>

This method will convert SGML input to XML.

=item B<c2texx($)>

This method will convert SGML input to TeX.

=item B<c2dvix($)>

This method will convert SGML input to DVI.

=item B<c2info($)>

This method will convert SGML input to GNU info output.

=item B<c2late($)>

This method will convert SGML input to LaTEX output.

=item B<c2lyxx($)>

This method will convert SGML input to Lyx output.

=item B<c2some($)>

This will run open jade and will convert sgml to several formats.

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

	0.00 MV pics with db support
	0.01 MV write some papers and custom dssls
	0.02 MV spelling and papers
	0.03 MV fix docbook and other various stuff
	0.04 MV perl packaging
	0.05 MV BuildInfo object change
	0.06 MV xml encoding
	0.07 MV md5 project
	0.08 MV database
	0.09 MV perl module versions in files
	0.10 MV movies and small fixes
	0.11 MV thumbnail user interface
	0.12 MV dbman package creation
	0.13 MV more thumbnail issues
	0.14 MV website construction
	0.15 MV web site automation
	0.16 MV SEE ALSO section fix
	0.17 MV bring movie data
	0.18 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Utils(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-use the -w option when running openjade to get warnings.

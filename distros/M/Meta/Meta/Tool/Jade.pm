#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Jade;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::Utils::System qw();

our($VERSION,@ISA);
$VERSION="0.16";
@ISA=qw();

#sub c2pdfx($$$$);
#sub TEST($);

#__DATA__

sub c2pdfx($$$$) {
	my($modu,$srcx,$targ,$path)=@_;
	my($prog)="jade";
	my(@args);
	push(@args,"-Vtex-backend");
	my(@pths)=split(':',$path);
	for(my($i)=0;$i<=$#pths;$i++) {
		my($curr)=$pths[$i];
		my($cata)=$curr."/dtdx/CATALOG";
		if(-f $cata) {
			push(@args,"-c",$cata);
		}
		my($dtdx)=$curr."/sgml";
		if(-d $dtdx) {
			push(@args,"-D",$dtdx);
		}
	}
	push(@args,"-d","/local/archive/bigplayground/nwdsssl/print/docbook.dsl");#FIX
	push(@args,"-t","tex");
	push(@args,"-o",$targ);
	push(@args,$srcx);
	my($text);
	Meta::Utils::Output::print("args are [".CORE::join(",",@args)."]\n");
	my($scod)=Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
	if(!$scod) {
		Meta::Utils::Output::print($text);
	} else {
#		filter $text here to see if there are any other errros
#		my($prog)="tex";
#		my(@args);
#		push(@args,"&pdfjadetex");
#		push(@args,$targ);
#		my($text);
#		Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
#		Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
#		Meta::Utils::System::system_err_nodie(\$text,$prog,\@args);
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

Meta::Tool::Jade - run jade for various stuff.

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

	MANIFEST: Jade.pm
	PROJECT: meta
	VERSION: 0.16

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Jade qw();
	my($object)=Meta::Tool::Jade->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will hide the complexity of running Jade from you.
Mind you, this is Jade not open Jade. It is preffereable to use open
jade.

=head1 FUNCTIONS

	c2pdfx($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2pdfx($$$$)>

This will run jade on the given SGML file and will convert it to PDF
(Portable Documentation Format from Adobe) format.

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
	0.02 MV remove old c++ files
	0.03 MV pics with db support
	0.04 MV write some papers and custom dssls
	0.05 MV finish lit database and convert DocBook to SGML
	0.06 MV perl packaging
	0.07 MV md5 project
	0.08 MV database
	0.09 MV perl module versions in files
	0.10 MV movies and small fixes
	0.11 MV thumbnail user interface
	0.12 MV more thumbnail issues
	0.13 MV website construction
	0.14 MV web site automation
	0.15 MV SEE ALSO section fix
	0.16 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-use the -w option when running jade to get warnings.

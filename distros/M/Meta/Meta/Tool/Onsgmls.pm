#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Onsgmls;

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Output qw();
use Meta::Lang::Docb::Params qw();
use Meta::Utils::File::Patho qw();

our($VERSION,@ISA);
$VERSION="0.16";
@ISA=qw();

#sub BEGIN();
#sub dochec($);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("onsgmls");
}

sub dochec($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($path)=$buil->get_path();
	my(@args);
	push(@args,"--no-output");#do not use onsgmls as convertor but as checker
	push(@args,"--warning=all");#all warnings
	push(@args,"--warning=no-mixed");#docbook dtds violate this
	push(@args,"--open-elements");#print open elements when printing errors
	push(@args,"--open-entities");#print open entities when printing errors
	my(@lpth)=split(":",$path);
	for(my($i)=0;$i<=$#lpth;$i++) {
		my($curr)=$lpth[$i];
		my($dtdx)=$curr."/dtdx";
		if(-d $dtdx) {
			push(@args,"--directory=".$dtdx);
		}
		my($docb)=$curr."/chun/sgml";
		if(-d $docb) {
			push(@args,"--directory=".$docb);
		}
		my($cata)=$curr."/dtdx/CATALOG";
		if(-f $cata) {
			push(@args,"--catalog=".$cata);
		}
	}
	my(@epth)=split(":",Meta::Lang::Docb::Params::get_extra());
	for(my($i)=0;$i<=$#epth;$i++) {
		my($curr)=$epth[$i];
		my($dtdx)=$curr;
		if(-d $dtdx) {
			push(@args,"--directory=".$dtdx);
		}
		my($cata)=$curr."/CATALOG";
		if(-f $cata) {
			push(@args,"--catalog=".$cata);
		}
	}
	push(@args,$srcx);
	my($text);
#	Meta::Utils::Output::print("args are [".join(",",@args)."]\n");
	my($code)=Meta::Utils::System::system_err(\$text,$tool_path,\@args);
#	Meta::Utils::Output::print("text is [".$text."]\n");
	#make sure that no errors are printed (even if exit code is good).
	if($code) {
		if($text ne "") {
			Meta::Utils::Output::print("onsgml failed\n");
			Meta::Utils::Output::print($text);
			$code=0;
		}
	} else {
		Meta::Utils::Output::print("onsgml failed\n");
		Meta::Utils::Output::print($text);
	}
	return($code);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Onsgmls - run onsgmls for you.

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

	MANIFEST: Onsgmls.pm
	PROJECT: meta
	VERSION: 0.16

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Onsgmls qw();
	my($object)=Meta::Tool::Onsgmls->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will ease the work of running onsgmls for you. The current purpose
is to validate SGML documents but more uses may be added in the future.

The onsgmls that this runs is the one supplied with recent versions of opensp
and NOT openjade. This means that you need opensp installed and your path
to point to the opensp version of onsgmls which has a DIFFERENT command line
interface than the openjade interface.

=head1 FUNCTIONS

	BEGIN()
	dochec($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

A bootstrap method to find your version of onsgmls.

=item B<dochec($)>

This method will check an sgml file using nsgmls and will return a boolean
value according to whether that file is correct.

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
	0.01 MV papers
	0.02 MV spelling and papers
	0.03 MV publish gz on the internet
	0.04 MV finish lit database and convert DocBook to SGML
	0.05 MV perl packaging
	0.06 MV BuildInfo object change
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

Meta::Lang::Docb::Params(3), Meta::Utils::File::Patho(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-fix the docbook dtd and remove the -wno-mixed flag that I use here to bypass it.

-get the path for onsgmls (/local/tools/bin) out of here and into some external options file.

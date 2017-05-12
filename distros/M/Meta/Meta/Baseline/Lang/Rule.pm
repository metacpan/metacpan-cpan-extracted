#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Rule;

use strict qw(vars refs subs);
use Meta::Baseline::Utils qw();
use Meta::Utils::Options qw();
use Meta::Baseline::Lang qw();
use Meta::IO::File qw();

our($VERSION,@ISA);
$VERSION="0.25";
@ISA=qw(Meta::Baseline::Lang);

#sub c2deps($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2deps($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($opti)=Meta::Utils::Options->new();
	my($resu)=$opti->read($srcx);
	if(!$resu) {
		return(0);
	}
	my($proc)=$opti->getd("proc","");
	my($trg0)=$opti->getd("trg0","");
	my($trg1)=$opti->getd("trg1","");
	my($trg2)=$opti->getd("trg2","");
	my($trg3)=$opti->getd("trg3","");
	my($src0)=$opti->getd("src0","");
	my($src1)=$opti->getd("src1","");
	my($src2)=$opti->getd("src2","");
	my($src3)=$opti->getd("src3","");
	my($prm0)=$opti->getd("prm0","");
	my($prm1)=$opti->getd("prm1","");
	my($prm2)=$opti->getd("prm2","");
	my($prm3)=$opti->getd("prm3","");
	my($modu)=($srcx=~/^(.*)\.tg$/);
	my($file)=Meta::IO::File->new_writer($targ);
	Meta::Baseline::Utils::cook_emblem_print($file);
	my(@trgs);
	if($trg0 ne "") {
		push(@trgs,$trg0);
	}
	if($trg1 ne "") {
		push(@trgs,$trg1);
	}
	if($trg2 ne "") {
		push(@trgs,$trg2);
	}
	if($trg3 ne "") {
		push(@trgs,$trg3);
	}
	my(@srcs);
	if($src0 ne "") {
		push(@srcs,$src0);
	}
	if($src1 ne "") {
		push(@srcs,$src1);
	}
	if($src2 ne "") {
		push(@srcs,$src2);
	}
	if($src3 ne "") {
		push(@srcs,$src3);
	}
	print $file join(" ",@trgs)." : ".join(" ",@srcs)."\n";
	print $file "\t[base_rule_tool_exec_depx]\n";
	print $file "\thost-binding [base_host_scr]\n";
	print $file "{\n";
	print $file "\tfunction base_doit [base_rule_tool_exec] ";
	my(@args);
	push(@args,"--proc \"".$proc."\"");
	if($trg0 ne "") {
		push(@args,"--trg0 \"".$trg0."\"");
	}
	if($trg1 ne "") {
		push(@args,"--trg1 \"".$trg1."\"");
	}
	if($trg2 ne "") {
		push(@args,"--trg2 \"".$trg2."\"");
	}
	if($trg3 ne "") {
		push(@args,"--trg3 \"".$trg3."\"");
	}
	if($src0 ne "") {
		push(@args,"--src0 [unsplit \":\" [resolve ".$src0."]]");
	}
	if($src1 ne "") {
		push(@args,"--src1 [unsplit \":\" [resolve ".$src1."]]");
	}
	if($src2 ne "") {
		push(@args,"--src2 [unsplit \":\" [resolve ".$src2."]]");
	}
	if($src3 ne "") {
		push(@args,"--src3 [unsplit \":\" [resolve ".$src3."]]");
	}
	if($prm0 ne "") {
		push(@args,"--prm0 [unsplit \":\" ".$prm0."]");
	}
	if($prm1 ne "") {
		push(@args,"--prm1 [unsplit \":\" ".$prm1."]");
	}
	if($prm2 ne "") {
		push(@args,"--prm2 [unsplit \":\" ".$prm2."]");
	}
	if($prm3 ne "") {
		push(@args,"--prm3 [unsplit \":\" ".$prm3."]");
	}
	push(@args,"--path [base_search_path]");
	print $file CORE::join(" ",@args).";\n}\n";
	print $file "base_rule_file_objx+=".join(" ",@trgs).";\n";
	$file->close();
	return(1);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^rule\/.*\.rule$/) {
		return(1);
	} else {
		return(0);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Rule - doing Rule specific stuff in the baseline.

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

	MANIFEST: Rule.pm
	PROJECT: meta
	VERSION: 0.25

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Rule qw();
	my($hash)=Meta::Baseline::Lang::Rule::env();

=head1 DESCRIPTION

This package excutes rule specific stuff in the baseline.

=head1 FUNCTIONS

	c2deps($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($)>

This method will convert Rule sources to dependency listings.
This method returns an error code.

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

	0.00 MV fix up the rule system
	0.01 MV perl quality change
	0.02 MV perl code quality
	0.03 MV more perl quality
	0.04 MV more perl quality
	0.05 MV perl documentation
	0.06 MV more perl quality
	0.07 MV perl qulity code
	0.08 MV more perl code quality
	0.09 MV revision change
	0.10 MV cook updates
	0.11 MV revision for perl files and better sanity checks
	0.12 MV languages.pl test online
	0.13 MV perl packaging
	0.14 MV BuildInfo object change
	0.15 MV xml encoding
	0.16 MV md5 project
	0.17 MV database
	0.18 MV perl module versions in files
	0.19 MV movies and small fixes
	0.20 MV thumbnail user interface
	0.21 MV more thumbnail issues
	0.22 MV website construction
	0.23 MV web site automation
	0.24 MV SEE ALSO section fix
	0.25 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), Meta::IO::File(3), Meta::Utils::Options(3), strict(3)

=head1 TODO

Nothing.

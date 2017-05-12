#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Tool::Gcc qw();
use Meta::Tool::Tar qw();
use Meta::Tool::Rpm qw();
use Meta::Tool::Jar qw();
use Meta::Tool::Deb qw();
use Meta::Utils::Output qw();

my($verb,$demo);
my($proc,$trg0,$trg1,$trg2,$trg3,$src0,$src1,$src2,$src3,$prm0,$prm1,$prm2,$prm3,$path);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_bool("demo","play around or do it for real ?",0,\$demo);
$opts->def_stri("proc","what procedure to use ?","",\$proc);
$opts->def_stri("trg0","target list 0","",\$trg0);
$opts->def_stri("trg1","target list 0","",\$trg1);
$opts->def_stri("trg2","target list 0","",\$trg2);
$opts->def_stri("trg3","target list 0","",\$trg3);
$opts->def_stri("src0","source list 0","",\$src0);
$opts->def_stri("src1","source list 0","",\$src1);
$opts->def_stri("src2","source list 0","",\$src2);
$opts->def_stri("src3","source list 0","",\$src3);
$opts->def_stri("prm0","paramters list 0","",\$prm0);
$opts->def_stri("prm1","paramters list 0","",\$prm1);
$opts->def_stri("prm2","paramters list 0","",\$prm2);
$opts->def_stri("prm3","paramters list 0","",\$prm3);
$opts->def_stri("path","search path","",\$path);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

if($verb) {
	for(my($i)=0;$i<=$#ARGV;$i++) {
		Meta::Utils::Output::print("arg [".$i."] is [".$ARGV[$i]."]\n");
	}
}
my($scod);
my($foun)=0;
#first try the gcc linking
if(!$foun) {
	if(Meta::Tool::Gcc::your_proc($proc)) {
		$scod=Meta::Tool::Gcc::link($verb,$demo,$proc,$trg0,$trg1,$trg2,$trg3,$src0,$src1,$src2,$src3,$prm0,$prm1,$prm2,$prm3,$path);
		$foun=1;
	}
}
#lets try the tar generation rule
if(!$foun) {
	if(Meta::Tool::Tar::your_proc($proc)) {
		$foun=1;
	}
}
#lets try the rpm generation rule
if(!$foun) {
	if(Meta::Tool::Rpm::your_proc($proc)) {
		$foun=1;
	}
}
#lets try the jar generation rule
if(!$foun) {
	if(Meta::Tool::Jar::your_proc($proc)) {
		$foun=1;
	}
}
#lets try the deb generation rule
if(!$foun) {
	if(Meta::Tool::Deb::your_proc($proc)) {
		$foun=1;
	}
}
if(!$foun) {
	Meta::Utils::Output::print("unknown proc [".$proc."]\n");
	$scod=0;
}
Meta::Utils::System::exit($scod);

__END__

=head1 NAME

base_rule_exec.pl - execute rule procedures.

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

	MANIFEST: base_rule_exec.pl
	PROJECT: meta
	VERSION: 0.29

=head1 SYNOPSIS

	base_rule_exec.pl

=head1 DESCRIPTION

This utility will execute rule targets for you.
According to the type of action required it will dispatch to an appropriate
function and will do whatever you want it to.

=head1 OPTIONS

=over 4

=item B<help> (type: bool, default: 0)

display help message

=item B<pod> (type: bool, default: 0)

display pod options snipplet

=item B<man> (type: bool, default: 0)

display manual page

=item B<quit> (type: bool, default: 0)

quit without doing anything

=item B<gtk> (type: bool, default: 0)

run a gtk ui to get the parameters

=item B<license> (type: bool, default: 0)

show license and exit

=item B<copyright> (type: bool, default: 0)

show copyright and exit

=item B<description> (type: bool, default: 0)

show description and exit

=item B<history> (type: bool, default: 0)

show history and exit

=item B<verbose> (type: bool, default: 0)

noisy or quiet ?

=item B<demo> (type: bool, default: 0)

play around or do it for real ?

=item B<proc> (type: stri, default: )

what procedure to use ?

=item B<trg0> (type: stri, default: )

target list 0

=item B<trg1> (type: stri, default: )

target list 0

=item B<trg2> (type: stri, default: )

target list 0

=item B<trg3> (type: stri, default: )

target list 0

=item B<src0> (type: stri, default: )

source list 0

=item B<src1> (type: stri, default: )

source list 0

=item B<src2> (type: stri, default: )

source list 0

=item B<src3> (type: stri, default: )

source list 0

=item B<prm0> (type: stri, default: )

paramters list 0

=item B<prm1> (type: stri, default: )

paramters list 0

=item B<prm2> (type: stri, default: )

paramters list 0

=item B<prm3> (type: stri, default: )

paramters list 0

=item B<path> (type: stri, default: )

search path

=back

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV more harsh checks on perl code
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV more perl code quality
	0.09 MV silense all tests
	0.10 MV fix small problems and update java
	0.11 MV perl code quality
	0.12 MV more perl quality
	0.13 MV more perl quality
	0.14 MV revision change
	0.15 MV languages.pl test online
	0.16 MV perl order in packages
	0.17 MV perl packaging
	0.18 MV license issues
	0.19 MV md5 project
	0.20 MV database
	0.21 MV perl module versions in files
	0.22 MV thumbnail user interface
	0.23 MV more thumbnail issues
	0.24 MV website construction
	0.25 MV improve the movie db xml
	0.26 MV web site automation
	0.27 MV SEE ALSO section fix
	0.28 MV move tests to modules
	0.29 MV md5 issues

=head1 SEE ALSO

Meta::Tool::Deb(3), Meta::Tool::Gcc(3), Meta::Tool::Jar(3), Meta::Tool::Rpm(3), Meta::Tool::Tar(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-when going into an implementation (like gcc_dbg_dll):

-check that trg0 has only one string element

-check that this element is a valid shared library name: dlls/gcc/dbg/lib[name].so

-check that there are strings in stc0 (at least 1)

-check that there are no other stuff (prms, other targets, other srcs)

-move all the code here into a library.

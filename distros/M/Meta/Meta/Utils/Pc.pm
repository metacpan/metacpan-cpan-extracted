#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Pc;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::Utils::File::File qw();

our($VERSION,@ISA);
$VERSION="0.29";
@ISA=qw();

#sub clean($);
#sub umount_all($$$);
#sub umount_all_mult($$$);
#sub results($$$$);
#sub make_perl_inte($$$);
#sub writ_perl_inte($$$$);
#sub get_temp_dir();
#sub pc_path($);
#sub TEST($);

#__DATA__

sub clean($) {
	my($data)=@_;
	my(@arra)=split(/\r\n|\r/,$data);
	return(\@arra);
}

sub umount_all($$$) {
	my($pcxx,$demo,$verb)=@_;
	if($verb) {
		Meta::Utils::Output::print("unmounting [".$pcxx."]\n");
	}
	my($comm)="net use";
	my($resu)=results($pcxx,$comm,$demo,$verb);
	for(my($i)=0;$i<=$#$resu;$i++) {
		my($curr)=$resu->[$i];
		if($curr=~/OK|Reconnecting|Unavailable/) {
			my(@arra)=split(" ",$curr);
			my($dire)=$arra[1];
			my($comm)="net use $dire /DELETE";
			if($verb) {
				Meta::Utils::Output::print("doing [".$comm."] on [".$pcxx."]\n");
			}
			if(!$demo) {
				my($code)=Meta::Utils::System::system_nodie("rsh",[$pcxx,$comm]);
				if($code) {
					return(0);
				}
			}
		}
	}
	return(1);
}

sub umount_all_mult($$$) {
	my($list,$demo,$verb)=@_;
	my($scod)=1;
	for(my($i)=0;$i<=$#$list;$i++) {
		my($pcxx)=$list->[$i];
		my($ccod)=umount_all($pcxx,$demo,$verb);
		if(!$ccod) {
			$scod=0;
		}
	}
	return($scod);
}

sub results($$$$) {
	my($pcxx,$comm,$demo,$verb)=@_;
	if($verb) {
		Meta::Utils::Output::print("doing [".$comm."] on [".$pcxx."]\n");
	}
	if(!$demo) {
		my($retu)=Meta::Utils::System::system_out("rsh",[$pcxx,$comm]);
		my($resu)=clean($$retu);
		return($resu);
	}
}

sub make_perl_inte($$$) {
	my($comm,$file,$curr)=@_;
	my(@sing)=split(";",$comm);
	my($outp)="";
	$outp.="#!/usr/bin/perl -w\n";
	$outp.="sub writ_resu_exit(\$\$) {\n";
	$outp.="\tmy(\$file,\$resu)=(\$\_[0],\$\_[1]);\n";
	$outp.="\topen(FILE,\"> \$file\") || die(\"unable to open file [\$file]\");\n";
	$outp.="\tprint FILE \$resu;\n";
	$outp.="\tclose(FILE) || die(\"unable to close file [\$file]\");\n";
	$outp.="\texit(\$resu);\n";
	$outp.="}\n";
	$outp.="sub doit(\$\$) {\n";
	$outp.="\tmy(\$comm,\$file)=(\$\_[0],\$\_[1]);\n";
	$outp.="\tmy(\$resu)=system(\$comm);\n";
	$outp.="\tif(\$resu) {\n";
	$outp.="\t\twrit_resu_exit(\$file,\$resu);\n";
	$outp.="\t}\n";
	$outp.="}\n";
	$outp.="if(\$#ARGV!=0) {\n";
	$outp.="\tdie(\"script: usage script [file]\");\n";
	$outp.="}\n";
	$outp.="my(\$file)=\$ARGV[0];\n";
	$outp.="if(!chdir(\"".$curr."\")) {\n";
	$outp.="\tdie(\"cannot chdir to [".$curr."]\");\n";
	$outp.="}\n";
	for(my($i)=0;$i<=$#sing;$i++) {
		$outp.="doit(\"".$sing[$i]."\",\$file);\n";
	}
	$outp.="writ_resu_exit(\$file,0);\n";
	return($outp);
}

sub writ_perl_inte($$$$) {
	my($comm,$file,$scri,$curr)=@_;
	my($data)=make_perl_inte($comm,$file,$curr);
	Meta::Utils::File::File::save($scri,$data);
}

sub get_temp_dir() {
	my($host)=Meta::Utils::Net::Hostname::part();
	return("/RnD/$host/onpc");
}

sub pc_path($) {
	my($stri)=@_;
	# sub / for \\ (lets not confuse the poor NT too much...)
	$stri=~s/\//\\\\/g;
	return($stri);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Pc - utilities to handle pc junk.

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

	MANIFEST: Pc.pm
	PROJECT: meta
	VERSION: 0.29

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Pc qw();
	my($clean_text)=Meta::Utils::Pc::clean($pc_data);

=head1 DESCRIPTION

This is a library to help you deal with pc junk.
This will umount all dirs in a pc, do pc path conversion and the like.
This is really a drag because PC's have so little capabilities...

=head1 FUNCTIONS

	clean($)
	umount_all($$$)
	umount_all_mult($$$)
	results($$$$)
	make_perl_inte($$$)
	writ_perl_inte($$$$)
	get_temp_dir()
	pc_path($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<clean($)>

This will split pc output according to lines and put it in an array for you.

=item B<umount_all($$$)>

This routine received a pc name and umount all mounts on that pc.

=item B<umount_all_mult($$$)>

This is exactly like the "umount_all" function except the first argument is
a list of pc's to umount and this one calls "umount_all" for each of them.

=item B<results($$$$)>

This routine receives a command to do on the pc and does it,splits the results
into lines and returns the array of lines.

=item B<make_perl_inte($$$)>

This makes a perl interpreter syntax from a command. It is currently quite
simple and I hope it will be sufficient.
The idea is to simulate a real shell on a handicapped MS windoze pc. The only
real tool which is able to do it seems to be perl (and it is certainly
sufficient...).
The parameters are:
0. comm - the command to be executed (could be a sequence of comma separated
	commands).
1. file - the file into which to write the interpreter.
2. curr - the current directory.
3. targ - the list of targets which are to be extracted from the pc.
4. tdir - where is the target directory where temp targets could be stored.

=item B<writ_perl_inte($$$$)>

This writes a perl script out of a command into a file.

=item B<get_temp_dir()>

This gives you the temporary directory (unix style) of work on a pc.

=item B<pc_path()>

This converts a unix string into a pc string.
(converting the god damn slashes...

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

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV introduce docbook into the baseline
	0.08 MV correct die usage
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV revision change
	0.17 MV languages.pl test online
	0.18 MV perl packaging
	0.19 MV md5 project
	0.20 MV database
	0.21 MV perl module versions in files
	0.22 MV movies and small fixes
	0.23 MV thumbnail user interface
	0.24 MV more thumbnail issues
	0.25 MV md5 project
	0.26 MV website construction
	0.27 MV web site automation
	0.28 MV SEE ALSO section fix
	0.29 MV md5 issues

=head1 SEE ALSO

Meta::Utils::File::File(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

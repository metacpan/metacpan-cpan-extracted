#!/bin/echo This is a perl module and should not be run

package Meta::Distrib::Distrib;

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Distrib::Files qw();
use Meta::Distrib::Machines qw();
use Meta::Utils::Net::Rm qw();
use Meta::Utils::Net::Cp qw();
use Meta::Utils::Net::Md qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw();

#sub act($$$$$$$$$);
#sub file_machine($$);
#sub files_machine($$);
#sub file_machines($$);
#sub files_machines($$);
#sub TEST($);

#__DATA__

sub act($$$$$$$$$) {
	my($verb,$demo,$files,$machines,$cdir,$build,$md,$clear,$distrib)=@_;
	my($o_files)=Meta::Distrib::Files->new();
	$o_files->read($files);
	my($o_machines)=Meta::Distrib::Machines->new();
	$o_machines->read($machines);
	if($build) {
		my(@list);
		for(my($i)=0;$i<$o_files->size();$i++) {
			my($curr)=$o_files->getx($i);
			if($curr->get_buil()) {
				push(@list,$curr->get_sour());
			}
		}
		if($#list>=0) {
			if($verb) {
				Meta::Utils::Output::print("doing aeb of [".join(",",@list)."]\n");
			}
			Meta::Utils::System::system("aegis",["-Build",@list]);
		}
	}
	if($md) {
		for(my($i)=0;$i<$o_machines->size();$i++) {
			my($curr)=$o_machines->getx($i);
			my($curr_name)=$curr->get_name();
			my($curr_user)=$curr->get_user();
			my($curr_pass)=$curr->get_password();
			if($verb) {
				Meta::Utils::Output::print("making directory on machine [".$curr_name."]\n");
			}
			Meta::Utils::Net::Md::doit($verb,$demo,$curr_name,$curr_user,$curr_pass,$cdir);
		}
	}
	if($clear) {
		for(my($i)=0;$i<$o_machines->size();$i++) {
			my($curr)=$o_machines->getx($i);
			my($curr_name)=$curr->get_name();
			my($curr_user)=$curr->get_user();
			my($curr_pass)=$curr->get_password();
			if($verb) {
				Meta::Utils::Output::print("clearing machine [".$curr_name."]\n");
			}
			Meta::Utils::Net::Rm::doit($verb,$demo,$curr_name,$curr_user,$curr_pass,$cdir);
		}
	}
	if($distrib) {
		for(my($i)=0;$i<$o_machines->size();$i++) {
			my($curr_mach)=$o_machines->getx($i);
			my($curr_mach_name)=$curr_mach->get_name();
			my($curr_mach_user)=$curr_mach->get_user();
			my($curr_mach_pass)=$curr_mach->get_password();
			Meta::Utils::Output::verbose($verb,"distributing to machine [".$curr_mach_name."]\n");
			for(my($j)=0;$j<$o_files->size();$j++) {
				my($curr_file)=$o_files->getx($j);
				my($curr_file_phys)=$curr_file->get_phys();
				my($curr_file_targ)=$curr_file->get_targ();
				my($curr_file_perm)=$curr_file->get_perm();
				Meta::Utils::Net::Cp::doit(
					$verb,
					$demo,
					$curr_mach_name,
					$curr_mach_user,
					$curr_mach_pass,
					$curr_file_phys,
					$curr_file_targ,
					$curr_file_perm,
				);
			}
		}
	}
}

sub file_machine($$) {
	my($file,$machine)=@_;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Distrib::Distrib - distribute a list of files to other machines.

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

	MANIFEST: Distrib.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Distrib::Distrib qw();
	my($prog)=Meta::Distrib::Distrib::files_machines($file_list,$machine_list);

=head1 DESCRIPTION

This is a library to help you put a set of files on a machine.

=head1 FUNCTIONS

	act($$$$$$$$$)
	file_machine($$)
	files_machine($$)
	file_machines($$)
	files_machines($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<act($$$$$$$$$)>

This will do the actual distribution.

=item B<files_machines($$)>

This will files on a machine for you using a

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
	0.01 MV bring databases on line
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
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
	0.25 MV website construction
	0.26 MV web site automation
	0.27 MV SEE ALSO section fix
	0.28 MV md5 issues

=head1 SEE ALSO

Meta::Distrib::Files(3), Meta::Distrib::Machines(3), Meta::Utils::Net::Cp(3), Meta::Utils::Net::Md(3), Meta::Utils::Net::Rm(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-currently users can see the output from the aegis build command - block that.

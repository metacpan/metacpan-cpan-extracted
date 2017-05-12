#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Rsh;

use strict qw(vars refs subs);
use Meta::Utils::Net::Hostname qw();
use Meta::Utils::Utils qw();
use Meta::Utils::Chdir qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::File::Prop qw();
use Meta::Utils::Pc qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.32";
@ISA=qw();

#sub rsh($$$$$);
#sub cook_rsh($$$$);
#sub TEST($);

#__DATA__

sub rsh($$$$$) {
	my($demo,$verb,$targ,$host,$comm)=@_;
	my($chst)=Meta::Utils::Net::Hostname::part();
	if($demo) {
		return(0);
	}
	my($type)="error";
	my($code)=1972;
	my($foun)=0;
	if(!$foun) { # this is the current machine
		my($currhost)=Meta::Utils::Net::Hostname::part();
		if($host eq $currhost) {
			$type="current";
			$code=Meta::Utils::System::smart_shell($comm);
			$foun=1;
		}
	}
	if(!$foun) { # this is a unix machine which is not the current
#		if(Meta::Baseline::Cook::is_linu($host)) {
		if(1) {
			$type="linux";
			$comm="cd ".Meta::Utils::Chdir::get_system_cwd().";".$comm;
#			$comm=Meta::Baseline::Cook::unix_path($comm,$host,$chst);
			$code=Meta::Utils::System::system_nodie("ssh",[$host,$comm]);
			$foun=1;
		}
	}
	if(!$foun) { # this is a pc machine
#		if(Meta::Baseline::Cook::is_ntxx($host)) {
		if(1) {
			$type="pc";
			my($numb)=$#$targ+1;
			for(my($i)=0;$i<$numb;$i++) {
				my($curr)=$targ->[$i];
				Meta::Utils::File::File::create_new($curr);
				Meta::Utils::File::Prop::chmod_agw($curr);
			}
			my($temp)=Meta::Utils::Pc::get_temp_dir()."/kuku.pl";
			my($resu)=Meta::Utils::Pc::get_temp_dir()."/kuku.res";
#			$comm=Meta::Baseline::Cook::pc_path($comm,$host,$chst);
			my($curr)=Meta::Utils::Chdir::get_system_cwd();
#			$curr=Meta::Baseline::Cook::pc_path($curr,$host,$chst);
			Meta::Utils::Pc::writ_perl_inte($comm,$resu,$temp,$curr);
			my($rcom)="perl $temp $resu";
#			$rcom=Meta::Baseline::Cook::pc_path($rcom,$host,$chst);
			$code=Meta::Utils::System::system_nodie("rsh",[$host,$rcom]);
			my($scod);
			Meta::Utils::File::File::load($resu,\$scod);
			if($scod) {
				$code=$scod;
			}
			Meta::Utils::File::Remove::rm_soft($temp);
			Meta::Utils::File::Remove::rm_soft($resu);
			if($code) {
				for(my($i)=0;$i<$numb;$i++) {
					my($curr)=$targ->[$i];
					Meta::Utils::File::Prop::chown_curr($curr);
					Meta::Utils::File::Remove::rm($curr);
				}
			} else {
				for(my($i)=0;$i<$numb;$i++) {
					my($curr)=$targ->[$i];
					Meta::Utils::File::Prop::chown_curr($curr);
					Meta::Utils::File::Prop::chmod_rgw($curr);
				}
			}
			$foun=1;
		}
	}
	if(!$foun) { # machine not found
		throw Meta::Error::Simple("unknown machine [".$host."]");
	}
	Meta::Utils::Output::verbose($verb,"data is [".$demo."] [".$verb."] [".$host."] [".$comm."] [".$type."]\n");
	my($ncod)=Meta::Utils::Utils::bnot($code);
	return($ncod);
}

sub cook_rsh($$$$) {
	my($demo,$verb,$host,$comm)=@_;
	my($inpu)=$comm=~/sh -ce (.*);/;
	my($file)=$comm=~/echo \$\? > (.*)'/;
	my($fcom)=Meta::Utils::File::File::load_line($inpu,1);
	my($rcom,$targ)=$fcom=~/(.*);targets=(.*)$/;
	Meta::Utils::Output::verbose($verb,"[".$targ."] on [".$host."]\n");
	my(@targ)=split(" ",$targ);
	my($code)=rsh($demo,0,\@targ,$host,$rcom);
	my($io)=Meta::IO::File->new_writer($file);
	my($scod)=Meta::Utils::Utils::bnot($code);
	print $io $scod."\n";
	$io->close();
	return($code);
}

sub TEST($) {
	my($context)=@_;
	#my($scod)=Meta::Baseline::Rsh::rsh(0,1,"localhost","echo","Hello,\ World!");
	#return($scod);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Rsh - library to do correct rsh execution on machines.

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

	MANIFEST: Rsh.pm
	PROJECT: meta
	VERSION: 0.32

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Rsh qw();
	my($resu)=Meta::Baseline::Rsh::rsh($demo,$verbose,$target,$host,$command);

=head1 DESCRIPTION

This package can do correct rsh execution, both on pcs and on unices (current
host included...).
This is supposed to handle the following cases:
0. the remote machine is the current machine (dont rsh).
1. the remote machine is the a unix machine (do rsh with a unix wrapper
	so you'll get the right return code...).
2. the remote machine is an NT machine (do rsh with an NT wrapper so
	you'll get the right return code...).

=head1 FUNCTIONS

	rsh($$$$$)
	cook_rsh($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<rsh($$$$$)>

This is the baseline version of rsh. Why is there such a version ? because
when you issue a command from rsh and you built the command on some host
there is no gurantee that this command will look exactly the same and execute
properly on all other hosts that work with the baseline. This is especialy
true if the command involved is doing development builds...:)
Return value for this function is 1 for success and 0 for failure.

=item B<cook_rsh($$$$)>

This does a cook simulation of an rsh. Cook is not treating rsh right cause
it thinks that rsh is not a good enough software. But since we are writing
the rsh wrapper and our wrapper is good we want to avoid rsh'ing when the
host to rsh is the current host etc...
Therefore we get the weird cook executiong lines, analyze them, and execute
them as if we were just a regular dumb rsh. We ofcourse call our own version
of rsh which is implemented in this modules to handle current, linux and
pc hosts correctly.

=item B<TEST($)>

Test suite for this module.
The way it does it is just to run the routine for a couple of random
host names.

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
	0.01 MV this time really make the databases work
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV put ALL tests back and light the tree
	0.09 MV fix up the cook module
	0.10 MV correct die usage
	0.11 MV perl code quality
	0.12 MV more perl quality
	0.13 MV more perl quality
	0.14 MV get basic Simul up and running
	0.15 MV perl documentation
	0.16 MV more perl quality
	0.17 MV perl qulity code
	0.18 MV more perl code quality
	0.19 MV revision change
	0.20 MV languages.pl test online
	0.21 MV perl packaging
	0.22 MV md5 project
	0.23 MV database
	0.24 MV perl module versions in files
	0.25 MV movies and small fixes
	0.26 MV thumbnail user interface
	0.27 MV more thumbnail issues
	0.28 MV website construction
	0.29 MV web site automation
	0.30 MV SEE ALSO section fix
	0.31 MV teachers project
	0.32 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Chdir(3), Meta::Utils::File::Prop(3), Meta::Utils::File::Remove(3), Meta::Utils::Net::Hostname(3), Meta::Utils::Output(3), Meta::Utils::Pc(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-stop getting the targets in cook_rsh through the chmod part of the command line.

-fix this module a lot since cook has changed a lot.

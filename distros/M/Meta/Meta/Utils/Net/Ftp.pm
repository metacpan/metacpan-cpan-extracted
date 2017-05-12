#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Net::Ftp;

use strict qw(vars refs subs);
use Net::FTP qw();
use Meta::Utils::System qw();
use Meta::Utils::File::Fs qw();
use Meta::Utils::Output qw();
use Meta::Class::MethodMaker qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.16";
@ISA=qw();

#sub BEGIN();
#sub do_login($);
#sub do_logout($);
#sub do_put_mkdir($$$);
#sub get_fs_1($);
#sub get_fs_2($);
#sub get_fs_3($);
#sub get_mdtm($$$);
#sub do_delete($$);
#sub do_rmdir($$);
#sub do_cwd($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_ftp",
		-java=>"_site",
		-java=>"_debug",
		-java=>"_name",
		-java=>"_password",
		-java=>"_mode",
	);
}

sub do_login($) {
	my($self)=@_;
	my($ftp)=Net::FTP->new($self->get_site(),Debug=>$self->get_debu());
	if(!$ftp) {
		throw Meta::Error::Simple("unable to create ftp object with error [".$@."]");
	}
	$self->set_ftpx($ftp);
	$self->get_ftpx()->type($self->get_mode());
	my($code)=$self->get_ftpx()->login($self->get_name(),$self->get_password());
	if(!$code) {
		throw Meta::Error::Simple("unable to login with error [".$self->get_ftpx()->message()."]");
	}
}

sub do_logout($) {
	my($self)=@_;
	my($code)=$self->get_ftpx()->quit();
	if(!$code) {
		throw Meta::Error::Simple("unable to quit with message [".$self->get_ftpx()->message()."]");
	}
}

sub do_put_mkdir($$$) {
	my($self,$abso,$file)=@_;
	my($dire)=File::Basename::dirname($file);
	if($dire ne "") {
		my($cod0)=$self->get_ftpx()->mkdir($dire,1);
	if(!$cod0) {
		throw Meta::Error::Simple("unable to mkdir [".$dire."] with message [".$self->get_ftpx()->message()."]");
		}
	}
	my($cod1)=$self->get_ftpx()->put($abso,$file);
	if(!$cod1) {
		throw Meta::Error::Simple("unable to put [".$file."] with message [".$self->get_ftpx()->message()."]");
	}
}

sub get_fs_1($) {
	my($self)=@_;
	my($fs)=Meta::Utils::File::Fs->new();
	$fs->set_type("directory");
	my(@list)=$self->get_ftpx()->ls("-R");
	my($cdir)=$fs;
	for(my($i)=0;$i<=$#list;$i++) {
		my($curr)=$list[$i];
		if($curr ne "") {
			#Meta::Utils::Output::print("curr is [".$curr."]\n");
			if($curr=~/^.+\..*$/) {#this is a file FIXME
				#Meta::Utils::Output::print("creating file [".$curr."]\n");
				#Meta::Utils::Output::print("size is [".$cdir->size()."]\n");
				my($file)=$curr;
				$cdir->create_single_file($file);
			} else {
				if($curr=~/\:$/) {
					my($dire)=($curr=~/^\.\/(.*):$/);#nbci specific
					#Meta::Utils::Output::print("creating directory and setting current [".$dire."]\n");
					$cdir=$fs->create_dir($dire);
				}
			}
			#Meta::Utils::Output::print("=======================\n");
			#$fs->print(0);
			#Meta::Utils::Output::print("=======================\n");
		}
	}
	return($fs);
}

sub get_fs_2($) {
	my($self)=@_;
	my($fs)=Meta::Utils::File::Fs->new();
	$fs->set_type("directory");
	my(@list)=$self->get_ftpx()->ls("-R");
	my($cdir)=$fs;
	for(my($i)=0;$i<=$#list;$i++) {
		my($curr)=$list[$i];
		if($curr ne "") {
			#Meta::Utils::Output::print("curr is [".$curr."]\n");
			if($curr=~/\./) {#this is a file FIXME
				#Meta::Utils::Output::print("creating file [".$curr."]\n");
				my($file)=$curr;
				$cdir->create_single_file($file);
			} else {
				if($curr=~/\:$/) {
					chop($curr);
					#Meta::Utils::Output::print("setting current to [".$curr."]\n");
					my($dire)=$curr;
					$cdir=$fs->get_dir($dire);
				} else {
					my($dire)=$curr;
					#Meta::Utils::Output::print("creating single [".$curr."]\n");
					$cdir->create_single_dir($curr);
				}
			}
			#Meta::Utils::Output::print("=======================\n");
			#$fs->print(0);
			#Meta::Utils::Output::print("=======================\n");
		}
	}
	return($fs);
}

sub get_fs_3($) {
	my($self)=@_;
	my($fs)=Meta::Utils::File::Fs->new();
	$fs->set_type("directory");
	my(@list)=$self->get_ftpx()->dir("-R");
	my($cdir)=$fs;
	for(my($i)=0;$i<=$#list;$i++) {
		my($curr)=$list[$i];
		if($curr=~/\:$/) {#this is a directory
			chop($curr);
			$cdir=$fs->create_dir($curr);
			#Meta::Utils::Output::print("curr is [".$curr."]\n");
		}
		if($curr=~/^drwx/) {#directory in the currnt
			my($perm,$link,$user,$grou,$size,$monx,$dayx,$hour,$name)=
				($curr=~/^(..........)\s+(\d+)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d\d\:\d\d)\s+(.+)$/);
			#Meta::Utils::Output::print("perm is [".$perm."]\n");
			#Meta::Utils::Output::print("link is [".$link."]\n");
			#Meta::Utils::Output::print("user is [".$user."]\n");
			#Meta::Utils::Output::print("grou is [".$grou."]\n");
			#Meta::Utils::Output::print("size is [".$size."]\n");
			#Meta::Utils::Output::print("monx is [".$monx."]\n");
			#Meta::Utils::Output::print("dayx is [".$dayx."]\n");
			#Meta::Utils::Output::print("hour is [".$hour."]\n");
			#Meta::Utils::Output::print("name is [".$name."]\n");
			if(($name ne ".") && ($name ne "..")) {
				$cdir->create_single_dir($name);
			}
			#my($time)=gettime($monx,$dayx,$hour);
			#$cdir->set_modi($time);
		}
		if($curr=~/^-rw-/) {#file in the currnt
			my($perm,$link,$user,$grou,$size,$monx,$dayx,$hour,$name)=
				($curr=~/^(..........)\s+(\d+)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d\d\:\d\d)\s+(.+)$/);
			$cdir->create_single_file($name);
			#my($time)=gettime($monx,$dayx,$hour);
			#$cdir->set_modi($time);
		}
	}
	return($fs);
}

sub get_mdtm($$$) {
	my($self,$fsxx,$pref)=@_;
	for(my($i)=0;$i<$fsxx->size();$i++) {
		my($key)=$fsxx->key($i);
		my($val)=$fsxx->val($i);
		my($curr);
		if($pref ne "") {
			$curr=$pref."/".$key;
		} else {
			$curr=$key;
		}
		#Meta::Utils::Output::print("curr is [".$curr."]\n");
		if($val->is_file()) {
			my($time)=$self->get_ftpx()->mdtm($curr);
			#Meta::Utils::Output::print("time is [".$time."]\n");
			$val->set_modi($time);
		}
		if($val->is_dire()) {
			$self->get_mdtm($val,$curr);
		}
	}
}

sub do_delete($$) {
	my($self,$file)=@_;
	my($resu)=$self->get_ftpx()->delete($file);
	if(!$resu) {
		throw Meta::Error::Simple("unable to remove file [".$file."]");
	}
}

sub do_rmdir($$) {
	my($self,$dire)=@_;
	my($resu)=$self->get_ftpx()->rmdir($dire);
#	if(!$resu) {
#		throw Meta::Error::Simple("unable to remove directory [".$dire."]");
#	}
}

sub do_cwd($$) {
	my($self,$dire)=@_;
	my($resu)=$self->get_ftpx()->cwd($dire);
	if(!$resu) {
		throw Meta::Error::Simple("unable to cwd to directory [".$dire."]");
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Net::Ftp - object to enhance Net::FTP.

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

	MANIFEST: Ftp.pm
	PROJECT: meta
	VERSION: 0.16

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Net::Ftp qw();
	my($object)=Meta::Utils::Net::Ftp->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object is here to enhance the Net::FTP object which is out there
for perl.

Note: it would have been convenient to just inherit from Net::FTP but
Net::FTP is not a hash. Therefore we just store Net::FTP internally.

Another solution would be to route methods to that class using
Meta::Class::MethodMaker which I plan to do in the future.

=head1 FUNCTIONS

	BEGIN()
	do_login($)
	do_logout($)
	do_put_mkdir($$$)
	get_fs_1($)
	get_fs_2($)
	get_fs_3($)
	get_mdtm($$$)
	do_delete($$)
	do_rmdir($$)
	do_cwd($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is an initialization code which creates get/set methods for the
following attributes:
ftp - the Net::FTP object that this object uses.
site - the remote site. 
debug - set debugging ?.
name - user name for the remote site.
password - password at the remote site.
mode - the transfer mode (text/binary) for the current session.

=item B<do_login($)>

This will login into the remote host.

=item B<do_logout($)>

This will logout the session.

=item B<put_mkdir($$$)>

This method uploads a file to the ftp archive and creates a directory if it is
neccessary.

=item B<get_fs_1($)>

This method returns a Meta::Utils::File::Fs object which represents
remote site. See that objects documentation about what you can
do with it.
The methos is to issue an "ls -R" command to the server and parse
the results. Each directory is postfixed by a ":" and the files are not.
The output from an ls -R command is far from satisfactory for what I'm
doing here so the code here is coyote ugly. Don't mind it cause
it does it's job in the cases where we need them. If you feel that
you need something better It's probably a good idea to write code
to recurse the site yourself or find a better command to list the
entire content of the site.

=item B<get_fs_2($)>

This method returns a Meta::Utils::File::Fs object which represents
remote site. See that objects documentation about what you can
do with it.
The methos is to issue an "ls -R" command to the server and parse
the results. Each directory is postfixed by a ":" and the files are not.
The output from an ls -R command is far from satisfactory for what I'm
doing here so the code here is coyote ugly. Don't mind it cause
it does it's job in the cases where we need them. If you feel that
you need something better It's probably a good idea to write code
to recurse the site yourself or find a better command to list the
entire content of the site.

=item B<get_fs_3()>

This method gets a file system using the dir("-R") method.

=item B<get_mdtm($$$>

This method receives an ftp type object and an Fs type object.
The method will fill all modification times for the Fs from the
remote serves by issuing mdtm commands.
Mind you, this method only gets times for files and not directories.

=item B<do_delete($$)>

Remove a file from the remote FTP archive.

=item B<do_rmdir($$)>

This method will remove a directory on the remote FTP archive for you.
Take heed that the error checking code in this routine is disabled
because the rmdir routine sometimes returns a fail value when the
request is legal and is even executed well!!! (is that a problem
on my end with version of perl compiler or something ?)

=item B<do_cwd($$)>

This method does a cwd command.

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

	0.00 MV upload system revamp
	0.01 MV do some book work
	0.02 MV writing papers
	0.03 MV perl packaging
	0.04 MV xml
	0.05 MV PDMT
	0.06 MV md5 project
	0.07 MV database
	0.08 MV perl module versions in files
	0.09 MV movies and small fixes
	0.10 MV thumbnail user interface
	0.11 MV more thumbnail issues
	0.12 MV website construction
	0.13 MV web site development
	0.14 MV web site automation
	0.15 MV SEE ALSO section fix
	0.16 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Class::MethodMaker(3), Meta::Utils::File::Fs(3), Meta::Utils::Output(3), Meta::Utils::System(3), Net::FTP(3), strict(3)

=head1 TODO

-make the get_fs_3 routine also set the modification times (will save runtime).

-make the get_fs_3 more robust (the regular expressions there for paring the output of dir("-R") are a little too much...

-return the error checking code into the do_rmdir method. It's just that some FTP servers return a "fail" value when they haven't failed in removing the remote directory.

-route methods to Net::FTP using MethodMaker or something.

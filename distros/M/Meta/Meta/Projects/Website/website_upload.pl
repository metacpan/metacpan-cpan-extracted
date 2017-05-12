#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Cook qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::Time qw();
use Meta::Utils::Hash qw();
use Meta::Utils::Net::Ftp qw();
use Time::localtime qw();

my($debug,$verbose,$doit,$mod,$upload,$remove,$empty_dir,$mode,$site_name,$file,$pass_file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("debug","debug the connection ?",0,\$debug);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->def_bool("doit","should I really transfer the files ?",1,\$doit);
$opts->def_bool("mod","should I only upload modified files ?",1,\$mod);
$opts->def_bool("upload","should I upload files ?",1,\$upload);
$opts->def_bool("remove","should I remove old files ?",1,\$remove);
$opts->def_bool("empty_dir","should I remove empty directories ?",1,\$empty_dir);
$opts->def_stri("mode","what type of transfer should I use ?","binary",\$mode);
$opts->def_stri("site_name","name of site",undef,\$site_name);
$opts->def_stri("file","file name to transfer","html/temp/html/projects/Website/main.html",\$file);
$opts->def_modu("passwords","passwords file","xmlx/passwords/passwords.xml",\$pass_file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($sites)=Meta::Info::Password->new_modu($pass_file);
my($my_site)=$sites->get($site_name);
my($site)=$my_site->get_ftp_address();
my($user)=$my_site->get_ftp_user();
my($pass)=$my_site->get_ftp_password();

#get the graph describing the dependency information for the file.
if($verbose) {
	Meta::Utils::Output::print("calculating the files to be passed\n");
}
my($graph)=Meta::Baseline::Cook::read_deps_full($file);
#prepare a list for all the nodes dependant
my($files)=[ $file ];
my($hash)={ $file,defined };
#get the list and hash using the graph method
$graph->all_ou($file,$hash,$files);

my($ftp)=Meta::Utils::Net::Ftp->new();
$ftp->set_site($site);
$ftp->set_debu($debug);
$ftp->set_name($site_name);
$ftp->set_password($pass);
$ftp->set_mode($mode);
if($verbose) {
	Meta::Utils::Output::print("logging in\n");
}
$ftp->do_login();

if($verbose) {
	Meta::Utils::Output::print("doing CWD\n");
}
my($res)=$ftp->do_cwd("www.veltzer.f2s.com");

#first lets get an image of the remote site.
#this takes a little time (but not a lot)
if($verbose) {
	Meta::Utils::Output::print("getting file system information\n");
}
my($fs)=$ftp->get_fs_3();
#now get their modification times
if($verbose) {
	Meta::Utils::Output::print("getting modification times\n");
}
$ftp->get_mdtm($fs,"");

#you can uncomment this for debug purposes
#$fs->print();
#Meta::Utils::System::exit_ok();

if($upload && $doit) {
	for(my($i)=0;$i<=$#$files;$i++) {
		my($curr)=$files->[$i];
		my($abso)=Meta::Baseline::Aegis::which($curr);
		if($verbose) {
			Meta::Utils::Output::print("working on [".$curr."]\n");
		}
		if($doit) {
			my($exec)=1;
			if($mod) {
				if($fs->has_file($curr)) {#file is on the remote site
					my($fh)=$fs->get_file($curr);
					my($time)=$fh->get_modi();
					my($my_time)=Meta::Utils::File::Time::time($abso);
					if($verbose) {
						my($c_my_time)=Time::localtime::ctime($my_time);
						my($c_time)=Time::localtime::ctime($time);
						Meta::Utils::Output::print("my_time is [".$c_my_time."]\n");
						Meta::Utils::Output::print("time is [".$c_time."]\n");
					}
					if($my_time>$time) {
						$exec=1;
						$fh->set_modi($my_time);
					} else {
						$exec=0;
					}
				} else {#the file is not on the remote site
					$exec=1;
					my($file)=$fs->create_file($curr);
					my($my_time)=Meta::Utils::File::Time::time($curr);
					$file->set_modi($my_time);
				}
			}
			if($exec) {
				if($verbose) {
					Meta::Utils::Output::print("transferring [".$curr."]\n");
				}
				$ftp->do_put_mkdir($abso,$curr);
			}
		}
	}
}
$hash->{"index.html"}=defined;#FIXME
if($remove && $doit) {
	my(%listhash);
	$fs->get_all_files_hash(\%listhash,"");
	Meta::Utils::Hash::remove_hash(\%listhash,$hash,1);
	while(my($file,$val)=each(%listhash)) {
		if($verbose) {
			Meta::Utils::Output::print("removing file [".$file."]\n");
		}
		$ftp->do_delete($file);
		$fs->remove_file($file);
	}
}
if($empty_dir && $doit) {
	my(@empty_dirs);
	$fs->get_all_empty_dirs(\@empty_dirs,"");
	for(my($i)=0;$i<=$#empty_dirs;$i++) {
		my($curr)=$empty_dirs[$i];
		if($verbose) {
			Meta::Utils::Output::print("removing directory [".$curr."]\n");
		}
		$ftp->do_rmdir($curr);
		$fs->remove_last_dir($curr);
	}
}
$ftp->do_logout();
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

website_upload.pl - upload a web site.

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

	MANIFEST: website_upload.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	website_upload.pl [options]

=head1 DESCRIPTION

This script updates a web site from a list of files which need to be uploaded.
The script uses the FTP protocol to achieve this. Since the tool is connected
to the Source Management System it uses that information to derive which
htmls or other files depend on the htmls that you want to transfer and
trasfers them too. The benefit is that all you need to do is point this
script to the root of the site. You can, ofcourse, not use this feature.
Another features is that this script will only update files which are
not up to date and remove files which no longer need to be at the
remote site (by comparing what's on the remote site with the inventory
list that he constructed on this side). Many options are supported.

Note: because of bugs in some ftp servers which do not calculate the
avilable space correctly the default value for relog here is 1 and
therefore the transfer will open a new ftp session for each file.
This causes the remote server to recalc the available space. This
causes some lag but gives the assurance that a single run of this
script will do what it's supposed to do. When saner FTP server
arrive on the scene this variable (and indeed the entire code
which supports this behavior) should be removed.

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

=item B<debug> (type: bool, default: 0)

debug the connection ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<doit> (type: bool, default: 1)

should I really transfer the files ?

=item B<mod> (type: bool, default: 1)

should I only upload modified files ?

=item B<upload> (type: bool, default: 1)

should I upload files ?

=item B<remove> (type: bool, default: 1)

should I remove old files ?

=item B<empty_dir> (type: bool, default: 1)

should I remove empty directories ?

=item B<mode> (type: stri, default: binary)

what type of transfer should I use ?

=item B<site_name> (type: stri, default: )

name of site

=item B<file> (type: stri, default: html/temp/html/projects/Website/main.html)

file name to transfer

=item B<passwords> (type: modu, default: xmlx/passwords/passwords.xml)

passwords file

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

	0.00 MV some chess work
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV thumbnail user interface
	0.05 MV more thumbnail issues
	0.06 MV website construction
	0.07 MV improve the movie db xml
	0.08 MV web site development
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV teachers project
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Cook(3), Meta::Utils::File::Time(3), Meta::Utils::Hash(3), Meta::Utils::Net::Ftp(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Time::localtime(3), strict(3)

=head1 TODO

-remove old empty directories too.

-all the code here should go into some library.

-put all the site list getting code into a library for ftp.

-try to use the mdel command instead of the del command to remove all the junk files in one round.

-try to use the mput command instead of the put command to put all the files in one round.

-when updating new files which were not there working with file modification times does not
	do the job.

-work with a filesystem encapsulating object.

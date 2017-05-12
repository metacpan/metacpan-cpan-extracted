#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Utils::Net::Ftp qw();
use Meta::Info::Passwords qw();

my($debug,$verbose,$remove_files,$remove_dirs,$site_name,$ftp_name);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("debug","debug the connection ?",0,\$debug);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->def_bool("remove","should I files ?",1,\$remove_files);
$opts->def_bool("empty_dir","should I remove directories ?",1,\$remove_dirs);
$opts->def_stri("site_name","what site name should I contact ?",undef,$site_name);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($module)=Meta::Development::Module->new_name("xmlx/passwords/passwords.xml");
my($sites)=Meta::Info::Passwords->new_modu($module);
my($site)=$sites->get_site($site_name);
my($ftp_address)=$site->ftp_address();
my($ftp_user)=$site->ftp_user();
my($ftp_password)=$site->ftp_password();

my($ftp)=Meta::Utils::Net::Ftp->new();
$ftp->set_site($ftp_address);
$ftp->set_debug($debug);
$ftp->set_name($ftp_name);
$ftp->set_password($ftp_password);

if($verbose) {
	Meta::Utils::Output::print("logging in\n");
}
$ftp->do_login();

#first lets get an image of the remote site.
if($verbose) {
	Meta::Utils::Output::print("getting file system information\n");
}
my($fs)=$ftp->get_fs_1();

#you can uncomment this for debu purposes
#$fs->print();
#Meta::Utils::System::exit_ok();

#lets remove all the files
if($remove_files) {
	my(%listhash);
	$fs->get_all_files_hash(\%listhash,"");
	delete($listhash{"index.html"});
	while(my($file,$val)=each(%listhash)) {
		if($verbose) {
			Meta::Utils::Output::print("removing file [".$file."]\n");
		}
		$ftp->do_delete($file);
		$fs->remove_file($file);
	}
}
#lets remove all the directories
if($remove_dirs) {
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

website_cleanout.pl - cleanout an ftp site.

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

	MANIFEST: website_cleanout.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	website_cleanout.pl [options]

=head1 DESCRIPTION

Give this script an ftp site, user and password and
it will clean it out for you. You can also specify
a list of special files which you want kept.

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

=item B<remove> (type: bool, default: 1)

should I files ?

=item B<empty_dir> (type: bool, default: 1)

should I remove directories ?

=item B<site_name> (type: stri, default: )

what site name should I contact ?

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

Meta::Info::Passwords(3), Meta::Utils::Net::Ftp(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

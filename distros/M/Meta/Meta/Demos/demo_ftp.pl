#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Net::FTP qw();
use Meta::Utils::Output qw();

my($debug,$site_name,$pass_file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("debug","debug the connection ?",1,\$debug);
$opts->def_stri("site_name","which site to contact ?",undef,\$site_name);
$opts->def_modu("pass_file","which passwords file","xmlx/passwords/passwords.xml",\$pass_file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($sites)=Meta::Info::Password->new_modu($pass_file);
my($site)=$sites->get($site_name);
my($ftp_address)=$site->get_ftp_address();
my($ftp_user)=$site->get_ftp_user();
my($ftp_password)=$site->get_ftp_password();

Meta::Utils::Output::print("creating object\n");
my($ftp)=Net::FTP->new($ftp_address,Debug=>$debug);
Meta::Utils::Output::print("logging in\n");
$ftp->login($ftp_user,$ftp_password);
Meta::Utils::Output::print("doing cwd\n");
my($res0)=$ftp->cwd("/");
Meta::Utils::Output::print("res0 is [".$res0."]\n");
my(@list)=$ftp->dir("-R");
for(my($i)=0;$i<=$#list;$i++) {
	my($curr)=$list[$i];
	Meta::Utils::Output::print($curr."\n");
}
#Meta::Utils::Output::print("getting data\n");
#my($time)=$ftp->mdtm("index.html");
#Meta::Utils::Output::print("time is [".$time."]\n");
#Meta::Utils::Output::print("removing dir\n");
#my($resu)=$ftp->rmdir("gg/hh");
#Meta::Utils::Output::print("resu is [".$resu."]\n");
Meta::Utils::Output::print("logging out\n");
$ftp->quit();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

demo_ftp.pl - demo Net::FTP capabilities.

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

	MANIFEST: demo_ftp.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	ftp.pl [options]

=head1 DESCRIPTION

This program opens an FTP session and does some things. You can use
it to explore Net::FTP capabilities.
Currently this just logs in, gets data about modification time
of the index.html file and logs out.

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

=item B<debug> (type: bool, default: 1)

debug the connection ?

=item B<site_name> (type: stri, default: )

which site to contact ?

=item B<pass_file> (type: modu, default: xmlx/passwords/passwords.xml)

which passwords file

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

	0.00 MV finish papers
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Net::FTP(3), strict(3)

=head1 TODO

Nothing.

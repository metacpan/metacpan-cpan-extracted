#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Utils qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();
use Meta::Archive::Tar qw();
use Meta::Template::Sub qw();
#use GnuPG qw();
use Net::SCP qw();
use Meta::Utils::File::Remove qw();
use Error qw(:try);

my($enum)=Meta::Baseline::Aegis::get_enum();

my($verb,$tarf,$dirf,$type,$author_file,$enc,$armor,$sign,$send,$remote_dir);

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","verbose or quiet ?",0,\$verb);
$opts->def_newf("tarfile","what file to backup to","[% project %]_[% change %]_[% time %].tar.gz",\$tarf);
$opts->def_stri("localdir","what directory to backup to ?","[% home_dir %]/backups",\$dirf);
$opts->def_enum("type","what type of backup ?",$enum->get_default(),\$type,$enum);
$opts->def_modu("author","author XML definition file","xmlx/author/author.xml",\$author_file);
$opts->def_bool("encrypt","encrypt the result ?",1,\$enc);
$opts->def_bool("armor","put ascii armor on encrypted files ?",0,\$armor);
$opts->def_bool("sign","sign the encrypted files ?",0,\$sign);
$opts->def_bool("send","send copy to internet ?",0,\$send);
$opts->def_stri("remote_dir","remote directory where backups are stored","backups",\$remote_dir);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$tarf=Meta::Template::Sub::interpolate($tarf);
$dirf=Meta::Template::Sub::interpolate($dirf);

my($list);
Meta::Utils::Output::verbose($verb,"started getting file list\n");
if($enum->is_selected($type,"change")) {
	$list=Meta::Baseline::Aegis::change_files_list(1,1,1,1,1,0);
}
if($enum->is_selected($type,"project")) {
	$list=Meta::Baseline::Aegis::project_files_list(1,1,0);
}
if($enum->is_selected($type,"source")) {
	$list=Meta::Baseline::Aegis::source_files_list(1,1,0,1,1,0);
}
Meta::Utils::Output::verbose($verb,"finished getting file list\n");
my($scod);
Meta::Utils::Output::verbose($verb,"started tarring\n");
my($tar)=Meta::Archive::Tar->new();
for(my($i)=0;$i<=$#$list;$i++) {
	my($curr)=$list->[$i];
	$tar->add_deve($curr,$curr);
}
Meta::Utils::Output::verbose($verb,"finished tarring\n");
$scod=$tar->write($dirf."/".$tarf);
if($enc) {
#	my($author)=Meta::Info::Author->new_modu($author_file);
#	my($enc_file)=$dirf."/".$tarf.".gpg";
#	my($gpg)=GnuPG->new();
#	Meta::Utils::Output::verbose($verb,"started encrypting\n");
#	$gpg->encrypt(
#		plaintext=>$dirf."/".$tarf,
#		output=>$enc_file,
#		recipient=>$author->get_default_email(),
#		armor=>$armor,
#		sign=>$sign,
#		passphrase=>$author->get_default_passphrase(),
#	);
#	Meta::Utils::Output::verbose($verb,"finished encrypting\n");
#	if($send) {
#		Meta::Utils::Output::verbose($verb,"started sending\n");
#		my($user)=$author->get_sourceforge_user();
#		my($host)=$author->get_sourceforge_ssh();
#		my($addr)=$user."@".$host.":".$remote_dir."/".$tarf.".gpg";
#		Meta::Utils::Output::verbose($verb,"addr is [".$addr."]\n");
#		my($scp)=Net::SCP->new($host,$user);
#		my($res)=$scp->scp($enc_file,$addr);
#		Meta::Utils::Output::verbose($verb,"res is [".$res."]\n");
#		if(!$res) {
#			throw Meta::Error::Simple("cannot put with error [".$scp->{errstr}."]");
#		}
#		Meta::Utils::Output::verbose($verb,"finished sending\n");
#	}
#	Meta::Utils::File::Remove::rm($enc_file);
}

Meta::Utils::System::exit($scod);

__END__

=head1 NAME

base_aegi_backup.pl - backup your change to a tar.gz file.

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

	MANIFEST: base_aegi_backup.pl
	PROJECT: meta
	VERSION: 0.42

=head1 SYNOPSIS

	base_aegi_backup.pl

=head1 DESCRIPTION

This script backs up aegis related files to a .tar.gz or tar.bz2 file.
It uses the Archive::Tar perl module to create the archive.
This script works in one of several ways:
1. change: it backs up all the change files.
2. project: it backs up the baseline (with diregard to change).
3. source: it backs up the super position of change on project.
The script uses the Meta::Baseline::Aegis module to get the information
from Aegis regarding which files are to be backed up.

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

verbose or quiet ?

=item B<tarfile> (type: newf, default: [% project %]_[% change %]_[% time %].tar.gz)

what file to backup to

=item B<localdir> (type: stri, default: [% home_dir %]/backups)

what directory to backup to ?

=item B<type> (type: enum, default: source)

what type of backup ?

options:
	change - just files from the current change
	project - just files from the current baseline
	source - complete source manifest

=item B<author> (type: modu, default: xmlx/author/author.xml)

author XML definition file

=item B<encrypt> (type: bool, default: 1)

encrypt the result ?

=item B<armor> (type: bool, default: 0)

put ascii armor on encrypted files ?

=item B<sign> (type: bool, default: 0)

sign the encrypted files ?

=item B<send> (type: bool, default: 0)

send copy to internet ?

=item B<remote_dir> (type: stri, default: backups)

remote directory where backups are stored

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
	0.01 MV bring databases on line
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV more harsh checks on perl code
	0.06 MV fix todo items look in pod documentation
	0.07 MV make all tests real tests
	0.08 MV more on tests/more checks to perl
	0.09 MV fix all tests change
	0.10 MV more on tests
	0.11 MV silense all tests
	0.12 MV more perl quality
	0.13 MV correct die usage
	0.14 MV perl code quality
	0.15 MV more perl quality
	0.16 MV more perl quality
	0.17 MV more perl quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV web site and docbook style sheets
	0.21 MV write some papers and custom dssls
	0.22 MV perl packaging
	0.23 MV validate writing
	0.24 MV license issues
	0.25 MV fix database problems
	0.26 MV md5 project
	0.27 MV database
	0.28 MV perl module versions in files
	0.29 MV md5 progress
	0.30 MV thumbnail user interface
	0.31 MV more thumbnail issues
	0.32 MV website construction
	0.33 MV improve the movie db xml
	0.34 MV web site automation
	0.35 MV SEE ALSO section fix
	0.36 MV move tests to modules
	0.37 MV bring movie data
	0.38 MV web site development
	0.39 MV finish papers
	0.40 MV teachers project
	0.41 MV more pdmt stuff
	0.42 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Archive::Tar(3), Meta::Baseline::Aegis(3), Meta::Template::Sub(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), Net::SCP(3), strict(3)

=head1 TODO

-encryption currently does not work since the GnuPG module is not working anymore. Move to another encryption module and make the code work again.

-use aedist and not do any querying on your own with the features...

-support bz2 too (and make it the default).

-move all the code here into a library.

-when doing full backup call the result project or something.(not according to change numbers) - the date suffices.

-there are some performance issues with this script due to the use of Archive::Tar which seems to hold all in memory and not be very efficient. Try to test it and imporve it.

-the localdir dir show be an existing directory and not a string type if only the Opts library knew how to do TT2 transformations.

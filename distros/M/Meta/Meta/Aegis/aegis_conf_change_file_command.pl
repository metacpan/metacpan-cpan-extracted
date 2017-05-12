#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Prop qw();
use Meta::Utils::Output qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Lang::Python::Python qw();
use Meta::Baseline::Lang::Perl qw();
use Meta::Baseline::Aegis qw();

my($verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->set_free_allo(1);
$opts->set_free_stri("[file_names]");
$opts->set_free_mini(1);
$opts->set_free_maxi(1);
$opts->analyze(\@ARGV);

#these next lines are a hack since due to the Quote substitution
#quoting all the files together we get only a single argument to
#this script (watche the opts up above). We then proceed to split
#the argument to get the various files.
#We can stop using this hack once we have a better way to pass the
#arguments to the script.
my($file_names)=$ARGV[0];
my(@files)=split(" ",$file_names);
for(my($i)=0;$i<=$#files;$i++) {
	my($modu)=$files[$i];
	my($file)=Meta::Baseline::Aegis::which($modu);
	#First lets determine if the file is a runnable script and chmod+x it if it is so.
	if(Meta::Lang::Perl::Perl::is_bin($modu) || Meta::Lang::Python::Python::is_bin($modu)) {
		if($verb) {
			Meta::Utils::Output::print("in here with module [".$modu."]\n");
		}
		Meta::Utils::File::Prop::chmod_x($file);
	}
	#Now determine if this is a perl file and if so then fix it's history.
	if(Meta::Lang::Perl::Perl::is_perl($modu)) {
		# now fix the pods which change from version to version
		# this means the history,details (which contains the current
		# version) and the $VERSION varialble.
		Meta::Baseline::Lang::Perl->fix_history_add($modu,$file);
		Meta::Baseline::Lang::Perl->fix_details_add($modu,$file);
		# module specific fixes
		if(Meta::Lang::Perl::Perl::is_lib($modu)) {
			Meta::Baseline::Lang::Perl->fix_version_add($modu,$file);
		}
		# script specific fixes
		if(Meta::Lang::Perl::Perl::is_bin($modu)) {
		}
	}
}
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

aegis_conf_change_file_command.pl - handle Aegis file changes in the change.

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

	MANIFEST: aegis_conf_change_file_command.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	aegis_conf_change_file_command.pl

=head1 DESCRIPTION

This script is called by Aegis whenever a new file is added to the project or
a file is copied to the project.
This will:
	0) Authorise that this file is allowed for insertion.
	1) Authorise that the current developer is allowed to insert this file.
	2) If the file is new it will run templates on it.
	3) If the file needs changed permissions it will give it new
		permissions.
	4) If the file in question records it's own history then it will fix
		that history for the current change.

Remarks:
number (0) (1) and (2) are not done.
number (3) is done for perl and python executables only.
number (4) is done only for perl files (scripts and modules).

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

=back

minimum of [1] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site development
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Lang::Perl(3), Meta::Lang::Perl::Perl(3), Meta::Lang::Python::Python(3), Meta::Utils::File::Prop(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-fix this scripts usage once better hooks are available in Aegis.

-this script is called when removing files too. How do I know that ? Can I have a different hook for removal ? I certainly don't need to do whatever I'm doing here on removal of files.

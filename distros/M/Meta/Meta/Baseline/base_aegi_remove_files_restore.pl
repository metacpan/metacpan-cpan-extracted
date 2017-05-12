#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::Copy qw();
use Meta::Utils::Output qw();

my($demo,$verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("demo","do it for real or just play ?",1,\$demo);
$opts->def_bool("verbose","noisy or quiet ?",1,\$verb);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($file)=Meta::Baseline::Aegis::which("data/baseline/aegis/remove_file.txt");
my($hash)=Meta::Baseline::Aegis::change_files_hash(0,0,1,1,1,1);
while(my($key,$val)=each(%$hash)) {
	if($verb) {
		Meta::Utils::Output::print("restoring [".$key."]\n");
	}
	if(!$demo) {
		Meta::Utils::File::Copy::copy_mkdir($file,$key);
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

base_aegi_remove_files_restore.pl - restore all change removed files.

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

	MANIFEST: base_aegi_remove_files_restore.pl
	PROJECT: meta
	VERSION: 0.26

=head1 SYNOPSIS

	base_aegi_remove_files_restore.pl

=head1 DESCRIPTION

This script restores all the delclared removed files according to aegis
from your change directory.

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

=item B<demo> (type: bool, default: 1)

do it for real or just play ?

=item B<verbose> (type: bool, default: 1)

noisy or quiet ?

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
	0.05 MV fix todo items look in pod documentation
	0.06 MV make all tests real tests
	0.07 MV silense all tests
	0.08 MV spelling change
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV revision change
	0.13 MV languages.pl test online
	0.14 MV perl packaging
	0.15 MV license issues
	0.16 MV md5 project
	0.17 MV database
	0.18 MV perl module versions in files
	0.19 MV thumbnail user interface
	0.20 MV more thumbnail issues
	0.21 MV website construction
	0.22 MV improve the movie db xml
	0.23 MV web site automation
	0.24 MV SEE ALSO section fix
	0.25 MV move tests to modules
	0.26 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::File::Copy(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

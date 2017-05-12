#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::File::Purge qw();

my($dire,$abso,$demo,$verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
# in the next line we cannot give the aegis development directory because
# then the documentation will become change dependant.
$opts->def_devd("directory","in which directory ?",".",\$dire);
$opts->def_bool("absolute","do it with absolute paths ?",0,\$abso);
$opts->def_bool("demo","do it for real or just play ?",0,\$demo);
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($hash)=Meta::Baseline::Aegis::change_files_hash(0,0,1,1,1,$abso);
Meta::Utils::File::Remove::rmhash($hash);
my($done);
my($scod)=Meta::Utils::File::Purge::purge($dire,$demo,$verb,\$done);
Meta::Utils::System::exit($scod);

__END__

=head1 NAME

base_aegi_remove_files_remove.pl - remove all change removed files.

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

	MANIFEST: base_aegi_remove_files_remove.pl
	PROJECT: meta
	VERSION: 0.27

=head1 SYNOPSIS

	base_aegi_remove_files_remove.pl

=head1 DESCRIPTION

This script removes all the delclared removed files according to aegis
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

=item B<directory> (type: devd, default: .)

in which directory ?

=item B<absolute> (type: bool, default: 0)

do it with absolute paths ?

=item B<demo> (type: bool, default: 0)

do it for real or just play ?

=item B<verbose> (type: bool, default: 0)

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
	0.05 MV fix up perl checks
	0.06 MV fix todo items look in pod documentation
	0.07 MV make all tests real tests
	0.08 MV more on tests/more checks to perl
	0.09 MV silense all tests
	0.10 MV perl code quality
	0.11 MV more perl quality
	0.12 MV more perl quality
	0.13 MV revision change
	0.14 MV languages.pl test online
	0.15 MV perl packaging
	0.16 MV license issues
	0.17 MV md5 project
	0.18 MV database
	0.19 MV perl module versions in files
	0.20 MV thumbnail user interface
	0.21 MV more thumbnail issues
	0.22 MV website construction
	0.23 MV improve the movie db xml
	0.24 MV web site automation
	0.25 MV SEE ALSO section fix
	0.26 MV move tests to modules
	0.27 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::File::Purge(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

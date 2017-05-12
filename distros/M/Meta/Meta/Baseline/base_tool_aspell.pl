#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(1);
$opts->set_free_stri("[file]");
$opts->set_free_mini(1);
$opts->set_free_maxi(1);
$opts->analyze(\@ARGV);

my($file)=$ARGV[0];
my($dict)=Meta::Baseline::Aegis::which("data/baseline/dict.txt");
my($scod)=Meta::Utils::System::system_nodie("aspell",["--dont-backup","--mode=sgml","--personal",$dict,"--check",$file]);
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

base_tool_aspell.pl - run aspell on files for you.

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

	MANIFEST: base_tool_aspell.pl
	PROJECT: meta
	VERSION: 0.20

=head1 SYNOPSIS

	base_tool_aspell.pl

=head1 DESCRIPTION

This script accepts a docbook file and checks it base style.
We use the --dont-backup here because a backup file (same name
with a .bak extension) will be created if we fix the file
while in interactive mode.

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

	0.00 MV spelling change
	0.01 MV perl code quality
	0.02 MV more perl quality
	0.03 MV more perl quality
	0.04 MV more perl quality
	0.05 MV revision change
	0.06 MV languages.pl test online
	0.07 MV spelling and papers
	0.08 MV perl packaging
	0.09 MV license issues
	0.10 MV md5 project
	0.11 MV database
	0.12 MV perl module versions in files
	0.13 MV thumbnail user interface
	0.14 MV more thumbnail issues
	0.15 MV website construction
	0.16 MV improve the movie db xml
	0.17 MV web site automation
	0.18 MV SEE ALSO section fix
	0.19 MV move tests to modules
	0.20 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-move the aspell code here to the aspell mode and share as much of it as possible
	with the aspell code that does the checking for the build process.

-aspell does not seem to respect the --rem-sgml-check=[programlisting] option
	and needs to be fixed so I'm not using it at the moment and all
	program listing code in sgml files is out.

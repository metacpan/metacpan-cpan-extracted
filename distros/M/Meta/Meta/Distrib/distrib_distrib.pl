#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
#use Meta::Distrib::Distrib qw();

my($desc);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_devf("desc","XML description of distribution requirements file",undef,\$desc);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

distrib_distrib.pl - distribute a set of sources/targets to a set of computers via various means.

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

	MANIFEST: distrib_distrib.pl
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	distrib_distrib.pl

=head1 DESCRIPTION

This script will get a distribution discription in XML format and will
distribute the data to the variouas machines involved.

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

=item B<desc> (type: devf, default: )

XML description of distribution requirements file

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

	0.00 MV fix database problems
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV thumbnail user interface
	0.05 MV more thumbnail issues
	0.06 MV website construction
	0.07 MV improve the movie db xml
	0.08 MV web site automation
	0.09 MV SEE ALSO section fix
	0.10 MV move tests to modules
	0.11 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-make this script distribtute the Meta package.

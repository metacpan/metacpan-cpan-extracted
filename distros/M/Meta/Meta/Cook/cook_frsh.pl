#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Rsh qw();

my($demo,$verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("demo","play around or do it for real ?",0,\$demo);
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->set_free_allo(1);
$opts->set_free_stri("[host] [comm]");
$opts->set_free_mini(2);
$opts->set_free_maxi(2);
$opts->analyze(\@ARGV);

my($host,$comm)=($ARGV[0],$ARGV[1]);
my($scod)=Meta::Baseline::Rsh::cook_rsh($demo,$verb,$host,$comm);
Meta::Utils::System::exit($scod);

__END__

=head1 NAME

cook_frsh.pl - perform remote shell commands for cook.

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

	MANIFEST: cook_frsh.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	cook_frsh.pl

=head1 DESCRIPTION

Cook, when issueing rsh commands gives a rather peculiar syntax.
It assumes that the command executing the rsh is rsh and therefore
cannot return the exit status of the remote process correctly.
This means that it wraps the command with ugly stuff.
This script behaves as if its doing what cook wants it to do.
Actually - it strips the original command out using libraries that we
have that do that stuff and then checks if the command is to be executed
on the current machine (perl system is enough to do that and no need
for even a remote shell) or a neighbor unix (rsh will do the trich then
with a few substitutions to make the command feel at home) or a pc
(god forbid) and then again a few substitutions are in order...
There is no reason to keep holding this command once peter miller dumps
the complexity on rsh or provides an option for straight forward interaction
with rsh.

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

=item B<demo> (type: bool, default: 0)

play around or do it for real ?

=item B<verbose> (type: bool, default: 0)

noisy or quiet ?

=back

minimum of [2] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Rsh(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

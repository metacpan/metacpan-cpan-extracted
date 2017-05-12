#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Info::Enum qw();
use Meta::Utils::Output qw();

my($enum)=Meta::Info::Enum->new();
$enum->set_name("opcode");
$enum->set_description("what operation to perform");
$enum->set_default("status");
$enum->insert("start","start the web server");
$enum->insert("stop","stop the web server");
$enum->insert("restart","restart the web server");
$enum->insert("status","report status of the web server");
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(1);
$opts->set_free_stri("opcode");
$opts->set_free_mini(1);
$opts->set_free_maxi(1);
$opts->analyze(\@ARGV);

my($opcode)=$ARGV[0];
if($enum->hasnt($opcode)) {
	Meta::Utils::Output::print("opcode [".$opcode."] is unknown\n");
	Meta::Utils::System::exit(0);
}
Meta::Utils::Output::print("opcode is [".$opcode."]\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

elems_rcd.pl - rc.d script for the Elems webserver.

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

	MANIFEST: elems_rcd.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	elems_rcd.pl [options]

=head1 DESCRIPTION

Place this script in your /etc/rc.d/init.d script and chkconfig it
to enable the elems web server to run at boot.

This script accepts the standard commands:
0. start - start the web server.
1. stop - stop the web server.
2. restart - restart the web server.
3. status - report status of web server.

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

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Info::Enum(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

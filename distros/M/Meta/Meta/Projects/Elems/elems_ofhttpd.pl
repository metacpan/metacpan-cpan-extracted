#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
#use OpenFrame::Server::HTTP qw();
use OpenFrame qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();

my($port,$debug);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_inte("port","what port to serve",8000,\$port);
$opts->def_bool("debug","should I debug OpenFrame",0,\$debug);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

#my($dir)="htdocs/";
#my($dir)=Meta::Baseline::Aegis::baseline();

#my($config)=OpenFrame::Config->new();
#$config->setKey(
#	'SLOTS',
#	[
#		{
#			dispatch=>'Local',
#			name=>'Meta::OpenFrame::Slot::Types',
#			config=>{ directory=>$dir,aegis=>1 },
#		},
#	]
#);
#$config->setKey(DEBUG=>$debug);

#my($h)=OpenFrame::Server::HTTP->new(port=>$port);
#Meta::Utils::Output::print("contact me at [http://localhost:".$port."/]\n");
#$h->handle();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

elems_ofhttpd.pl - OpenFrame based web server for Elems.

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

	MANIFEST: elems_ofhttpd.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	elems_ofhttpd.pl [options]

=head1 DESCRIPTION

This program is the web server for the elems project.

Security
If you want to run this server securly I advise you to keep running it on a user
port (port over 1024) like 8080. This way the server can run as a user process.
The problem is that you have to either install a piece of software that runs as root
and redicts port 80 to 8080 or to use feature in the OS which enables you to
efficiently redirect one port to another. Linux has this feature in it's iptables
subsystem.

=head1 OPTIONS

=over 4

=item B<port> (type: inte, default: 8000)

what port to serve

=item B<debug> (type: bool, default: 0)

should I debug OpenFrame

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

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV download scripts
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), OpenFrame(3), strict(3)

=head1 TODO

Nothing.

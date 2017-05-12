#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();

my($from_port,$to_port,$host,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_inte("from_port","from what port to scan ?",0,\$from_port);
$opts->def_inte("to_port","from what port to scan ?",1024,\$to_port);
$opts->def_stri("host","what host to use ?","localhost",\$host);
$opts->def_bool("verbose","should I be noisy ?",0,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

for(my($i)=$from_port;$i<$to_port;$i++) {
	Meta::Utils::Output::verbose($verbose,"scanning port [".$i."]\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

nettools_nmap.pl - perl version of nmap.

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

	MANIFEST: nettools_nmap.pl
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	nettools_nmap.pl [options]

=head1 DESCRIPTION

This program will scan a range of ports on a target machine and will report
which ports are open. It can optionally translate these ports into service
names using a small XML database that it uses.

Many ideas were borrowed from the standard nmap. Obviously this version does
not support the many features that nmap supports but on the other hand it
is Perl and therefore can run on any machine. In addition most users of nmap
scan their own machines to check if they didn't leave something on unintentionally
which means that this program is enough for 95% of the users of nmap.

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

=item B<from_port> (type: inte, default: 0)

from what port to scan ?

=item B<to_port> (type: inte, default: 1024)

from what port to scan ?

=item B<host> (type: stri, default: localhost)

what host to use ?

=item B<verbose> (type: bool, default: 0)

should I be noisy ?

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

	0.00 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

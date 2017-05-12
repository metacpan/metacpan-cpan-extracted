#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Comm::Socket::Server qw();
use Meta::Comm::Socket::Client qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

#if(CORE::fork()) {#server side
#	my($server)=Meta::Comm::Socket::Server->new();
#	$server->run();
#} else {#client side
#	CORE::sleep(2);
#	my($client)=Meta::Comm::Socket::Client->new();
#	CORE::sleep(2);
#	my($mess)="Hello\n";
#	Meta::Utils::Output::print("sending [".$mess."]\n");
#	my($result)=$client->send($mess);
#	Meta::Utils::Output::print("result is [".$result."]\n");
#	CORE::sleep(2);
#	my($mess)="Hello2\n";
#	Meta::Utils::Output::print("sending [".$mess."]\n");
#	my($result)=$client->send($mess);
#	Meta::Utils::Output::print("result is [".$result."]\n");
#}
my($scod)=1;

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit($scod);

__END__

=head1 NAME

client_server.pl - test client/server communication.

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

	MANIFEST: client_server.pl
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	client_server.pl

=head1 DESCRIPTION

This test creates a client and server classes and tests communication
between them.

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

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV misc fixes
	0.01 MV perl packaging
	0.02 MV perl packaging again
	0.03 MV stuff
	0.04 MV license issues
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV improve the movie db xml
	0.12 MV web site automation
	0.13 MV SEE ALSO section fix
	0.14 MV move tests to modules
	0.15 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Test(3), Meta::Comm::Socket::Client(3), Meta::Comm::Socket::Server(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

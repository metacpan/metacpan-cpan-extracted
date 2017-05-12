#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use LWP::UserAgent qw();
use Meta::Utils::Output qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($ua)=LWP::UserAgent->new();
my($response)=$ua->get('http://search.cpan.org/');
#my($response)=$ua->get('http://www.veltzer.org:65000/');
#Meta::Utils::Output::print("as_string is [".$response->as_string()."]\n");
Meta::Utils::Output::print("code is [".$response->code()."]\n");
Meta::Utils::Output::print("header is [".$response->header()."]\n");
Meta::Utils::Output::print("message is [".$response->message()."]\n");
Meta::Utils::Output::print("protocol is [".$response->protocol()."]\n");
Meta::Utils::Output::print("status_line is [".$response->status_line()."]\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

demo_lwp.pl - demo LWP usage.

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

	MANIFEST: demo_lwp.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	lwp.pl [options]

=head1 DESCRIPTION

This script demos how to use the LWP::UserAgent modules form libwww-perl
and lets you play with the settings and debug stuff so that you could
better understand how to use this library.

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

	0.00 MV finish papers
	0.01 MV md5 issues

=head1 SEE ALSO

LWP::UserAgent(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

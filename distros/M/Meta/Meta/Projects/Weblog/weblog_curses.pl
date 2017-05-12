#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Curses qw();
use Curses::Widgets qw();
use Curses::Widgets::TextField qw();
use Meta::Utils::Output qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($mwh)=Curses->new();
Curses::noecho();
Curses::curs_set(0);
my($tf)=Curses::Widgets::TextField->new({
	X=>5,
	Y=>5,
	LENGTH=> 10,
	CAPTION=>'name'
});
$tf->draw($mwh,0);
$tf->execute($mwh);
my($name)=$tf->getField('VALUE');
Meta::Utils::Output::print("name is [".$name."]\n");
Curses::curs_set(1);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

weblog_curses.pl - provide easy curses interface for entering weblog events.

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

	MANIFEST: weblog_curses.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	weblog_curses.pl [options]

=head1 DESCRIPTION

This program provides a nice and easy curses cmd line interface for entering new weblog
events. New events which are entered are entered under the current time (unless you
specify differently) and go straight into the database.

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

	0.00 MV weblog issues
	0.01 MV md5 issues

=head1 SEE ALSO

Curses(3), Curses::Widgets(3), Curses::Widgets::TextField(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

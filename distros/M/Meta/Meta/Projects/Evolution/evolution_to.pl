#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

evolution_to.pl - convert XML/contacts file to evolution type contacts.

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

	MANIFEST: evolution_to.pl
	PROJECT: meta
	VERSION: 0.05

=head1 SYNOPSIS

	evolution_to.pl [options]

=head1 DESCRIPTION

This script receives as input an XML/contacts file and outputs evolution type contacts.
The result can be placed in your evolution folder (usually somewhere in ~/evolution)
and be used as your evolution contacts list. The script could either be used as a one
time conversion process or you could decide to keep your contact information in your
own XML file (a smart move) and whenever adding a contact add it by editing your
XML file and then running the conversion so that you could have access to the new
information. In this way you are always in control of your contact information.

How does an XML/contacts file look like ? you should have received an example with the
software that you got and you sould also have received a formal DTD with the software
that you got.

Do you need changes/enhancements in the XML/contacts format ? contact me. I'm willing
to apply such changes and support them if they make sense for most users. If this is
a really specific change then please do it yourself (in the DTD and the appropriate
perl classes). I can help you with that (my contact information can be found in this
file).

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

	0.00 MV improve the movie db xml
	0.01 MV web site development
	0.02 MV web site automation
	0.03 MV SEE ALSO section fix
	0.04 MV move tests to modules
	0.05 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

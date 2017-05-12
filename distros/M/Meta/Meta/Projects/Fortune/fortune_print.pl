#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Projects::Fortune::Fortune qw();

my($connections_file,$con_name,$name);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_devf("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","fortune",\$name);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($fortune)=Meta::Projects::Fortune::Fortune->new($connections_file,$con_name,$name);
Meta::Utils::Output::print($fortune->random()."\n");
#Meta::Utils::Output::print($fortune->random_cat("love")."\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

fortune_print.pl - print out a fortune saying (by random).

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

	MANIFEST: fortune_print.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	fortune_print.pl [options]

=head1 DESCRIPTION

This program will print out a fortune saying by random.
This is much line the fortune(1) command of old by works
with a real RDBMS. Please use the code here and embed it
in what ever you like (web servers, programs, whatever...).

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

=item B<connections_file> (type: devf, default: xmlx/connections/connections.xml)

what connections XML file to use ?

=item B<con_name> (type: stri, default: )

what connection name ?

=item B<name> (type: stri, default: fortune)

what database name ?

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

Meta::Projects::Fortune::Fortune(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

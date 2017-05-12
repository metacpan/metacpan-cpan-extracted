#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Tool::Aegis qw();
use Meta::Utils::Output qw();
use Meta::Info::Authors qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($authors)=Meta::Info::Authors->new();
my($module)="aegi/repo/file_hstry.rpt";
my($revision)=Meta::Tool::Aegis::history($module,$authors);
Meta::Utils::Output::print("revision in xml is [".$revision->docbook_revhistory()."]\n");
$revision->print(Meta::Utils::Output::get_file());
Meta::Utils::Output::print("perl_pod is [".$revision->perl_pod()."]\n");
Meta::Utils::Output::print("perl_currnet is [".$revision->perl_current()."]\n");

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

aegis.pl - testing program for the Meta::Tool::Aegis.pm module.

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

	MANIFEST: aegis.pl
	PROJECT: meta
	VERSION: 0.19

=head1 SYNOPSIS

	aegis.pl

=head1 DESCRIPTION

This is a test suite for the Meta::Tool::Aegis.pm package.

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

	0.00 MV better general cook schemes
	0.01 MV languages.pl test online
	0.02 MV history change
	0.03 MV more c++ stuff
	0.04 MV Revision in DocBook files stuff
	0.05 MV PDMT stuff
	0.06 MV perl packaging
	0.07 MV license issues
	0.08 MV md5 project
	0.09 MV database
	0.10 MV perl module versions in files
	0.11 MV thumbnail user interface
	0.12 MV more thumbnail issues
	0.13 MV website construction
	0.14 MV improve the movie db xml
	0.15 MV web site automation
	0.16 MV SEE ALSO section fix
	0.17 MV move tests to modules
	0.18 MV bring movie data
	0.19 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Test(3), Meta::Info::Authors(3), Meta::Tool::Aegis(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

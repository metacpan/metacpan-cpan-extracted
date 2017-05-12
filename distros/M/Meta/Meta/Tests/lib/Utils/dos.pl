#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Utils::Dos qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Remove qw();
use Meta::IO::File qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($file_orig)=Meta::Utils::Utils::get_temp_file();
my($file_dosx)=Meta::Utils::Utils::get_temp_file();
my($file_unix)=Meta::Utils::Utils::get_temp_file();
my($file_visu)=Meta::Utils::Utils::get_temp_file();

my($io)=Meta::IO::File->new_writer($file_orig);
print $io "this is the first line\n";
print $io "this is the second line\n";
print $io "this is the third line\n";
$io->close();

Meta::Utils::Dos::to_dosx_file($file_orig,$file_dosx,0);
Meta::Utils::Dos::to_unix_file($file_dosx,$file_unix,0);
Meta::Utils::Dos::visual_file($file_dosx,$file_visu);

Meta::Utils::File::Remove::rm($file_orig);
Meta::Utils::File::Remove::rm($file_dosx);
Meta::Utils::File::Remove::rm($file_unix);
Meta::Utils::File::Remove::rm($file_visu);

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

dos.pl - testing program for the Meta::Utils::Dos.pm module.

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

	MANIFEST: dos.pl
	PROJECT: meta
	VERSION: 0.22

=head1 SYNOPSIS

	dos.pl

=head1 DESCRIPTION

This is a test suite for the Meta::Utils::Dos.pm package.

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

	0.00 MV put ALL tests back and light the tree
	0.01 MV silense all tests
	0.02 MV more perl code quality
	0.03 MV cleanup tests change
	0.04 MV correct die usage
	0.05 MV perl code quality
	0.06 MV more perl quality
	0.07 MV more perl quality
	0.08 MV revision change
	0.09 MV languages.pl test online
	0.10 MV perl packaging
	0.11 MV license issues
	0.12 MV md5 project
	0.13 MV database
	0.14 MV perl module versions in files
	0.15 MV thumbnail user interface
	0.16 MV more thumbnail issues
	0.17 MV website construction
	0.18 MV improve the movie db xml
	0.19 MV web site automation
	0.20 MV SEE ALSO section fix
	0.21 MV move tests to modules
	0.22 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Test(3), Meta::IO::File(3), Meta::Utils::Dos(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.

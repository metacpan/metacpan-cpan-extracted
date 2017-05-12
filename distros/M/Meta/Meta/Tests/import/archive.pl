#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Utils::Output qw();
use Archive::Tar qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Remove qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($tar)=Archive::Tar->new();
$tar->add_data("foo.c","kuku");
my(@list)=$tar->list_files();
Meta::Utils::Output::print(join("\n",@list)."\n");
my($temp)=Meta::Utils::Utils::get_temp_file();
$tar->write($temp,9);
Meta::Utils::System::system("tar",["ztvf",$temp]);
Meta::Utils::File::Remove::rm($temp);

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

archive.pl - test the external Archive::Tar module.

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

	MANIFEST: archive.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	archive.pl

=head1 DESCRIPTION

This is a test suite for the Archive::Tar package.
Currently it just creates an archive with some data and then shows
you it's content via the system tar command.

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

	0.00 MV validate writing
	0.01 MV license issues
	0.02 MV fix database problems
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV improve the movie db xml
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV move tests to modules
	0.13 MV md5 issues

=head1 SEE ALSO

Archive::Tar(3), Meta::Baseline::Test(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-do some stress testing here regarding the add_data command since it takes a long time to complete if there are big files and a lot of them involved.

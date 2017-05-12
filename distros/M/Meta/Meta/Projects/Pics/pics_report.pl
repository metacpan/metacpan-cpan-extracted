#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Iterator qw();

my($dire,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_dire("directory","in what directory should I work ?",".",\$dire);
$opts->def_bool("verbose","noisy or quiet ?",1,\$verbose);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directory($dire);
$iterator->start();

while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	if($verbose) {
		Meta::Utils::Output::print("doing [".$curr."]\n");
	}
	$iterator->next();
}
$iterator->fini();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pics_report.pl - create a report about a collection of images in XML.

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

	MANIFEST: pics_report.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	pics_report.pl [options]

=head1 DESCRIPTION

This script receives as input a directory containing a collection of
images and creates an XML report of the collection which includes number
of images in every set and its name. This is very close to a recursive
directory listing but in XML without mention of each image. The report
ignores files which have unknown suffixes.

=head1 OPTIONS

=over 4

=item B<directory> (type: dire, default: .)

in what directory should I work ?

=item B<verbose> (type: bool, default: 1)

noisy or quiet ?

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

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Utils::File::Iterator(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

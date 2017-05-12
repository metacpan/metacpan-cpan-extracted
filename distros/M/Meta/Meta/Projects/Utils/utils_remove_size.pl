#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::File::Iterator qw();
use Meta::Utils::File::Prop qw();
use Meta::Utils::Output qw();

my($demo,$verb,$dire,$size);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("demo","should I do it for real ?",0,\$demo);
$opts->def_bool("verbose","should I be noisy ?",1,\$verb);
$opts->def_dire("directory","what directory to recurse ?",undef,\$dire);
$opts->def_inte("size","what size to remove at ?",10000,\$size);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directory($dire);
$iterator->start();
while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
#	if($verb) {
#		Meta::Utils::Output::print("working on [".$curr."]\n");
#	}
	#find out the file size
	my($curr_size)=Meta::Utils::File::Prop::size($curr);
	if($curr_size<$size) {#size is too small
		#remove the file
		if($verb) {
			Meta::Utils::Output::print("removing [".$curr."]\n");
		}
		if(!$demo) {
			Meta::Utils::File::Remove::rm($curr);
		}
	}
	$iterator->next();
}
$iterator->fini();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_remove_size.pl - remove files according to size.

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

	MANIFEST: utils_remove_size.pl
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	utils_remove_size.pl [options]

=head1 DESCRIPTION

This program will remove files under a certain size.

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

=item B<demo> (type: bool, default: 0)

should I do it for real ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<directory> (type: dire, default: )

what directory to recurse ?

=item B<size> (type: inte, default: 10000)

what size to remove at ?

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

	0.00 MV books XML into database
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV more thumbnail stuff
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Utils::File::Iterator(3), Meta::Utils::File::Prop(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

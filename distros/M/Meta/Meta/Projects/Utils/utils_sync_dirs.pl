#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Iterator qw();
use Meta::Utils::File::File qw();
use Meta::Utils::File::Remove qw();

my($verbose,$remove,$suffix,$source,$target);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->def_bool("remove","should I really remove ?",1,\$remove);
$opts->def_stri("suffix","suffix to remove",".png",\$suffix);
$opts->def_dire("source","what source directory ?","/",\$source);
$opts->def_dire("target","what target directory ?","/local/home/mark/.gqview/thumbnails",\$target);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directory($target);
$iterator->start();

while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
#	if($verbose) {
#		Meta::Utils::Output::print("curr is [".$curr."]\n");
#	}
	#my($relative)=$iterator->get_relative();
	if(Meta::Utils::Utils::is_suffix($curr,$suffix)) {
		my($relative)=Meta::Utils::Utils::minus($curr,$target);
#		if($verbose) {
#			Meta::Utils::Output::print("relative is [".$relative."]\n");
#		}
		my($suff_relative)=Meta::Utils::Utils::remove_suf($relative,$suffix);
#		if($verbose) {
#			Meta::Utils::Output::print("suff_relative is [".$suff_relative."]\n");
#		}
		my($test)=$source.$suff_relative;
#		if($verbose) {
#			Meta::Utils::Output::print("test is [".$test."]\n");
#		}
		if(Meta::Utils::File::File::notexist($test)) {
			if($verbose) {
				Meta::Utils::Output::print("removing is [".$curr."]\n");
			}
			if($remove) {
				Meta::Utils::File::Remove::rm($curr);
			}
		}
	}
	$iterator->next();
}
$iterator->fini();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_sync_dirs.pl - sync two directories.

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

	MANIFEST: utils_sync_dirs.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	utils_sync_dirs.pl [options]

=head1 DESCRIPTION

This program will sync two directories.

Currently it only has a small subset of the overall functionality
I will have for it but it can be used to sync a thumbnail directory
with the corresponding image directory.

=head1 OPTIONS

=over 4

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<remove> (type: bool, default: 1)

should I really remove ?

=item B<suffix> (type: stri, default: .png)

suffix to remove

=item B<source> (type: dire, default: /)

what source directory ?

=item B<target> (type: dire, default: /local/home/mark/.gqview/thumbnails)

what target directory ?

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

Meta::Utils::File::File(3), Meta::Utils::File::Iterator(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

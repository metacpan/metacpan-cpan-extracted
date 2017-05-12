#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::Remove qw();
use Image::Magick qw();
use Image::Size qw();
use Meta::Info::Enum qw();
use Meta::Utils::File::Iterator qw();

my($enum)=Meta::Info::Enum->new();
$enum->insert("magick","use Image::Magick");
$enum->insert("imagesize","use Image::Size");
$enum->set_default("magick");

my($verbose,$demo,$summ,$x_size,$y_size,$method,$dire);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->def_bool("demo","should I just fake it ?",1,\$demo);
$opts->def_bool("summary","should I display summary ?",0,\$summ);
$opts->def_inte("x","minimum x size",200,\$x_size);
$opts->def_inte("y","minimum y size",200,\$y_size);
$opts->def_enum("method","what type of method to use ?","magick",\$method,$enum);
$opts->def_dire("directory","directory to scan",".",\$dire);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($scan)=0;
my($remove)=0;
my($found)=0;

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directory($dire);
$iterator->start();

while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	Meta::Utils::Output::verbose($verbose,"doing [".$curr."]\n");
	my($curr_x,$curr_y);
	if($enum->is_selected($method,"magick")) {
		my($image)=Image::Magick->new();
		my($ret)=$image->Read($curr);
		if($ret) {
			throw Meta::Error::Simple("unable to read image [".$curr."]");
		}
		#$image->Display();
		($curr_x,$curr_y)=$image->Get('height','width');
	}
	if($enum->is_selected($method,"imagesize")) {
		($curr_x,$curr_y)=Image::Size::imgsize($curr);
	}
	#Meta::Utils::Output::print("x is [".$curr_x."] y is [".$curr_y."]\n");
	if(($curr_x<$x_size) || ($curr_y<$y_size)) {
		Meta::Utils::Output::verbose($verbose,"removing [".$curr."]\n");
		$found++;
		if(!$demo) {
			Meta::Utils::File::Remove::rm($curr);
			$remove++;
		}
	}
	$scan++;
	$iterator->next();
}
$iterator->fini();
if($summ) {
	Meta::Utils::Output::print("scanned [".$scan."] images\n");
	Meta::Utils::Output::print("found [".$found."] small images\n");
	Meta::Utils::Output::print("removed [".$remove."] images\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pics_remove_small.pl - remove small images from a list of images.

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

	MANIFEST: pics_remove_small.pl
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	pics_remove_small.pl [options]

=head1 DESCRIPTION

Give this module a list of images and it will remove all images under
a certail XxY size (either x or y counts).
This module can work in 2 ways:
1. use the excellent Perl Magick library, create an image object for
each image, get its size and take it from there.
2. use the Image::Size library from CPAN and just get the image size.

Method number 2 should be a lot faster since the image need not be
read in full. In actual tests of 2000 images the second method
(which is also the default) was found to be much faster (meaning
more than 10 times faster...).

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

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<demo> (type: bool, default: 1)

should I just fake it ?

=item B<summary> (type: bool, default: 0)

should I display summary ?

=item B<x> (type: inte, default: 200)

minimum x size

=item B<y> (type: inte, default: 200)

minimum y size

=item B<method> (type: enum, default: magick)

what type of method to use ?

options:
	magick - use Image::Magick
	imagesize - use Image::Size

=item B<directory> (type: dire, default: .)

directory to scan

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
	0.04 MV movie stuff
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV bring movie data
	0.13 MV finish papers
	0.14 MV teachers project
	0.15 MV md5 issues

=head1 SEE ALSO

Image::Magick(3), Image::Size(3), Meta::Info::Enum(3), Meta::Utils::File::Iterator(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-add option to only produce of list of files to be removed.

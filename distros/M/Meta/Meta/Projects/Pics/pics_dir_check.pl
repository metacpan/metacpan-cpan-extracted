#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Iterator qw();
use Meta::Utils::Output qw();
use Image::Magick qw();

my($verbose,$dire);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","should I be noisy ?",0,\$verbose);
$opts->def_dire("directory","directory to scan",".",\$dire);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directory($dire);
$iterator->start();

my($bad)=0;
while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	if($verbose) {
		Meta::Utils::Output::print("doing [".$curr."]\n");
	}
	my($image)=Image::Magick->new();
	my($ret)=$image->Read($curr);
	if($ret) {
		Meta::Utils::Output::print($curr."\n");
		$bad++;
	}
	$iterator->next();
}
$iterator->fini();

my($scod);
if($bad>0) {
	$scod=0;
} else {
	$scod=1;
}

Meta::Utils::System::exit($scod);

__END__

=head1 NAME

pics_dir_check.pl - check images in a directory.

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

	MANIFEST: pics_dir_check.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	pics_dir_check.pl [options]

=head1 DESCRIPTION

This script checks a list of files (currently all files contained
recursivly in a directory) for damaged image files and either
produces a list of the damaged files or just removes them.
Why should you need such a script ? well, it seems that most image
viewers today will show you an image even if the file itself is
damaged (some of the last scan lines are missing etc...). This
script is intended to aid you in finding the bad images in a big
image collection.

How does it work ? It uses Image::Magick to load the image. If the
file is ok then all is well and the image is discarded. If the load
fails then it reports the image as being bad or removed it (your
preference).

Other strategies for determining the correctness of the image file
may be added in the future.

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

=item B<verbose> (type: bool, default: 0)

should I be noisy ?

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

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Image::Magick(3), Meta::Utils::File::Iterator(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

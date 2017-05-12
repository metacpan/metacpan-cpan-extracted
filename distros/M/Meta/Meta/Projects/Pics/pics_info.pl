#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Image::Magick qw();
use Image::Size qw();
use Meta::Info::Enum qw();
use Meta::Utils::Output qw();

my($enum)=Meta::Info::Enum->new();
$enum->insert("magick","use Image::Magick to do the work");
$enum->insert("imagesize","use Image::Size to do the work");
$enum->set_default("imagesize");

my($file,$method);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_file("file","what file to use ?",undef,\$file);
$opts->def_enum("method","what type of method to use ?","imagesize",\$method,$enum);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($size_x,$size_y);
if($enum->is_selected($method,"magick")) {
	my($image)=Image::Magick->new();
	my($ret)=$image->Read($file);
	if($ret) {
		throw Meta::Error::Simple("unable to read image [".$file."]");
	}
	#$image->Display();
	($size_x,$size_y)=$image->Get('height','width');
}
if($enum->is_selected($method,"imagesize")) {
	($size_x,$size_y)=Image::Size::imgsize($file);
}
Meta::Utils::Output::print("x is [".$size_x."]\n");
Meta::Utils::Output::print("y is [".$size_y."]\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pics_info.pl - provide info about an image file.

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

	MANIFEST: pics_info.pl
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	pics_info.pl [options]

=head1 DESCRIPTION

This program reads an image file and provides you with info about it.
The info includes width, height and other info.

Currently it just provides size info (x and y).

=head1 OPTIONS

=over 4

=item B<file> (type: file, default: )

what file to use ?

=item B<method> (type: enum, default: imagesize)

what type of method to use ?

options:
	magick - use Image::Magick to do the work
	imagesize - use Image::Size to do the work

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
	0.01 MV bring movie data
	0.02 MV finish papers
	0.03 MV teachers project
	0.04 MV md5 issues

=head1 SEE ALSO

Image::Magick(3), Image::Size(3), Meta::Info::Enum(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-add ability to see tags (in formats that support tags)

#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::Move qw();
use Meta::Math::Pad qw();

my($start,$prefix,$verbose,$demo,$pad,$pad_factor,$suffix);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_inte("start","what number should I start at ?",0,\$start);
$opts->def_stri("pref","what prefix should I give ?","pref",\$prefix);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->def_bool("demo","should I just fake it ?",0,\$demo);
$opts->def_bool("pad","should I pad the files ?",1,\$pad);
$opts->def_inte("pad_factor","what pad factor should I use ?",4,\$pad_factor);
$opts->def_stri("suffix","what suffix should I use ?",".jpg",\$suffix);
$opts->set_free_allo(1);
$opts->set_free_stri("[files]");
$opts->set_free_mini(1);
$opts->set_free_noli(1);
$opts->analyze(\@ARGV);

my($counter)=$start;
for(my($i)=0;$i<=$#ARGV;$i++) {
	my($curr)=$ARGV[$i];
	my($num);
	if($pad) {
		$num=Meta::Math::Pad::pad($counter,$pad_factor);
	} else {
		$num=$counter;
	}
	my($new)=$prefix.$num.$suffix;
	if($verbose) {
		Meta::Utils::Output::print("moving [".$curr."] to [".$new."]\n");
	}
	if(!$demo) {
		Meta::Utils::File::Move::mv($curr,$new);
	}
	$counter++;
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_give_serial_names.pl - give serial names to files.

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

	MANIFEST: utils_give_serial_names.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	utils_give_serial_names.pl [options]

=head1 DESCRIPTION

Give this script a set of files and hell move them to a same prefix with
a serial number attached (to make sure they dont overlap).

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

=item B<start> (type: inte, default: 0)

what number should I start at ?

=item B<pref> (type: stri, default: pref)

what prefix should I give ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<demo> (type: bool, default: 0)

should I just fake it ?

=item B<pad> (type: bool, default: 1)

should I pad the files ?

=item B<pad_factor> (type: inte, default: 4)

what pad factor should I use ?

=item B<suffix> (type: stri, default: .jpg)

what suffix should I use ?

=back

minimum of [1] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more pdmt stuff
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Math::Pad(3), Meta::Utils::File::Move(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::Move qw();
use Meta::File::MMagic qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Iterator qw();

my($verbose,$type,$suffix,$directories);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","should I be noisy ?",0,\$verbose);
$opts->def_stri("type","what type to look for ?","image/jpeg",\$type);
$opts->def_stri("suffix","what suffix to give ?",".jpg",\$suffix);
$opts->def_dlst("directories","what directories to process ?",".",\$directories);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($mm)=Meta::File::MMagic->new();

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directories($directories,':');
$iterator->set_want_dirs(0);
$iterator->set_want_files(1);
$iterator->start();
while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	Meta::Utils::Output::verbose($verbose,"considering [".$curr."]\n");
	if(!Meta::Utils::Utils::is_suffix($curr,$suffix)) {
		my($c_type)=$mm->checktype_filename($curr);
		Meta::Utils::Output::verbose($verbose,"c_type is [".$c_type."]\n");
		if($c_type eq $type) {
			my($new)=Meta::Utils::Utils::replace_suffix($curr,$suffix);
			Meta::Utils::Output::verbose($verbose,"moving [".$curr."] to [".$new."]\n");
			Meta::Utils::File::Move::mv_noov($curr,$new);
		}
	}
	$iterator->next();
}
$iterator->fini();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_move_files.pl - move multiple files according to filter.

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

	MANIFEST: utils_move_files.pl
	PROJECT: meta
	VERSION: 0.09

=head1 SYNOPSIS

	utils_move_files.pl [options]

=head1 DESCRIPTION

Give this script a list of files and select a filter to run them through and
their names will be changed using the filter. The script is ofcourse careful
not to step over existing files.

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

=item B<type> (type: stri, default: image/jpeg)

what type to look for ?

=item B<suffix> (type: stri, default: .jpg)

what suffix to give ?

=item B<directories> (type: dlst, default: .)

what directories to process ?

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

	0.00 MV md5 project
	0.01 MV website construction
	0.02 MV improve the movie db xml
	0.03 MV web site automation
	0.04 MV SEE ALSO section fix
	0.05 MV move tests to modules
	0.06 MV bring movie data
	0.07 MV finish papers
	0.08 MV teachers project
	0.09 MV md5 issues

=head1 SEE ALSO

Meta::File::MMagic(3), Meta::Utils::File::Iterator(3), Meta::Utils::File::Move(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.

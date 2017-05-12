#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use File::Find qw();
use Meta::Math::Pad qw();
use Meta::Utils::File::Move qw();

my($demo,$verbose,$index,$dindex,$dire,$pad,$suff,$pref);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("demo","play pretend ?",1,\$demo);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->def_bool("index","give index names or keep names ?",1,\$index);
$opts->def_bool("dindex","give directory index names or keep names ?",0,\$index);
$opts->def_dire("dire","what directory to scan ?",".",\$dire);
$opts->def_inte("pad","how many digits to pad ?",4,\$pad);
$opts->def_stri("suff","what suffix to work on ?","\.jpg",\$suff);
$opts->def_stri("pref","what prefix to work on ?","pref",\$pref);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($hash_directory)={};
my($hash_directory_tag)={};
my($directory_counter)=0;

sub wanted() {
	my($name)=$File::Find::name;
	my($dirx)=$File::Find::dir;
	my($full)=$File::Find::fullname;
#	Meta::Utils::Output::print("name is [".$name."]\n");
#	Meta::Utils::Output::print("dirx is [".$dirx."]\n");
#	Meta::Utils::Output::print("full is [".$full."]\n");
	if(-f $name) {
		# find the directory tag
		if(!exists($hash_directory_tag->{$dirx})) {
			$hash_directory_tag->{$dirx}=$directory_counter;
			$directory_counter++;
		}
		my($dir_tag)=$hash_directory_tag->{$dirx};
		$dir_tag=Meta::Math::Pad::pad($dir_tag,$pad);
		# ok - we have it in dir_tag
		# find the current number within the directory
		if(!exists($hash_directory->{$dirx})) {
			$hash_directory->{$dirx}=0;
		}
		my($counter)=$hash_directory->{$dirx};
		$hash_directory->{$dirx}++;
		$counter=Meta::Math::Pad::pad($counter,$pad);
		# ok - we have it in counter
		my($new_name)=$dirx."/".$pref."_".$dir_tag."_".$counter.$suff;
		if($verbose) {
			Meta::Utils::Output::print("source is [".$name."]\n");
			Meta::Utils::Output::print("target is [".$new_name."]\n");
		}
		if(!$demo) {
			Meta::Utils::File::Move::mv_noov($name,$new_name);
		}
	}
	return(0);
}

File::Find::find({ wanted=>\&wanted,no_chdir=>1 },$dire);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pics_give_dir_names.pl - give names according to directories.

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

	MANIFEST: pics_give_dir_names.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	pics_give_dir_names.pl [options]

=head1 DESCRIPTION

This program receives a directory name and runs through some or all of
the files in that directory (you can give a regexp to filter) and gives
a name which indicates the directory first and the original or index
later.

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

=item B<demo> (type: bool, default: 1)

play pretend ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<index> (type: bool, default: 1)

give index names or keep names ?

=item B<dindex> (type: bool, default: 0)

give directory index names or keep names ?

=item B<dire> (type: dire, default: .)

what directory to scan ?

=item B<pad> (type: inte, default: 4)

how many digits to pad ?

=item B<suff> (type: stri, default: .jpg)

what suffix to work on ?

=item B<pref> (type: stri, default: pref)

what prefix to work on ?

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
	0.04 MV thumbnail user interface
	0.05 MV dbman package creation
	0.06 MV more thumbnail issues
	0.07 MV paper writing
	0.08 MV website construction
	0.09 MV improve the movie db xml
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV move tests to modules
	0.13 MV md5 issues

=head1 SEE ALSO

File::Find(3), Meta::Math::Pad(3), Meta::Utils::File::Move(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

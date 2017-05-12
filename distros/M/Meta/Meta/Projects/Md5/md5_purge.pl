#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Iterator qw();
use Meta::Utils::Output qw();
use Meta::Digest::MD5 qw();
use Meta::Digest::Collection qw();
use Meta::Ds::Noset qw();
use MIME::Base64 qw();
use Meta::Utils::File::Remove qw();
use Term::ReadKey qw();
use Error qw(:try);
use Meta::Development::Assert qw();

my($verb,$dire,$interactive);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",1,\$verb);
$opts->def_dlst("directories","directory list to scan",".",\$dire);
$opts->def_bool("interactive","present menues for deletion ?",1,\$interactive);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($collection)=Meta::Digest::Collection->new();
my($dups)=Meta::Ds::Noset->new();

my($iterator)=Meta::Utils::File::Iterator->new();
#$iterator->add_directory($dire);
$iterator->add_directories($dire,':');
$iterator->set_want_dirs(0);
$iterator->set_want_files(1);
$iterator->start();
while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	Meta::Utils::Output::verbose($verb,"working on [".$curr."]\n");
	my($sum)=Meta::Digest::MD5::get_filename_digest($curr);
	$collection->insert($curr,$sum);
	my($set)=$collection->get_files_by_sum($sum);
	if($set->size()>1) {
		if($dups->hasnt($sum)) {
			$dups->insert($sum);
		}
	}
	$iterator->next();
}
$iterator->fini();

# now iterate over duplicates and remove them.
for(my($i)=0;$i<$dups->size();$i++) {
	my($curr)=$dups->elem($i);
	my($set)=$collection->get_files_by_sum($curr);
	if($verb) {
		my($printable)=MIME::Base64::encode($curr,"");
		Meta::Utils::Output::verbose($verb,"working on set for sum [".$printable."]\n");
	}
	if($interactive) {
		my($ok)=0;
		while(!$ok) {
			for(my($j)=0;$j<$set->size();$j++) {
				my($curr_file)=$set->elem($j);
				Meta::Utils::Output::print($j.") keep [".$curr_file."]\n");
			}
			Meta::Utils::Output::print("a) interrupt.\n");
			Meta::Utils::Output::print("b) skip.\n");
			my($line)=Term::ReadKey::ReadLine(0);
			CORE::chop($line);
			if($line eq "a") {
				Term::ReadKey::ReadMode(0);
				throw Meta::Error::Simple("caught interrupt");
				$ok=1;
			} else {
				if($line eq "b") {
					$ok=1;
				} else {
					Meta::Development::Assert::is_number($line);
					if($line>=0 && $line<$set->size()) {
						for(my($j)=0;$j<$set->size()-1;$j++) {
							if($j!=$line) {
								my($curr_file)=$set->elem($j);
								if($verb) {
									Meta::Utils::Output::print("removing [".$curr_file."]\n");
								}
								Meta::Utils::File::Remove::rm($curr_file);
							}
						}
						$ok=1;
					} else {
						Meta::Utils::Output::print("got bad input [".$line."]\n");
					}
				}
			}
		}
		#Meta::Utils::Output::print("got line [".$line."]\n");
	} else {
		#the 1 is to keep at least one version of the file in question
		for(my($j)=1;$j<$set->size();$j++) {
			my($curr_file)=$set->elem($j);
			Meta::Utils::Output::verbose($verb,"removing [".$curr_file."]\n");
			Meta::Utils::File::Remove::rm($curr_file);
		}
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

md5_purge.pl - remove duplicated in a directory according to MD5 sums.

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

	MANIFEST: md5_purge.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	md5_purge.pl [options]

=head1 DESCRIPTION

Give this script a set of directories to work on and it will remove all duplicates
in that directory.

This script provide two policies:
1. Ask the user on each set of duplicates on which to remove.
	You will be prompted on which of the duplicates you want to keep.
	Keep in mind that more than two duplicate files may exists and so
	more than one file may be erased at each interaction.
2. Remove the duplicate itself.
	The script will just remove all but the first instance of the
	duplicates group.

The default policy is to ask the user.

How does this script work ?

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

noisy or quiet ?

=item B<directories> (type: dlst, default: .)

directory list to scan

=item B<interactive> (type: bool, default: 1)

present menues for deletion ?

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

	0.00 MV more pdmt stuff
	0.01 MV md5 issues

=head1 SEE ALSO

Error(3), MIME::Base64(3), Meta::Development::Assert(3), Meta::Digest::Collection(3), Meta::Digest::MD5(3), Meta::Ds::Noset(3), Meta::Utils::File::Iterator(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Term::ReadKey(3), strict(3)

=head1 TODO

-implement getting more than one directory to recurse.

#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Meta::Xml::Dom qw();
use Meta::Lang::Xml::Xml qw();

my($verb,$file,$vali);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_stri("file","where is the xml db file ?","xmlx/music/music.xml",\$file);
$opts->def_bool("vali","use a validating parser ?",0,\$vali);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

if($verb) {
	Meta::Utils::Output::print("Analyzing...\n");
}
Meta::Lang::Xml::Xml::setup_path();
my($file)=Meta::Baseline::Aegis::which($file);
my($parser)=Meta::Xml::Dom->new_vali($vali);
my($doc)=$parser->parsefile($file);
 
my($artist_number)=$doc->getElementsByTagName("artist")->getLength();
my($cd_number)=$doc->getElementsByTagName("cd")->getLength();
my($have_number)=$doc->getElementsByTagName("have")->getLength();
my($hear_number)=$doc->getElementsByTagName("hear")->getLength();
my($borrow_number)=$doc->getElementsByTagName("borrow")->getLength();

Meta::Utils::Output::print("number of artist is [".$artist_number."]\n");
Meta::Utils::Output::print("number of cd is [".$cd_number."]\n");
Meta::Utils::Output::print("number of have is [".$have_number."]\n");
Meta::Utils::Output::print("number of hear is [".$hear_number."]\n");
Meta::Utils::Output::print("number of borrow is [".$borrow_number."]\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

music_stats.pl - show statistics from my private xml music database.

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

	MANIFEST: music_stats.pl
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	music_stats.pl [options]

=head1 DESCRIPTION

This script reports various statistics about music hears from the music xml
database.
Currently it reports these metrics:
0. Number of artists in the database.
1. Number of cds in the database.
2. Number of haves in the database.
3. Number of hears in the database.
4. Number of borrows in the database.

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

noisy or quiet ?

=item B<file> (type: stri, default: xmlx/music/music.xml)

where is the xml db file ?

=item B<vali> (type: bool, default: 0)

use a validating parser ?

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

	0.00 MV fix database problems
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV more Class method generation
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Lang::Xml::Xml(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Xml::Dom(3), strict(3)

=head1 TODO

Nothing.

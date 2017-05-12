#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use XML::DOM::ValParser qw();
use XML::DOM qw();
use Meta::Imdb::Get qw();
use Meta::Utils::Output qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

# these should be parameters to the script.

my($all)=0;#should all directors be updated ?
my($validate)=0;#should the reading parser be a validating one ?
my($update)=0;#should the script update the XML ?
my($verbose)=1;#should the script be noisy ?

Meta::Utils::Output::print("Analyzing...\n");
my($file)=Meta::Baseline::Aegis::which("xmlx/movie.xml");
my(@list);
my($search_path)=Meta::Baseline::Aegis::search_path_list();
for(my($i)=0;$i<=$#$search_path;$i++) {
	push(@list,$search_path->[$i]."/dtdx");
}
XML::Checker::Parser::set_sgml_search_path(@list);
my($parser);
if($validate) {
	$parser=XML::DOM::ValParser->new();
} else {
	$parser=XML::DOM::Parser->new();
}
my($doc)=$parser->parsefile($file);
 
my($directors);
$directors=$doc->getElementsByTagName("director");
for(my($i)=0;$i<$directors->getLength();$i++) {
	my($director)=$directors->[$i];
	my($doit)=0;
	if($all) {
		$doit=1;
	} else {
		my($imdbid)=$director->getElementsByTagName("imdbid");
		if(!$imdbid) {
			$doit=1;
		}
	}
	if($doit) {
		my($firstname)=$director->getElementsByTagName("firstname")->[0]->getFirstChild()->getData();
		my($secondname)=$director->getElementsByTagName("secondname")->[0]->getFirstChild()->getData();
		if($verbose) {
			Meta::Utils::Output::print("doing [".$firstname."] [".$secondname."]\n");
		}
		my($imdb)=Meta::Imdb::Get->new();
		my($id)=$imdb->get_director_id($firstname,$secondname);
		Meta::Utils::Output::print("got id [".$id."]\n");
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

movie_update.pl - update director/movie imdb ids for not known ones.

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

	MANIFEST: movie_update.pl
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	movie_update.pl [options]

=head1 DESCRIPTION

This script will iterate thorough all directors/movies and will update
their imdb ids.

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

	0.00 MV more movies
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV thumbnail user interface
	0.05 MV more thumbnail issues
	0.06 MV website construction
	0.07 MV improve the movie db xml
	0.08 MV web site automation
	0.09 MV SEE ALSO section fix
	0.10 MV move tests to modules
	0.11 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Imdb::Get(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::DOM(3), XML::DOM::ValParser(3), strict(3)

=head1 TODO

Nothing.

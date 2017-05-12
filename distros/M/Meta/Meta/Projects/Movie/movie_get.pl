#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Imdb::Get qw();

my($movie,$director,$first,$second,$title_id,$agent,$referer);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("movie","what movie name ?","zelig",\$movie);
$opts->def_stri("director","what director name ?","Woody Allen",\$director);
$opts->def_stri("first","what director first name ?","Woody",\$first);
$opts->def_stri("second","what director second name ?","Allen",\$second);
$opts->def_stri("title_id","what title id ?","0086637",\$title_id);
$opts->def_stri("agent","what agent id to use ?","MVbrowser/v5.7 Platinum",\$agent);
$opts->def_stri("referer","what refere url to use ?","http://www.nomorebillgates.org",\$referer);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($imdb)=Meta::Imdb::Get->new();
$imdb->set_agent($agent);
$imdb->set_referer($referer);
my($info)=$imdb->get_title_info($title_id);
#Meta::Utils::Output::print("director is [".$info."]\n");
Meta::Utils::Output::dump($info);
#my($html1)=$imdb->get_page($director,$movie);
#my($html2)=$imdb->get_title($title);
#my($html3)=$imdb->get_director_id($first,$second);
#my($html4)=$imdb->get_search_page();
#my($html5)=$imdb->get_page_form($director,$movie);
#my($html6)=$imdb->get_director_id_form($first,$second);
#my($birth)=$imdb->get_birth_name($first,$second);
#Meta::Utils::Output::print("birth name is [".$birth."]\n");

#Meta::Utils::Output::print($html1);
#Meta::Utils::Output::print($html2);
#Meta::Utils::Output::print($html3);
#Meta::Utils::Output::print($html4);
#Meta::Utils::Output::print($html5);
#Meta::Utils::Output::print($html6);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

movie_get.pl - get data from imdb.

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

	MANIFEST: movie_get.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	movie_get.pl [options]

=head1 DESCRIPTION

This program demostrates how to get data from Imdb using director name
and movie name.

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

=item B<movie> (type: stri, default: zelig)

what movie name ?

=item B<director> (type: stri, default: Woody Allen)

what director name ?

=item B<first> (type: stri, default: Woody)

what director first name ?

=item B<second> (type: stri, default: Allen)

what director second name ?

=item B<title_id> (type: stri, default: 0086637)

what title id ?

=item B<agent> (type: stri, default: MVbrowser/v5.7 Platinum)

what agent id to use ?

=item B<referer> (type: stri, default: http://www.nomorebillgates.org)

what refere url to use ?

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
	0.04 MV md5 progress
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV teachers project
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Imdb::Get(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Tool::Editor qw();
use Meta::Utils::File::File qw();
use Meta::Info::Enum qw();
use Meta::Utils::Output qw();

my($freg,$type,$acti,$repe,$demo,$verb,$prin,$lrep,$lreg,$match);
my($opts)=Meta::Utils::Opts::Opts->new();
my($type_enum)=Meta::Baseline::Aegis::get_enum();
my($action_enum)=Meta::Info::Enum->new();
$action_enum->insert("none","dont do anything");
$action_enum->insert("print","print the matches");
$action_enum->insert("edit","edit the files");
$action_enum->insert("replace","do replacement on the files content");
$action_enum->insert("checkout","checkout the files");
$action_enum->insert("checkout_edit","checkout the files and edit them");
$action_enum->insert("checkout_replace","checkout the files and replace the content");
$action_enum->set_default("print");
$opts->set_standard();
$opts->def_stri("fileregexp","regular expression on the file names","",\$freg);
$opts->def_enum("type","what types of files to look at ?","source",\$type,$type_enum);
$opts->def_enum("action","what action to be done with the files found ?","print",\$acti,$action_enum);
$opts->def_stri("replace","regular expression for substitution","",\$repe);
$opts->def_bool("rep_file","should the substitution be loaded from file ?",0,\$lrep);
$opts->def_bool("rep_rege","should the regexp be loaded from file ?",0,\$lreg);
$opts->def_bool("demo","play around or do it for real ?",0,\$demo);
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_bool("print","print progress ?",0,\$prin);
$opts->def_bool("match","match file regexps ?",1,\$match);
$opts->set_free_allo(1);
$opts->set_free_stri("[regexp]");
$opts->set_free_mini(1);
$opts->set_free_maxi(1);
$opts->analyze(\@ARGV);

my($rege)=$ARGV[0];
if($lreg) {
	my($temp);
	Meta::Utils::File::File::load($rege,\$temp);
	$rege=$temp;
}
if($lrep) {
	my($temp);
	Meta::Utils::File::File::load($repe,\$temp);
	$repe=$temp;
}
my($show,$chec,$edit,$repl)=(0,0,0,0);
if($action_enum->is_selected($acti,"none")) {
}
if($action_enum->is_selected($acti,"print")) {
	$show=1;
}
if($action_enum->is_selected($acti,"edit")) {
	$edit=1;
}
if($action_enum->is_selected($acti,"replace")) {
	$repl=1;
}
if($action_enum->is_selected($acti,"checkout")) {
	$chec=1;
}
if($action_enum->is_selected($acti,"checkout_edit")) {
	$chec=1;
	$edit=1;
}
if($action_enum->is_selected($acti,"checkout_replace")) {
	$chec=1;
	$repl=1;
}
my($set);
if($type_enum->is_selected($type,"change")) {
	$set=Meta::Baseline::Aegis::change_files_set(1,1,0,1,1,1);
}
if($type_enum->is_selected($type,"project")) {
	$set=Meta::Baseline::Aegis::project_files_set(1,1,1);
}
if($type_enum->is_selected($type,"source")) {
	$set=Meta::Baseline::Aegis::source_files_set(1,1,0,1,1,1);
}
if($match) {
	$set=$set->filter_regexp($freg);
	$set=$set->filter_content($rege);
}
if($verb) {
	my($numb)=$set->size();
	Meta::Utils::Output::verbose($prin,"doing [".$numb."] files\n");
	$set->foreach(\&Meta::Utils::Output::println);
}
if($chec) {
	if(!$demo) {
		my($change)=Meta::Baseline::Aegis::change_files_set(1,1,0,1,1,1);
		my($baseline_set)=$set->clone();
		$baseline_set->remove_set($change);
		Meta::Baseline::Aegis::checkout_set($baseline_set);
	}
}
if($edit) {
	if(!$demo) {
		Meta::Tool::Editor::edit_set_pat($set,$rege);
	}
}
if($repl) {
	if(!$demo) {
		for(my($i)=0;$i<$set->size();$i++) {
			my($curr)=$set->elem($i);
			Meta::Utils::Output::verbose($verb,"doing [".$curr."]\n");
			my($count)=Meta::Utils::File::File::subst($curr,$rege,$repe);
			Meta::Utils::Output::verbose($verb,"replaced [".$count."]\n");
		}
	}
}
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

base_tool_grep.pl - grep multiple source files according to patterns.

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

	MANIFEST: base_tool_grep.pl
	PROJECT: meta
	VERSION: 0.37

=head1 SYNOPSIS

	base_tool_grep.pl

=head1 DESCRIPTION

This script accepts:
0. relative path in the baseline
1. regular expression to search for in the files content.
2. regular expression for names of files to be searched (*.nw,*.cc,*.java,*.pl,*.pm etc...).
3. type of image to take as baseline. Three options are available:
	a. change: search only my change.
	b. project: search the current baseline.
	c. source: search my image of the baseline (meaning the baseline as
		it is overriden by my change). This is the default.
The idea is to be able to quickly and efficiently do massive editing jobs on your entire
source code usually from your changed point of view. You can do various things with this script:
1. checkout multiple files from the baseline.
2. replace regular expressions on multiple files.
3. checkout and replace (1+2).
4. just print which files match.
5. run an editor on all matched files.
6. checkout and run an editor on all matched files (1+5).
You can actually use aefind which is supplied with Aegis to do finds instead of
this script (this is quite a new feature from Peter Miller).

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

=item B<fileregexp> (type: stri, default: )

regular expression on the file names

=item B<type> (type: enum, default: source)

what types of files to look at ?

options:
	change - just files from the current change
	project - just files from the current baseline
	source - complete source manifest

=item B<action> (type: enum, default: print)

what action to be done with the files found ?

options:
	none - dont do anything
	print - print the matches
	edit - edit the files
	replace - do replacement on the files content
	checkout - checkout the files
	checkout_edit - checkout the files and edit them
	checkout_replace - checkout the files and replace the content

=item B<replace> (type: stri, default: )

regular expression for substitution

=item B<rep_file> (type: bool, default: 0)

should the substitution be loaded from file ?

=item B<rep_rege> (type: bool, default: 0)

should the regexp be loaded from file ?

=item B<demo> (type: bool, default: 0)

play around or do it for real ?

=item B<verbose> (type: bool, default: 0)

noisy or quiet ?

=item B<print> (type: bool, default: 0)

print progress ?

=item B<match> (type: bool, default: 1)

match file regexps ?

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

	0.00 MV initial code brought in
	0.01 MV c++ and perl code quality checks
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV more harsh checks on perl code
	0.06 MV fix todo items look in pod documentation
	0.07 MV make all tests real tests
	0.08 MV fix all tests change
	0.09 MV more on tests
	0.10 MV silense all tests
	0.11 MV more perl quality
	0.12 MV change new methods to have prototypes
	0.13 MV perl code quality
	0.14 MV more perl quality
	0.15 MV more perl quality
	0.16 MV perl documentation
	0.17 MV more perl quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV perl reorganization
	0.21 MV perl packaging
	0.22 MV license issues
	0.23 MV md5 project
	0.24 MV database
	0.25 MV perl module versions in files
	0.26 MV thumbnail user interface
	0.27 MV more thumbnail issues
	0.28 MV website construction
	0.29 MV improve the movie db xml
	0.30 MV web site development
	0.31 MV web site automation
	0.32 MV SEE ALSO section fix
	0.33 MV move tests to modules
	0.34 MV bring movie data
	0.35 MV finish papers
	0.36 MV teachers project
	0.37 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Info::Enum(3), Meta::Tool::Editor(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-add an option to just print which files match without the match content (one print per file).

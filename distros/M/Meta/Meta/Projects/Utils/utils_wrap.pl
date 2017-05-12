#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::File qw();
use Text::Wrap qw();
use Meta::Utils::Output qw();

my($initial_tab,$subsequent_tab,$columns,$break,$unexpand,$tabstop,$separator,$huge,$verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("initial_tab","initial tab on line",'\t',\$initial_tab);
$opts->def_stri("subsequent_tab","subsequent tab",'',\$subsequent_tab);
$opts->def_inte("columns","number of columns to wrap at",80,\$columns);
$opts->def_stri("break","reg exp to break lines at",'\s',\$break);
$opts->def_bool("unexpand","unexpand",1,\$unexpand);
$opts->def_inte("tabstop","how many characters per tab",8,\$tabstop);
$opts->def_stri("separator","string to separate lines","\n",\$separator);
$opts->def_stri("huge","what to do on huge lines",'die',\$huge);
$opts->def_bool("verbose","reg exp to break lines at",1,\$verb);
$opts->set_free_allo(1);
$opts->set_free_stri("[files]");
$opts->set_free_mini(1);
$opts->set_free_noli(1);
$opts->analyze(\@ARGV);

$Text::Wrap::colunms=$columns;
$Text::Wrap::break=$break;
$Text::Wrap::unexpand=$unexpand;
$Text::Wrap::tabstop=$tabstop;
$Text::Wrap::separator=$separator;
$Text::Wrap::huge=$huge;

for(my($i)=0;$i<=$#ARGV;$i++) {
	my($curr)=$ARGV[$i];
	Meta::Utils::Output::verbose($verb,"working on [".$curr."]\n");
	my($text);
	Meta::Utils::File::File::load($curr,\$text);
	my($res)=Text::Wrap::wrap($initial_tab,$subsequent_tab,$text);
	Meta::Utils::File::File::save($curr,$res);
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_wrap.pl - wrap text files.

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

	MANIFEST: utils_wrap.pl
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	utils_wrap.pl [options]

=head1 DESCRIPTION

Give this script a few files and it will wrap them for you!!!
This script uses the Text::Wrap module.

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

=item B<initial_tab> (type: stri, default: \t)

initial tab on line

=item B<subsequent_tab> (type: stri, default: )

subsequent tab

=item B<columns> (type: inte, default: 80)

number of columns to wrap at

=item B<break> (type: stri, default: \s)

reg exp to break lines at

=item B<unexpand> (type: bool, default: 1)

unexpand

=item B<tabstop> (type: inte, default: 8)

how many characters per tab

=item B<separator> (type: stri, default: 
)

string to separate lines

=item B<huge> (type: stri, default: die)

what to do on huge lines

=item B<verbose> (type: bool, default: 1)

reg exp to break lines at

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

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV put all tests in modules
	0.03 MV move tests to modules
	0.04 MV md5 issues

=head1 SEE ALSO

Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Text::Wrap(3), strict(3)

=head1 TODO

-fix the fact that this script leaves "\t" at the start of the corrected files.

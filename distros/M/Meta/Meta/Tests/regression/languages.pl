#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Switch qw();
use Meta::Utils::List qw();
use Meta::Utils::Output qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

#my($list)=Meta::Baseline::Aegis::source_files_list(1,1,0,1,1,0);
my($list)=Meta::Baseline::Aegis::total_files_list(0,0);
my($scod)=1;
for(my($i)=0;$i<=$#$list;$i++) {
	my($curr)=$list->[$i];
#	Meta::Utils::Output("curr is [".$curr."]\n");
	my($count)=Meta::Baseline::Switch::get_count($curr);
	if($count!=1) {
		$scod=0;
		if($count==0) {
			Meta::Utils::Output::print("module [".$curr."] owned by none\n");
		} else {
			my($list)=Meta::Baseline::Switch::get_own($curr);
			Meta::Utils::Output::print("module [".$curr."] owned by many\n");
			Meta::Utils::List::print(Meta::Utils::Output::get_file(),$list);
		}
	}
}

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit($scod);

__END__

=head1 NAME

languages.pl - test that every file in the baseline is from some language.

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

	MANIFEST: languages.pl
	PROJECT: meta
	VERSION: 0.24

=head1 SYNOPSIS

	languages.pl

=head1 DESCRIPTION

This test will create a list of all the project files and will test that
each one of them has a language module which says that it is his and ONLY
one which says so...:)

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

	0.00 MV better general cook schemes
	0.01 MV revision in files
	0.02 MV revision for perl files and better sanity checks
	0.03 MV languages.pl test online
	0.04 MV history change
	0.05 MV perl reorganization
	0.06 MV more on data sets
	0.07 MV pics with db support
	0.08 MV automatic data sets
	0.09 MV spelling and papers
	0.10 MV perl packaging
	0.11 MV license issues
	0.12 MV md5 project
	0.13 MV database
	0.14 MV perl module versions in files
	0.15 MV thumbnail user interface
	0.16 MV import tests
	0.17 MV more thumbnail issues
	0.18 MV website construction
	0.19 MV improve the movie db xml
	0.20 MV web site automation
	0.21 MV SEE ALSO section fix
	0.22 MV move tests to modules
	0.23 MV teachers project
	0.24 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Switch(3), Meta::Baseline::Test(3), Meta::Utils::List(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

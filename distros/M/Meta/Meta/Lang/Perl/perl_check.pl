#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Lang::Perl qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Error qw(:try);

my($enum)=Meta::Baseline::Aegis::get_enum();

my($type,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_enum("type","what source files to take ?","change",\$type,$enum);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($fileset);
if($enum->is_selected($type,"change")) {
	$fileset=Meta::Baseline::Aegis::change_files_hash(1,1,1,1,1,0);
}
if($enum->is_selected($type,"project")) {
	$fileset=Meta::Baseline::Aegis::project_files_hash(1,1,0);
}
if($enum->is_selected($type,"source")) {
	$fileset=Meta::Baseline::Aegis::source_files_hash(1,1,0,1,1,0);
}
for(my($i)=0;$i<$fileset->size();$i++) {
	my($modu)=$fileset->key($i);
	try {
		Meta::Baseline::Lang::Perl->source_file($modu);
		Meta::Utils::Output::verbose($verbose,"checking [".$modu."]...");
		my($srcx)=Meta::Baseline::Aegis::which($modu);
		my($path)=Meta::Baseline::Aegis::search_path();
		my($resu)=Meta::Baseline::Lang::Perl::check($modu,$srcx,$path);
		if($resu) {
			Meta::Utils::Output::verbose($verbose,"ok\n");
		} else {
			Meta::Utils::Output::verbose($verbose,"fail\n");
		}
	}
	# do nothing since we dont care if the check fails or this is
	# not a perl source file.
	catch Error with {
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

perl_check.pl - check all perl source files in the baseline.

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

	MANIFEST: perl_check.pl
	PROJECT: meta
	VERSION: 0.05

=head1 SYNOPSIS

	perl_check.pl [options]

=head1 DESCRIPTION

This script will quesry the source management system about which
sources are perl sources and will runa check on all of those files.

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

=item B<type> (type: enum, default: change)

what source files to take ?

options:
	change - just files from the current change
	project - just files from the current baseline
	source - complete source manifest

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

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

	0.00 MV put all tests in modules
	0.01 MV move tests to modules
	0.02 MV bring movie data
	0.03 MV finish papers
	0.04 MV teachers project
	0.05 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::Baseline::Lang::Perl(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

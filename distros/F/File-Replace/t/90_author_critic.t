#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

=head1 Synopsis

Tests for the Perl module File::Replace.

=begin comment

How to run coverage tests:

 which cover  # make sure it's the one for the current Perl
 perl Makefile.PL
 make
 make test
 cover -test -coverage default,-pod
 firefox cover_db/coverage.html
 make distclean
 rm -rf cover_db/

Running tests on all Perl versions: Install the required Perl versions (see
list below), note that some test failures in Perl <5.10 can be ignored. In each
Perl version, install L<App::cpanminus|App::cpanminus> (may need to do this
manually on Perls <5.8.9), then install L<Test::Fatal|Test::Fatal>, which
should install dependencies like Test-Simple, as well as
L<App::Prove|App::Prove> for ease of testing (can use C<perlbrew exec> as shown
below for this). Then:

 perlbrew exec --with 5.8.1,5.8.9,5.10.1,5.12.5,5.14.4,5.16.3,5.18.4,5.20.3,5.22.4,5.24.2,5.26.0 prove -l

=end comment

=head1 Author, Copyright, and License

Copyright (c) 2017 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use File_Replace_Testlib;

use File::Spec::Functions qw/catfile catdir abs2rel/;
use File::Glob 'bsd_glob';
our @PERLFILES;
BEGIN {
	@PERLFILES = (
		catfile($FindBin::Bin,qw/ .. lib File Replace.pm /),
		catfile($FindBin::Bin,qw/ .. lib File Replace DualHandle.pm /),
		catfile($FindBin::Bin,qw/ .. lib File Replace SingleHandle.pm /),
		catfile($FindBin::Bin,qw/ .. lib Tie Handle Base.pm /),
		bsd_glob("$FindBin::Bin/*.t"),
		bsd_glob("$FindBin::Bin/*.pm"),
	);
}

use Test::More $AUTHOR_TESTS ? (tests=>2*@PERLFILES)
	: (skip_all=>'author Perl::Critic tests (set $ENV{FILE_REPLACE_AUTHOR_TESTS} to enable)');

use Test::Perl::Critic -profile=>catfile($FindBin::Bin,'perlcriticrc');
use Test::MinimumVersion;

my @tasks;
for my $file (@PERLFILES) {
	critic_ok($file);
	minimum_version_ok($file, '5.008');
	open my $fh, '<', $file or die $!;  ## no critic (RequireCarping)
	while (<$fh>) {
		s/\A\s+|\s+\z//g;
		push @tasks, [abs2rel($file,catdir($FindBin::Bin,'..')), $., $_] if /T[O][D]O/;
	}
	close $fh;
}
diag "To-","Do Report: ", 0+@tasks, " To-","Dos found";
diag "### TO","DOs ###" if @tasks;
diag "$$_[0]:$$_[1]: $$_[2]" for @tasks;
diag "### ###" if @tasks;


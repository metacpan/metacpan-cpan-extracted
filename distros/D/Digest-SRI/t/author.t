#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Author Tests for the Perl module Digest::SRI.

=head1 Notes

For notes on how to run C<cover> and C<perlbrew>, see e.g.:
L<https://github.com/haukex/File-Replace/blob/master/t/90_author_critic.t>

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
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
use Digest_SRI_Testlib;
use File::Spec::Functions qw/catfile abs2rel catdir/;
use File::Glob 'bsd_glob';

our (@PODFILES,@PERLFILES);
BEGIN {
	@PERLFILES = (
		catfile($FindBin::Bin,qw/ .. lib Digest SRI.pm /),
		bsd_glob("$FindBin::Bin/*.t"),
		bsd_glob("$FindBin::Bin/*.pm"),
	);
	@PODFILES = (
		catfile($FindBin::Bin,qw/ .. lib Digest SRI.pm /),
	);
}

use Test::More $AUTHOR_TESTS ? ( tests => @PODFILES + 2*@PERLFILES )
	: (skip_all=>'author tests (set $ENV{DIGEST_SRI_AUTHOR_TESTS} to enable)');

use Test::Perl::Critic -profile=>catfile($FindBin::Bin,'perlcriticrc');
use Test::MinimumVersion;
use Test::Pod;

for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
}

my @tasks;
for my $file (@PERLFILES) {
	critic_ok($file);
	minimum_version_ok($file, '5.006');
	open my $fh, '<', $file or die $!;  ## no critic (RequireCarping)
	while (<$fh>) {
		s/\A\s+|\s+\z//g;
		push @tasks, [abs2rel($file,catdir($FindBin::Bin,'..')), $., $_] if /TO.?DO/i;
	}
	close $fh;
}
diag "To-","Do Report: ", 0+@tasks, " To-","Dos found";
diag "### TO","DOs ###" if @tasks;
diag "$$_[0]:$$_[1]: $$_[2]" for @tasks;
diag "### ###" if @tasks;


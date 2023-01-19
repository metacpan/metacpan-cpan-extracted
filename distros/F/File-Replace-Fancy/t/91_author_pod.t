#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

=head1 Synopsis

Tests for the Perl distribution File::Replace::Fancy.

=head1 Author, Copyright, and License

Copyright (c) 2017-2023 Hauke Daempfling (haukex@zero-g.net)
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

use File::Spec::Functions qw/catfile/;
our @PODFILES;
BEGIN {
	@PODFILES = (
		catfile($FindBin::Bin,qw/ .. lib File Replace Fancy.pm /),
		catfile($FindBin::Bin,qw/ .. lib File Replace DualHandle.pm /),
		catfile($FindBin::Bin,qw/ .. lib File Replace SingleHandle.pm /),
	);
}

use Test::More $AUTHOR_TESTS ? (tests=>1*@PODFILES+1)
	: (skip_all=>'author POD tests');

use Test::Pod;

for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
}

subtest 'other doc bits' => sub {
	use File::Replace 'replace';
	my $handle = replace(newtempfn);
	# other bits from the documentation
	ok defined eof( tied(*$handle)->out_fh ), 'out eof';
	ok defined tied(*$handle)->out_fh->tell(), 'out tell';
	close $handle;
};


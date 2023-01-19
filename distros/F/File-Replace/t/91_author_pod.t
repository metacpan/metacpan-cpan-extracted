#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

=head1 Synopsis

Tests for the Perl module File::Replace.

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
		catfile($FindBin::Bin,qw/ .. lib File Replace.pod /),
	);
}

use Test::More $AUTHOR_TESTS ? (tests=>1*@PODFILES+1)
	: (skip_all=>'author POD tests');

use Test::Pod;

for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
}

use Capture::Tiny qw/capture_merged/;
use Cwd qw/getcwd/;
use File::Temp qw/tempdir/;
subtest 'verbatim code' => sub {
	## no critic (ProhibitStringyEval, RequireBriefOpen, RequireCarping)
	my $verb_fr = getverbatim($PODFILES[0], qr/\bsynopsis\b/i);
	is @$verb_fr, 1, 'File::Replace verbatim block count'
		or diag explain $verb_fr;
	{
		my $filename = newtempfn("Foo\nBar\nQuz\n");
		eval("use warnings; use strict; $$verb_fr[0]; 1") or fail($@);
		is slurp($filename), "X: Foo\nX: Bar\nX: Quz\n", 'File::Replace synposis';
	}
	## use critic
};

use Pod::Simple::SimpleTree;
sub getverbatim {
	my ($file,$regex) = @_;
	my $tree = Pod::Simple::SimpleTree->new->parse_file($file)->root;
	my ($curhead,@v);
	for my $e (@$tree) {
		next unless ref $e eq 'ARRAY';
		if (defined $curhead) {
			if ($e->[0]=~/^\Q$curhead\E/)
				{ $curhead = undef }
			elsif ($e->[0] eq 'Verbatim')
				{ push @v, $e->[2] }
		}
		elsif ($e->[0]=~/^head\d\b/ && $e->[2]=~$regex)
			{ $curhead = $e->[0] }
	}
	return \@v;
}


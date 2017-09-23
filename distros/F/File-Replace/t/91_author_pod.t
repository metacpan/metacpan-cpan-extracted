#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

=head1 Synopsis

Tests for the Perl module File::Replace.

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

use File::Spec::Functions qw/catfile/;
our @PODFILES;
BEGIN {
	@PODFILES = (
		catfile($FindBin::Bin,qw/ .. lib File Replace.pm /),
		catfile($FindBin::Bin,qw/ .. lib Tie Handle Base.pm /),
		catfile($FindBin::Bin,qw/ .. lib File Replace DualHandle.pm /),
		catfile($FindBin::Bin,qw/ .. lib File Replace SingleHandle.pm /),
	);
}

use Test::More $AUTHOR_TESTS ? (tests=>1*@PODFILES+2)
	: (skip_all=>'author POD tests');

use Test::Pod;

for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
}

subtest 'synposes' => sub {
	## no critic (ProhibitStringyEval)
	my $verb_thb = getsynverb($PODFILES[1]);
	is @$verb_thb, 2, 'Tie::Handle::Base synopsis verbatim block count'
		or diag explain $verb_thb;
	eval("use warnings; use strict; $$verb_thb[0]; 1") or fail($@);
	{
		my $filename = newtempfn;
		use Capture::Tiny qw/capture_merged/;
		is capture_merged {
			eval("use warnings; use strict; $$verb_thb[1]; 1") or fail($@);
		}, "Debug: Output 'Hello, World'\n", 'my tied handle works 1';
		is slurp($filename), "Hello, World", 'my tied handle works 2';
	}
	
	my $verb_fr = getsynverb($PODFILES[0]);
	is @$verb_fr, 3, 'File::Replace synopsis verbatim block count'
		or diag explain $verb_fr;
	{
		my $filename = spew(newtempfn, "Foo\nBar\nQuz\n");
		eval("use warnings; use strict; $$verb_fr[0]; 1") or fail($@);
		is slurp($filename), "X: Foo\nX: Bar\nX: Quz\n", 'synposis 1';
		eval("use warnings; use strict; $$verb_fr[1]; 1") or fail($@);
		is slurp($filename), "Y: X: Foo\nY: X: Bar\nY: X: Quz\n", 'synposis 2';
		eval("use warnings; use strict; $$verb_fr[2]; 1") or fail($@);
		is slurp($filename), "Z: Y: X: Foo\nZ: Y: X: Bar\nZ: Y: X: Quz\n", 'synposis 3';
	}
	## use critic
};

subtest 'other doc bits' => sub {
	my $handle = replace(newtempfn);
	# other bits from the documentation
	ok defined eof( tied(*$handle)->out_fh ), 'out eof';
	ok defined tied(*$handle)->out_fh->tell(), 'out tell';
	close $handle;
};

use Pod::Simple::SimpleTree;
sub getsynverb { # extract verbatim code blocks from the "Synopsis" section
	my $file = shift;
	my $tree = Pod::Simple::SimpleTree->new->parse_file($file)->root;
	my $state = 'idle';
	my @synverb;
	TREE: for my $e (@$tree) {
		next unless ref $e eq 'ARRAY';
		if ($state eq 'idle' && $e->[0] eq 'head1'
			&& $e->[2]=~/\bsynopsis\b/i)
				{ $state = 'synopsis' }
		elsif ($state eq 'synopsis') {
			last TREE if $e->[0]=~/^head/;
			push @synverb, $e->[2] if $e->[0] eq 'Verbatim';
		}
	}
	return \@synverb;
}

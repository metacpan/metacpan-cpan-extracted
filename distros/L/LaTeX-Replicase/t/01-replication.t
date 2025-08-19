# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01-replication.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 12;
use Test::More::UTF8;
use Digest::MD5;


BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(:all);

##### Test replication() #####

my $info = {
		data => { # mandatory data section
			myTitle => 'ChiTaRS-${}_{3.1}$-the enhanced chimeric transcripts and RNA-seq database matched with protein-protein interactions',
			Authors => 'Alessandro Gorohovski, Somnath Tagore, etc...',
			myAbstract => 'Discovery of chimeric RNAs, which are produced by chromosomal translocations as well as 
the joining of exons from different genes by trans-splicing, has added a new level of complexity to our study and 
understanding of the transcriptome. The enhanced ChiTaRS-${}_{3.1}$ database (\url{http://chitars.md.biu.ac.il}) is designed 
to make widely accessible a wealth of mined data on chimeric RNAs, with easy-to-use analytical tools built-in.',
			myCaption => 'The major improvements and data additions in ChiTaRS-${}_{3.1}$ in comparison to ChiTaRS-${}_{2.1}$.',
			myTable_array => [ # custom user variable ARRAY-ARRAY
				['00', '01', '02', '03', '04',], # row 0
				[10, 11, 12, 13, 14,], # row 1
				[20, 21, 22, undef, 24,], # row 2
				[30, 31, 32, 33, 34,], # row 3
			],
			myTable_hash => [ # custom user variable ARRAY-HASH
				{A=>'00', B=>'01', C=>'02', D=>'03', E=>'04',}, # row 0
				{A=>10, B=>11, C=>12, D=>13, E=>14,}, # row 1
				{A=>20, B=>21, C=>22, D=>23, E=>24,}, # row 2
				{A=>30, B=>31, C=>32, D=>33, E=>34,}, # row 3
			],
		},
		cases => { # optional auxiliary data section
			myTable_array => {
				0 => { # table row 0
					3 => [1, 2], # extract from document %%%CASE1: and %%%CASE2: for 3-rd column of table
					1 => [5, 10],
				},
				2 => { # table row 2
					0 => [1, 3], # extract %%%CASE1: and %%%CASE3: for 0-th column
					1 => 2, # extract only %%%CASE2: for 1-st column
					2 => 1,
					4 => 1,
					'' => 5, # extract only %%%CASE5: located at the very "tail" of row
				},
				3 => { # table row 2
					0 => 4, # extract %%%CASE4: for 0-th column
				},
			},
			myTable_hash => {
				1 => { # table row 1
					B => 1, # extract %%%CASE1: for 'B' key (1-st column)
					A => [1, 3], # extract %%%CASE1: and %%%CASE3: for 'A' key (0-th column)
				},
				0 => { # table row 0
					B => 2, # extract %%%CASE2:
					C => [1, 2], # extract %%%CASE1: and %%%CASE2:
				},
			},

		},
	};

### Test 2
my $file = 't/template_good.tex';
my $ofile = 't/ready_good.tex';

my $msg = replication( $file, $info, ofile => $ofile, def => 1, ignore => 1 ) // [];

is( @$msg, 0, "Test #2: '$file'");


###Test 3
open (my $fh, '<', $ofile) or die "Can't open '$ofile': $!";
binmode ($fh);
is( Digest::MD5->new->addfile($fh)->hexdigest, '526a81de57c3ca8618d31d46c40fdc31', "Test #3: MD5SUM of '$ofile'");
close $fh;

###Test 6
my $outdir = 't/tmp';
$msg = replication( $file, $info, outdir => $outdir, def => 1, utf8 => 1, ignore => 1 ) // [];

is( @$msg, 0, "Test #6: OUTDIR");

###Test 7
open ($fh, '<', "$outdir/template_good.tex") or die "Can't open '$outdir/template_good.tex': $!";
binmode ($fh);
is( Digest::MD5->new->addfile($fh)->hexdigest, '526a81de57c3ca8618d31d46c40fdc31', "Test #7: MD5SUM of OUTDIR dor '$file'");
close $fh;


###Test 8
$msg = replication( $file, $info, ofile => $ofile, def => 1, debug => 1 ) // [];

my $md5 = Digest::MD5->new;
for( @$msg ) {
	$md5->add($_);
}
is( $md5->hexdigest, '8e9ca9ce71fa24b2d39c20450af2a1ab', "Test #8: DEBUG");


###Test 4
$file = 't/template_unknown.tex';
$ofile = 't/ready_unknown.tex';

$msg = replication( $file, $info, ofile => $ofile, silent =>1, debug => 0 ) // [];

is( $msg->[0],
	"!!! ERROR#1: 't/template_unknown.tex' does NOT exist or is EMPTY!",
	"Test #4: 't/template_unknown.tex'"
);

###Test 5
$file = 't/template_good.tex';
$ofile = 't/ready_good.tex';

$info = {
		data => { # mandatory data section
			Authors => 'Alessandro Gorohovski, Somnath Tagore, etc...',
		},
	};

$msg = replication( $file, $info, ofile => $ofile, def => 1, silent =>1 ) // [];

my $msg_ref = [
	'~~> WARNING#3: unknown SCALAR tag = myTitle',
	'~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myAbstract',
	'~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myCaption',
	'~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myTable_array',
	'~~> WARNING#3: unknown SCALAR tag = 0',
	'~~> WARNING#3: unknown SCALAR tag = 1',
	'~~> WARNING#3: unknown SCALAR tag = 2',
	'~~> WARNING#3: unknown SCALAR tag = 3',
	'~~> WARNING#3: unknown SCALAR tag = 4',
	'~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myTable_hash',
	'~~> WARNING#3: unknown SCALAR tag = A',
	'~~> WARNING#3: unknown SCALAR tag = B',
	'~~> WARNING#3: unknown SCALAR tag = C',
	'~~> WARNING#3: unknown SCALAR tag = D',
	'~~> WARNING#3: unknown SCALAR tag = E',
	'~~> WARNING#3: unknown SCALAR tag = NoNameI',
	'~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:NoNameII',
];

is_deeply( $msg, $msg_ref, "Test #5: unknown %%%VARs");


###Test 11
$msg = replication( $file, $info, ofile => $ofile, def => 1, silent =>1, debug => 1 ) // [];

my $msg_ref2 = [
	"--> Check 't/template_good.tex' file",
	"--> Using 't/ready_good.tex' file as output",
	"--> Open 't/template_good.tex'",
	"--> Open 't/ready_good.tex'",
	"~~> WARNING#3: unknown SCALAR tag = myTitle",
	"--> Found %%%VAR:Authors",
	"--> Insert SCALAR %%%VAR value = Alessandro Gorohovski, Somnath Tagore, etc...",
	"~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myAbstract",
	"~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myCaption",
	"~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myTable_array",
	"~~> WARNING#3: unknown SCALAR tag = 0",
	"~~> WARNING#3: unknown SCALAR tag = 1",
	"~~> WARNING#3: unknown SCALAR tag = 2",
	"~~> WARNING#3: unknown SCALAR tag = 3",
	"~~> WARNING#3: unknown SCALAR tag = 4",
	"~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:myTable_hash",
	"~~> WARNING#3: unknown SCALAR tag = A",
	"~~> WARNING#3: unknown SCALAR tag = B",
	"~~> WARNING#3: unknown SCALAR tag = C",
	"~~> WARNING#3: unknown SCALAR tag = D",
	"~~> WARNING#3: unknown SCALAR tag = E",
	"~~> WARNING#3: unknown SCALAR tag = NoNameI",
	"~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:NoNameII",
];

is_deeply( $msg, $msg_ref2, "Test #11: unknown %%%VARs with DEBUG");


###Test 9
$msg = replication( $file, $info, ofile => $file, silent =>1, debug => 0 ) // [];

is( $msg->[0], "!!! ERROR#3: Input (template) & output files match. Can't overwrite template file!", "Test #9: INFILE == OUTFILE");

###Test 10
$msg = replication( $file, {}, ofile => $file, silent =>1 ) // [];

is( $msg->[0], "!!! ERROR#2: EMPTY data!", "Test #10: EMPTY data");


###Test 12
$file = 't/template_good.tex';
$ofile = 't/ready_good.tex';

$info = {
		data => {
			myTitle => 'My Title',
			Authors => 'Alessandro Gorohovski, etc...',
			myAbstract => 'My Abstract',
			myCaption => 'My Caption',
			myTable_array => {
				0 => ['00', '01', '02', '03', '04',], # row 0
			},
		},
	};

$msg = replication( $file, $info, ofile => $ofile, silent =>1 ) // [];

# is( $msg->[0], "!!! ERROR#2: EMPTY data!", "Test #12:");

$md5 = Digest::MD5->new;
for( @$msg ) {
	$md5->add($_);
}
is( $md5->hexdigest, 'b9fa29a73c2d2d23873b0cfea888476d', "Test #12: wrong ARRAY");


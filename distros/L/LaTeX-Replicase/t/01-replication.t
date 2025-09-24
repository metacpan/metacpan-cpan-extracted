# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01-replication.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 22;
use Test::More::UTF8;
use Digest::MD5;
use File::Path;

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
					3 => [1, 2], # extract from document %%%ADD1: and %%%ADD2: for 3-rd column of table
					1 => [5, 10],
				},
				2 => { # table row 2
					0 => [1, 3], # extract %%%ADD1: and %%%ADD3: for 0-th column
					1 => 2, # extract only %%%ADD2: for 1-st column
					2 => 1,
					4 => 1,
					'' => 5, # extract only %%%ADD5: located at the very "tail" of row
				},
				3 => { # table row 2
					0 => 4, # extract %%%ADD4: for 0-th column
				},
			},
			myTable_hash => {
				1 => { # table row 1
					B => 1, # extract %%%ADD1: for 'B' key (1-st column)
					A => [1, 3], # extract %%%ADD1: and %%%ADD3: for 'A' key (0-th column)
				},
				0 => { # table row 0
					B => 2, # extract %%%ADD2:
					C => [1, 2], # extract %%%ADD1: and %%%ADD2:
				},
			},

		},
	};


### Test 2
my $file = 't/template_good.tex';
my $ofile = 't/ready_good.tex';

unlink $ofile;
my $msg = replication( $file, $info, ofile => $ofile, def => 1, ignore => 1 ) // [];

is( @$msg, 0, "Test #2: '$file'");


###Test 3
open OFILE, $ofile or die "Can't open '$ofile': $!";
$msg = [];
while(<OFILE>) {
	s/\s+$//;
	push @$msg, $_;
}
close OFILE;

open TFILE, 't/template_test.tex' or die "Can't open 't/template_test.tex': $!";
my $msg_ref3 = [];
while(<TFILE>) {
	s/\s+$//;
	push @$msg_ref3, $_;
}
close TFILE;

is_deeply( $msg, $msg_ref3, "Test #3: Check '$ofile' body");

unlink $ofile;


###Test 6
my $outdir = 't/tmp';
$msg = replication( $file, $info, outdir => $outdir, def => 1, utf8 => 1, ignore => 1 ) // [];

is( @$msg, 0, "Test #6: OUTDIR");


###Test 7
open OFILE, "$outdir/template_good.tex" or die "Can't open '$outdir/template_good.tex': $!";
$msg = [];
while(<OFILE>) {
	s/\s+$//;
	push @$msg, $_;
}
close OFILE;

is_deeply( $msg, $msg_ref3, "Test #7: Check OUTDIR of '$outdir/template_good.tex' body");

unlink $ofile;


###Test 8
$msg = replication( $file, $info, ofile => $ofile, def => 1, debug => 1 ) // [];

my $md5 = Digest::MD5->new;
for( @$msg ) {
	$md5->add($_);
}
is( $md5->hexdigest, 'a51299dd3ff00321337d4728b9e5bbf9', "Test #8: DEBUG");


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
	'~~> l.12 WARNING#3: unknown tag = myTitle',
	'~~> l.24 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myAbstract',
	'~~> l.32 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myCaption',
	'~~> l.40 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myTable_array',
	'~~> l.49 WARNING#3: unknown tag = 0',
	'~~> l.54 WARNING#3: unknown tag = 1',
	'~~> l.58 WARNING#3: unknown tag = 2',
	'~~> l.63 WARNING#3: unknown tag = 3',
	'~~> l.67 WARNING#3: unknown tag = 4',
	'~~> l.80 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myTable_hash',
	'~~> l.82 WARNING#3: unknown tag = A',
	'~~> l.84 WARNING#3: unknown tag = B',
	'~~> l.86 WARNING#3: unknown tag = C',
	'~~> l.88 WARNING#3: unknown tag = D',
	'~~> l.90 WARNING#3: unknown tag = E',
	'~~> l.96 WARNING#3: unknown tag = NoNameI',
	'~~> l.99 WARNING#2: unknown SCALAR or ARRAY %%%VAR:NoNameII',
];

is_deeply( $msg, $msg_ref, "Test #5: unknown %%%VARs");


###Test 11
$file = 't/template_good.tex';
$ofile = 't/ready_good.tex';

$msg = replication( $file, $info, ofile => $ofile, def => 1, silent =>1, debug => 1 ) // [];

my $msg_ref2 = [
	"--> Check 't/template_good.tex' file",
	"--> Using 't/ready_good.tex' file as output",
	"--> Open 't/template_good.tex'",
	"--> Open 't/ready_good.tex'",
	"~~> l.12 WARNING#3: unknown tag = myTitle",
	"--> l.15 Found %%%VAR:Authors",
	"--> l.17>16 Insert SCALAR %%%VAR = Alessandro Gorohovski, Somnath Tagore, etc...",
	"~~> l.24 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myAbstract",
	"~~> l.32 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myCaption",
	"~~> l.40 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myTable_array",
	"~~> l.49 WARNING#3: unknown tag = 0",
	"~~> l.54 WARNING#3: unknown tag = 1",
	"~~> l.58 WARNING#3: unknown tag = 2",
	"~~> l.63 WARNING#3: unknown tag = 3",
	"~~> l.67 WARNING#3: unknown tag = 4",
	"~~> l.80 WARNING#2: unknown SCALAR or ARRAY %%%VAR:myTable_hash",
	"~~> l.82 WARNING#3: unknown tag = A",
	"~~> l.84 WARNING#3: unknown tag = B",
	"~~> l.86 WARNING#3: unknown tag = C",
	"~~> l.88 WARNING#3: unknown tag = D",
	"~~> l.90 WARNING#3: unknown tag = E",
	"~~> l.96 WARNING#3: unknown tag = NoNameI",
	"~~> l.99 WARNING#2: unknown SCALAR or ARRAY %%%VAR:NoNameII",
];

is_deeply( $msg, $msg_ref2, "Test #11: unknown %%%VARs with DEBUG");


###Test 9
my $newfile = "t/$$.tex";
open IFILE, $file or die $!;
open OFILE, ">$newfile" or die $!;
print OFILE <IFILE>;
close OFILE;
close IFILE;

$msg = replication( $newfile, $info, ofile => $newfile, silent =>1, debug => 0 ) // [];

unlink $newfile;

my $msg_ref9 = [
	"!!! ERROR#3: Input (template) & output files match. Can't overwrite template file!",
];

is_deeply( $msg, $msg_ref9, "Test #9: INFILE == OUTFILE");


###Test 10
$msg = replication( $file, {}, ofile => $file, silent =>1, debug => 0 ) // [];

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
			myTable_hash => [ # custom user variable ARRAY-HASH
				{A=>'00', B=>'01', C=>'02', D=>'03', E=>'04',}, # row 0
			],
		},
	};

$msg = replication( $file, $info, ofile => $ofile, silent =>1, debug => 0 ) // [];

my $msg_ref12 = [
	'~~> l.96 WARNING#3: unknown tag = NoNameI',
	'~~> l.99 WARNING#2: unknown SCALAR or ARRAY %%%VAR:NoNameII',
];

is_deeply( $msg, $msg_ref12, "Test #12: wrong ARRAY");

unlink $ofile;

###Test 13-14
my $file_s = 't/tmp/template_simple.tex';
my $ofile_s = 't/tmp/ready_simple.tex';

my $tex = q|
\begin{tabbing}
%%%VAR: myArray
   'A' %%%V: @
 \= %%%ADDX:
   'B'
 \=
   'C'
%%%END:
\end{tabbing}
|;

open F, ">$file_s" or die "Can't open '$file_s': $!";
print F $tex;
close F;

$info = {
		data => {
			myArray => [1..5],
		},
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #13: '$file_s'");

open OFILE, $ofile_s or die "Can't open '$ofile_s': $!";
$msg = [];
while(<OFILE>) {
	s/\s+$//;
	push @$msg, $_;
}
close OFILE;

my $msg_ref_s = [
'',
'\begin{tabbing}',
1,
' \=',
2,
' \=',
3,
' \=',
4,
' \=',
5,
'\end{tabbing}',
];

is_deeply( $msg, $msg_ref_s, "Test #14: ordinary ARRAY");

unlink $file_s, $ofile_s;


###Test 21-22
$tex = q|
\begin{tabbing}
%%%VAR: myArray
   'A' %%%V:0
 \= %%%ADD:
   'B' %%%V:2%
 \= %%%ADD:
   'C' %%%V:1
%%%END:
\end{tabbing}
 SPECIFY VALUE 'myArray'! %%%V: myArray
~
 SPECIFY VALUE 'myArrayArray'! %%%V: myArrayArray
~
%%%VAR: myArrayHashArray
   array A   %%%V:A%
, %%%ADD:
%%%END:
~
%%%VAR: myArrayArrayArray
   array 1   %%%V:1%
, %%%ADD:
%%%END:
|;

open F, ">$file_s" or die "Can't open '$file_s': $!";
print F $tex;
close F;

$info = {
		data => {
			myArray => [0,1,2],
			myArrayArray => [[0,3..5], 1, 2],
			myArrayHashArray => [ { A=>[0..9],},],
			myArrayArrayArray => [[undef,[1..9],],[undef,[2..9],],],
		},
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #21: '$file_s'");

open OFILE, $ofile_s or die "Can't open '$ofile_s': $!";
$msg = [];
while(<OFILE>) {
	s/\s+$//;
	push @$msg, $_;
}
close OFILE;

$msg_ref_s = [
'',
'\begin{tabbing}',
0,
' \=',
'2 \=',
1,
'\end{tabbing}',
0,
'~',
0,
'~',
'0123456789,',
'~',
'123456789,',
'23456789,',
];

is_deeply( $msg, $msg_ref_s, "Test #22: ARRAY");

unlink $file_s, $ofile_s;


###Test 15-16
$tex = q|
\begin{tabbing}
%%%VAR: myHash
   SPECIFY VALUE 'A'! %%%V: A%
 \= %%%ADD:
   SPECIFY VALUE 'B'! %%%V: B%
 \= %%%ADD:
   SPECIFY VALUE 'C'! %%%V: C%
 \= %%%ADD:
   SPECIFY VALUE 'D'! %%%V: D%
 \= %%%ADD:
   SPECIFY VALUE 'E'! %%%V: E
%%%END:
\end{tabbing}
|;

open F, ">$file_s" or die "Can't open '$file_s': $!";
print F $tex;
close F;

$info = {
		data => {
			myHash => {A=>1, B=>2, C=>3, D=>4, E=>5},
		},
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #15: '$file_s'");

open OFILE, $ofile_s or die "Can't open '$ofile_s': $!";
$msg = [];
while(<OFILE>) {
	s/\s+$//;
	push @$msg, $_;
}
close OFILE;

$msg_ref_s = [
'',
'\begin{tabbing}',
'1 \=',
'2 \=',
'3 \=',
'4 \=',
5,
'\end{tabbing}',
];

is_deeply( $msg, $msg_ref_s, "Test #16: ordinary HASH");

unlink $ofile_s;


###Test 17-18
$info = {
		data => {
			myHash => {A=>1, B=>[2,6..8], C=>3, D=>4, E=>5},
		},
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #17: '$file_s'");

open OFILE, $ofile_s or die "Can't open '$ofile_s': $!";
$msg = [];
while(<OFILE>) {
	s/\s+$//;
	push @$msg, $_;
}
close OFILE;

$msg_ref_s = [
'',
'\begin{tabbing}',
'1 \=',
' \=',
'3 \=',
'4 \=',
5,
'\end{tabbing}',
];

is_deeply( $msg, $msg_ref_s, "Test #18: mixed HASH");

unlink $file_s, $ofile_s;


###Test 19-20
$tex = q|
\mbox{
%%%VAR: ParamI%
SPECIFY VALUE ParamI !
~
~
~
%%%VAR: ParamII
SPECIFY VALUE ParamII !
~
~
%%%END:
}
|;

open F, ">$file_s" or die "Can't open '$file_s': $!";
print F $tex;
close F;

$info = {
		data => {
			ParamI => 12345,
			ParamII => 67890,
		},
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #19: '$file_s'");

open OFILE, $ofile_s or die "Can't open '$ofile_s': $!";
$msg = [];
while(<OFILE>) {
	s/\s+$//;
	push @$msg, $_;
}
close OFILE;

$msg_ref_s = [
'',
'\mbox{',
1234567890,
'}',
];

is_deeply( $msg, $msg_ref_s, "Test #20: '%%%VAR:' nested within another '%%%VAR:'");

unlink $file_s, $ofile_s;

rmtree('t/tmp');


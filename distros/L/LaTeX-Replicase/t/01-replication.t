# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01-replication.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 53;
use Test::More::UTF8;
# use Test::NoWarnings;
use Test::Exception;
use File::Path;

use Data::Dumper;

BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(:all);

##### Test replication() #####

my $info = {
		myTitle => 'ChiTaRS-${}_{3.1}$-the enhanced chimeric transcripts and RNA-seq database matched with protein-protein interactions',
		Authors => 'Alessandro Gorohovski, Somnath Tagore, etc...',
		myAbstract => 'Discovery of chimeric RNAs, which are produced by chromosomal translocations as well as 
the joining of exons from different genes by trans-splicing, has added a new level of complexity to our study and 
understanding of the transcriptome. The enhanced ChiTaRS-${}_{3.1}$ database (\url{http://chitars.md.biu.ac.il}) is designed 
to make widely accessible a wealth of mined data on chimeric RNAs, with easy-to-use analytical tools built-in.',
		myCaption => 'The major improvements and data additions in ChiTaRS-${}_{3.1}$ in comparison to ChiTaRS-${}_{2.1}$.',
		myTable_array => [ # custom user variable ARRAY-ARRAY
			['00','01','02','03','04',], # row 0
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
	};


### Test 2
my $file = 't/template_good.tex';
my $ofile = 't/ready_good.tex';

unlink $ofile;
my $msg = replication( $file, $info, ofile => $ofile, def => 1, ignore => 1 ) // [];

is( @$msg, 0, "Test #2: '$file' without errors");

sub read_file {
	my $file = shift;

	open my $fh, '<', $file or die "Can't open '$file': $!\n";

	my @msg;
	while(<$fh>) {
		s/\s+$//;
		push @msg, $_;
	}
	close $fh;

	return \@msg;
}

###Test 3
lives_ok { $msg = read_file( $ofile ) } "Test #3.1: $ofile read";

my $tfile = 't/template_test.tex';
my $msg_ref3 = [];
lives_ok { $msg_ref3 = read_file( $tfile ) } "Test #3.2: $tfile read";

is_deeply( $msg, $msg_ref3, "Test #3.3: Check body of '$ofile' vs '$tfile'");

unlink $ofile;


###Test 6
my $outdir = 't/tmp';
$msg = replication( $file, $info, outdir => $outdir, def => 1, utf8 => 1, ignore => 1 ) // [];

is( @$msg, 0, "Test #6: OUTDIR");


###Test 7
my $gfile = "$outdir/template_good.tex";
lives_ok { $msg = read_file( $gfile ) } "Test #7.1: $gfile read";

is_deeply( $msg, $msg_ref3, "Test #7.2: Check OUTDIR of '$gfile' body");

unlink $ofile;


###Test 8
$msg = replication( $file, $info, ofile => $ofile, def => 1, debug => 1 ) // [];

my $msg_ref8 = [
          '--> Checking source data: \'t/template_good.tex\'',
          '--> Using \'t/ready_good.tex\' file as output',
          '--> Open \'t/template_good.tex\'',
          '--> Open \'t/ready_good.tex\'',
          '--> l.14>12 Insert %%%V[AR]:myTitle= ChiTaRS-${}_{3.1}$-the enhanced chimeric transcripts and RNA-seq database matched with protein-protein interactions',
          '--> l.17 Found %%%VAR:Authors',
          '--> l.19>15 Insert %%%V[AR]:Authors= Alessandro Gorohovski, Somnath Tagore, etc...',
          '--> l.26 Found %%%VAR:myAbstract',
          '--> l.28>22 Insert %%%V[AR]:myAbstract= Discovery of chimeric RNAs, which are produced by chromosomal translocations as well as 
the joining of exons from different genes by trans-splicing, has added a new level of complexity to our study and 
understanding of the transcriptome. The enhanced ChiTaRS-${}_{3.1}$ database (\\url{http://chitars.md.biu.ac.il}) is designed 
to make widely accessible a wealth of mined data on chimeric RNAs, with easy-to-use analytical tools built-in.',
          '--> l.34 Found %%%VAR:myCaption',
          '--> l.36>31 Insert %%%V[AR]:myCaption= The major improvements and data additions in ChiTaRS-${}_{3.1}$ in comparison to ChiTaRS-${}_{2.1}$.',
          '--> l.42 Found %%%VAR:myTable_array',
          '--> Table row = 0',
          '-->	l.61>37 Insert head: \\rule{0mm}{1.5em}
',
          '--> l.61>38 Insert %%%V[AR]:0= 00',
          '-->	l.61>39 Insert head:  &
',
          '--> l.61>40 Insert %%%V[AR]:1= 01',
          '-->	l.61>41 Insert head:  &
',
          '--> l.61>42 Insert %%%V[AR]:2= 02',
          '-->	l.61>43 Insert head:  &
',
          '--> l.61>44 Insert %%%V[AR]:3= 03',
          '-->	l.61>45 Insert head:  &
',
          '--> l.61>46 Insert %%%V[AR]:4= 04',
          '-->	l.61>47 Insert head: ~
',
          '~~> l.61 NOT defined %%%V[AR]:',
          '--> Table row = 1',
          '-->	l.61>48 Insert head: \\\\
',
          '-->	l.61>49 Insert head: \\hline
',
          '-->	l.61>50 Insert head: \\rule{0mm}{1.5em}
',
          '--> l.61>51 Insert %%%V[AR]:0= 10',
          '-->	l.61>52 Insert head:  &
',
          '--> l.61>53 Insert %%%V[AR]:1= 11',
          '-->	l.61>54 Insert head:  &
',
          '--> l.61>55 Insert %%%V[AR]:2= 12',
          '-->	l.61>56 Insert head:  &
',
          '--> l.61>57 Insert %%%V[AR]:3= 13',
          '-->	l.61>58 Insert head:  &
',
          '--> l.61>59 Insert %%%V[AR]:4= 14',
          '-->	l.61>60 Insert head: ~
',
          '~~> l.61 NOT defined %%%V[AR]:',
          '--> Table row = 2',
          '-->	l.61>61 Insert head: \\\\
',
          '-->	l.61>62 Insert head: \\hline
',
          '-->	l.61>63 Insert head: \\rule{0mm}{1.5em}
',
          '--> l.61>64 Insert %%%V[AR]:0= 20',
          '-->	l.61>65 Insert head:  &
',
          '--> l.61>66 Insert %%%V[AR]:1= 21',
          '-->	l.61>67 Insert head:  &
',
          '--> l.61>68 Insert %%%V[AR]:2= 22',
          '~~> l.61 NOT defined %%%V:3',
          '-->	l.61>69 Insert head:  &
',
          '--> l.61>70 Insert %%%V[AR]:4= 24',
          '-->	l.61>71 Insert head: ~
',
          '~~> l.61 NOT defined %%%V[AR]:',
          '--> Table row = 3',
          '-->	l.61>72 Insert head: \\\\
',
          '-->	l.61>73 Insert head: \\hline
',
          '-->	l.61>74 Insert head: \\rule{0mm}{1.5em}
',
          '--> l.61>75 Insert %%%V[AR]:0= 30',
          '-->	l.61>76 Insert head:  &
',
          '--> l.61>77 Insert %%%V[AR]:1= 31',
          '-->	l.61>78 Insert head:  &
',
          '--> l.61>79 Insert %%%V[AR]:2= 32',
          '-->	l.61>80 Insert head:  &
',
          '--> l.61>81 Insert %%%V[AR]:3= 33',
          '-->	l.61>82 Insert head:  &
',
          '--> l.61>83 Insert %%%V[AR]:4= 34',
          '~~> l.61 NOT defined %%%V[AR]:',
          '--> l.70 Found %%%VAR:myTable_hash',
          '--> Table row = 0',
          '--> l.81>91 Insert %%%V[AR]:A= 00',
          '-->	l.81>92 Insert head:  \\=
',
          '--> l.81>93 Insert %%%V[AR]:B= 01',
          '-->	l.81>94 Insert head:  \\=
',
          '--> l.81>95 Insert %%%V[AR]:C= 02',
          '-->	l.81>96 Insert head:  \\=
',
          '--> l.81>97 Insert %%%V[AR]:D= 03',
          '-->	l.81>98 Insert head:  \\=
',
          '--> l.81>99 Insert %%%V[AR]:E= 04',
          '--> Table row = 1',
          '-->	l.81>100 Insert head: \\\\
',
          '--> l.81>101 Insert %%%V[AR]:A= 10',
          '-->	l.81>102 Insert head:  \\=
',
          '--> l.81>103 Insert %%%V[AR]:B= 11',
          '-->	l.81>104 Insert head:  \\=
',
          '--> l.81>105 Insert %%%V[AR]:C= 12',
          '-->	l.81>106 Insert head:  \\=
',
          '--> l.81>107 Insert %%%V[AR]:D= 13',
          '-->	l.81>108 Insert head:  \\=
',
          '--> l.81>109 Insert %%%V[AR]:E= 14',
          '--> Table row = 2',
          '-->	l.81>110 Insert head: \\\\
',
          '--> l.81>111 Insert %%%V[AR]:A= 20',
          '-->	l.81>112 Insert head:  \\=
',
          '--> l.81>113 Insert %%%V[AR]:B= 21',
          '-->	l.81>114 Insert head:  \\=
',
          '--> l.81>115 Insert %%%V[AR]:C= 22',
          '-->	l.81>116 Insert head:  \\=
',
          '--> l.81>117 Insert %%%V[AR]:D= 23',
          '-->	l.81>118 Insert head:  \\=
',
          '--> l.81>119 Insert %%%V[AR]:E= 24',
          '--> Table row = 3',
          '-->	l.81>120 Insert head: \\\\
',
          '--> l.81>121 Insert %%%V[AR]:A= 30',
          '-->	l.81>122 Insert head:  \\=
',
          '--> l.81>123 Insert %%%V[AR]:B= 31',
          '-->	l.81>124 Insert head:  \\=
',
          '--> l.81>125 Insert %%%V[AR]:C= 32',
          '-->	l.81>126 Insert head:  \\=
',
          '--> l.81>127 Insert %%%V[AR]:D= 33',
          '-->	l.81>128 Insert head:  \\=
',
          '--> l.81>129 Insert %%%V[AR]:E= 34',
          '~~> l.86 WARNING#3: unknown sub-key \'NoNameI\' in %%%V:NoNameI',
          '~~> l.89 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key \'NoNameII\' in %%%VAR:NoNameII'
];

is_deeply( $msg, $msg_ref8, "Test #8: DEBUG");


###Test 4
$file = 't/template_unknown.tex';
$ofile = 't/ready_unknown.tex';

$msg = replication( $file, $info, ofile => $ofile, silent =>1, debug => 0 ) // [];

is( $msg->[0],
	"!!! ERROR#1: source ('t/template_unknown.tex') does NOT exist or is EMPTY!",
	"Test #4: 't/template_unknown.tex'"
);


###Test 5
$file = 't/template_good.tex';
$ofile = 't/ready_good.tex';

$info = {
		Authors => 'Alessandro Gorohovski, Somnath Tagore, etc...',
	};

$msg = replication( $file, $info, ofile => $ofile, def => 1, silent =>1 ) // [];

my $msg_ref = [
	"~~> l.14 WARNING#3: unknown sub-key 'myTitle' in %%%V:myTitle",
	"~~> l.26 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myAbstract' in %%%VAR:myAbstract",
	"~~> l.34 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myCaption' in %%%VAR:myCaption",
	"~~> l.42 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myTable_array' in %%%VAR:myTable_array",
	"~~> l.46 WARNING#3: unknown sub-key '0' in %%%V:0",
	"~~> l.49 WARNING#3: unknown sub-key '1' in %%%V:1",
	"~~> l.52 WARNING#3: unknown sub-key '2' in %%%V:2",
	"~~> l.55 WARNING#3: unknown sub-key '3' in %%%V:3",
	"~~> l.58 WARNING#3: unknown sub-key '4' in %%%V:4",
	"~~> l.70 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myTable_hash' in %%%VAR:myTable_hash",
	"~~> l.72 WARNING#3: unknown sub-key 'A' in %%%V:A",
	"~~> l.74 WARNING#3: unknown sub-key 'B' in %%%V:B",
	"~~> l.76 WARNING#3: unknown sub-key 'C' in %%%V:C",
	"~~> l.78 WARNING#3: unknown sub-key 'D' in %%%V:D",
	"~~> l.80 WARNING#3: unknown sub-key 'E' in %%%V:E",
	"~~> l.86 WARNING#3: unknown sub-key 'NoNameI' in %%%V:NoNameI",
	"~~> l.89 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'NoNameII' in %%%VAR:NoNameII",
];

is_deeply( $msg, $msg_ref, "Test #5: unknown %%%VARs");


###Test 11
$file = 't/template_good.tex';
$ofile = 't/ready_good.tex';

$msg = replication( $file, $info, ofile => $ofile, def => 1, silent =>1, debug => 1 ) // [];

my $msg_ref2 = [
	"--> Checking source data: 't/template_good.tex'",
	"--> Using 't/ready_good.tex' file as output",
	"--> Open 't/template_good.tex'",
	"--> Open 't/ready_good.tex'",
	"~~> l.14 WARNING#3: unknown sub-key 'myTitle' in %%%V:myTitle",
	"--> l.17 Found %%%VAR:Authors",
	"--> l.19>15 Insert %%%V[AR]:Authors= Alessandro Gorohovski, Somnath Tagore, etc...",
	"~~> l.26 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myAbstract' in %%%VAR:myAbstract",
	"~~> l.34 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myCaption' in %%%VAR:myCaption",
	"~~> l.42 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myTable_array' in %%%VAR:myTable_array",
	"~~> l.46 WARNING#3: unknown sub-key '0' in %%%V:0",
	"~~> l.49 WARNING#3: unknown sub-key '1' in %%%V:1",
	"~~> l.52 WARNING#3: unknown sub-key '2' in %%%V:2",
	"~~> l.55 WARNING#3: unknown sub-key '3' in %%%V:3",
	"~~> l.58 WARNING#3: unknown sub-key '4' in %%%V:4",
	"~~> l.70 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'myTable_hash' in %%%VAR:myTable_hash",
	"~~> l.72 WARNING#3: unknown sub-key 'A' in %%%V:A",
	"~~> l.74 WARNING#3: unknown sub-key 'B' in %%%V:B",
	"~~> l.76 WARNING#3: unknown sub-key 'C' in %%%V:C",
	"~~> l.78 WARNING#3: unknown sub-key 'D' in %%%V:D",
	"~~> l.80 WARNING#3: unknown sub-key 'E' in %%%V:E",
	"~~> l.86 WARNING#3: unknown sub-key 'NoNameI' in %%%V:NoNameI",
	"~~> l.89 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'NoNameII' in %%%VAR:NoNameII",
];

is_deeply( $msg, $msg_ref2, "Test #11: unknown %%%VARs with DEBUG");


sub copy_file {
	my( $file, $newfile ) = @_;

	open IFILE, $file or die "Can't open '$file': $!\n";
	open OFILE, ">$newfile" or die "Can't open '$newfile': $!\n";

	print OFILE <IFILE>;
	close OFILE;
	close IFILE;
}

###Test 9
my $newfile = "t/$$.tex";

lives_ok { copy_file( $file, $newfile ) } "Test #9.1: copy $file to $newfile";

$msg = replication( $newfile, $info, ofile => $newfile, silent =>1, debug => 0 ) // [];

unlink $newfile;

my $msg_ref9 = [
	"!!! ERROR#3: Input (template) & output files match. Can't overwrite template file!",
];

is_deeply( $msg, $msg_ref9, "Test #9: INFILE == OUTFILE");


###Test 10
$msg = replication( $file, {}, ofile => $newfile, silent =>1, debug => 0 ) // [];

is( $msg->[0], "!!! ERROR#2: EMPTY or WRONG data!", "Test #10: EMPTY or WRONG data");

unlink $newfile;


###Test 12
$file = 't/template_good.tex';
$ofile = 't/ready_good.tex';

my $rs = 'My Title';
$info = {
		myTitle => \$rs,
		Authors => 'Alessandro Gorohovski, etc...',
		myAbstract => 'My Abstract',
		myCaption => 'My Caption',
		myTable_array => {
			0 => ['00','01','02','03','04',], # row 0
		},
		myTable_hash => [ # custom user variable ARRAY-HASH
			{A=>'00', B=>'01', C=>'02', D=>'03', E=>'04',}, # row 0
		],
	};

$msg = replication( $file, $info, ofile => $ofile, silent =>1, debug => 0 ) // [];

my $msg_ref12 = [
	"~~> l.86 WARNING#3: unknown sub-key 'NoNameI' in %%%V:NoNameI",
	"~~> l.89 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key 'NoNameII' in %%%VAR:NoNameII",
];

is_deeply( $msg, $msg_ref12, "Test #12: wrong ARRAY");

unlink $ofile;


###Test 13
my $file_s = 't/tmp/template_simple.tex';
my $ofile_s = 't/tmp/ready_simple.tex';

my $tex = q|
\begin{tabbing}
%%%VAR: myArray
%%%ADDX: \=
   'A' %%%V: @
 \=
   'B'
 \=
   'C'
%%%END:
\end{tabbing}

\begin{tabbing}
%%%VAR: myArray
%%%ADDX: \=
   'A' %%%V: -1-
 \=
   'B'
 \=
   'C'
%%%END:
\end{tabbing}

\begin{tabbing}
%%%VAR: myArray
%%%ADDX: \=
   'A' %%%V: 2,1,3-4,-,0
 \=
   'B'
 \=
   'C'
%%%END:
\end{tabbing}

\begin{tabbing}
%%%VAR: myArrayRef
%%%ADDX: \=
   'A' %%%V: 2,1,0-
 \=
   'B'
 \=
   'C'
%%%END:
\end{tabbing}
|;


sub save_file {
	my( $file, $tex ) = @_;

	open FILE, ">$file" or die "Can't open '$file': $!\n";
	print FILE $$tex;
	close FILE;
}


lives_ok { &save_file( $file_s, \$tex ) } "Test #13.1: $file_s save";

my @ell = (11, 22, 33);
$info = {
		myArray => [1..5],
		myArrayRef => \@ell,
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #13.2: '$file_s' without errors");


###Test 14
lives_ok { $msg = read_file( $ofile_s ) } "Test #14.1: $ofile_s read";

my $msg_ref_s = [
'',
'\begin{tabbing}',
1,
'\=',
2,
'\=',
3,
'\=',
4,
'\=',
5,
'\end{tabbing}',
'',
'\begin{tabbing}',
5,
'\=',
4,
'\=',
3,
'\=',
2,
'\=',
1,
'\end{tabbing}',
'',
'\begin{tabbing}',
3,
'\=',
2,
'\=',
4,
'\=',
5,
'\=',
1,
'\end{tabbing}',
'',
'\begin{tabbing}',
33,
'\=',
22,
'\=',
11,
'\=',
22,
'\=',
33,
'\end{tabbing}',
];

is_deeply( $msg, $msg_ref_s, "Test #14.2: ordinary ARRAY");

unlink $file_s, $ofile_s;


###Test 21
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
 SPECIFY VALUE 'myArray'! %%%V: myArray/0
~
 SPECIFY VALUE 'myArrayArray'! %%%V: myArrayArray/0/0
~
 SPECIFY VALUE 'myArrayHashArray'! %%%V: myArrayHashArray/0/A/5
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

lives_ok { &save_file( $file_s, \$tex ) } "Test #21.1: $file_s save";

$info = {
		myArray => [0,1,2],
		myArrayArray => [[0,3..5], 1, 2],
		myArrayHashArray => [ { A=>[0..9],},],
		myArrayArrayArray => [[undef,[1..9],],[undef,[2..9],],],
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #21.2: '$file_s' without errors");


###Test 22
lives_ok { $msg = read_file( $ofile_s ) } "Test #22.1: $ofile_s read";

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
5,
'~',
'0123456789,',
'~',
'123456789,',
'23456789,',
];

is_deeply( $msg, $msg_ref_s, "Test #22.2: ARRAY");

unlink $file_s, $ofile_s;


###Test 15
$tex = q|
%%%V: /// 	   
%%%V: /		
%%%V: /myHash
\begin{tabbing}
%%%VAR: /myHash
   SPECIFY VALUE 'A'! %%%V:A%
 \= %%%ADD:
   SPECIFY VALUE 'B'! %%%V: B%
 \= %%%ADD:
   SPECIFY VALUE 'C'! %%%V: C%
 \= %%%ADD:
   SPECIFY VALUE 'D'! %%%V:D%
 \= %%%ADD:
   SPECIFY VALUE 'E'! %%%V: E
%%%ENDZ:
\end{tabbing}

\begin{tabular}{ccccc}
 \hline
%%%VAR: /myHash
 & %%%ADDX:
 \multicolumn{1}{l}{ %%%ADD:%
   SPECIFY VALUE 'A'! %%%V:@%
} %%%ADDE:
 B 
 & %%%ADDX:
 C & D & E
%%%ENDT:
 \\\\ \hline
\end{tabular}
|;

lives_ok { &save_file( $file_s, \$tex ) } "Test #15.1: $file_s save";

my $r = 1;
$info = {
		myHash => {
			A=>\$r, B=>2, C=>3, D=>4, E=>5,
			'@' => ['C','B','D','A','E'],
		},
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #15.2: '$file_s' without errors");


###Test 16
lives_ok { $msg = read_file( $ofile_s ) } "Test #16.1: $ofile_s read";

$msg_ref_s = [
'',
'\begin{tabbing}',
'1 \=',
'2 \=',
'3 \=',
'4 \=',
5,
'\end{tabbing}',
'',
'\begin{tabular}{ccccc}',
' \hline',
' \multicolumn{1}{l}{3}',
' &',
' \multicolumn{1}{l}{2}',
' &',
' \multicolumn{1}{l}{4}',
' &',
' \multicolumn{1}{l}{1}',
' &',
' \multicolumn{1}{l}{5}',
' \\\\ \hline',
'\end{tabular}',
];

is_deeply( $msg, $msg_ref_s, "Test #16.2: ordinary HASH");

unlink $ofile_s;


###Test 17
$info = {
		myHash => {
			A=>1, B=>[2,6..8], C=>3, D=>4, E=>5,
			'@' => [undef,'E','C','A','D','B'],
		},
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( @$msg, 0, "Test #17: '$file_s'");


###Test 18
lives_ok { $msg = read_file( $ofile_s ) } "Test #18.1: $ofile_s read";

$msg_ref_s = [
'',
'\begin{tabbing}',
'1 \=',
' \=',
'3 \=',
'4 \=',
5,
'\end{tabbing}',
'',
'\begin{tabular}{ccccc}',
' \hline',
' \multicolumn{1}{l}{5}',
' &',
' \multicolumn{1}{l}{3}',
' &',
' \multicolumn{1}{l}{1}',
' &',
' \multicolumn{1}{l}{4}',
' \\\\ \hline',
'\end{tabular}',
];

is_deeply( $msg, $msg_ref_s, "Test #18.2: mixed HASH");

unlink $file_s, $ofile_s;


###Test 19
$tex = q|
\mbox{
ParamI:
%%%VAR: ParamI%
SPECIFY VALUE ParamI !
~
~
~
ParamII:
%%%VAR: ParamII
SPECIFY VALUE ParamII !
~
~ %%%ADDD:% is wrong tag!
%%%END:
~
%%%V: RefSub
~
myArray 1st:
%%%VAR: myArray
%%%ADD:%
~ %%%ADD:%
SPECIFY VALUE %%%V:-25-15
%%%END:
~
myArray 2nd:
%%%VAR: myArray
~ %%%ADD:%
SPECIFY VALUE %%%V:-5-1,-3
* %%%ADD:%
SPECIFY VALUE %%%V: k
%%%END:
~
ArrRefs:
%%%VAR: ArrRefs
( %%%ADD:%
SPECIFY VALUE %%%V:1%
) %%%ADDE:
~ %%%ADD:%
SPECIFY VALUE %%%V:@
%%%END:
~
Arr_in_Hash:
%%%VAR: Arr_in_Hash
A %%%ADD:%
SPECIFY VALUE %%%V:A%
~ %%%ADDE:
B %%%ADD:%
SPECIFY VALUE %%%V:B%
~ %%%ADDE:
C %%%ADD:%
SPECIFY VALUE %%%V:C%
~ %%%ADDE:
D %%%ADD:%
SPECIFY VALUE %%%V:D%
~ %%%ADDE:
E %%%ADD:%
SPECIFY VALUE %%%V:E%
~ %%%ADDE:
%%%VAR: Mixed
~ %%%ADD:%
SPECIFY VALUE %%%V:@
%%%END:
emptyArray:
%%%VAR: emptyArray
~ %%%ADD:%
%%%VAR: ArrayArray
aa %%%ADD:%
SPECIFY VALUE %%%V:@
%%%ENDZ:
}
|;

lives_ok { &save_file( $file_s, \$tex ) } "Test #19.1: $file_s save";

$info = {
		ParamI => 12345,
		ParamII => 67890,
		RefSub => sub{ print"Ok\n"},
		ArrRefs => [
				\$ell[2],
				\$ell[0],
				\$ell[1],
			],
		Mixed => [
				0,
				{A=>1},
				\$ell[2],
				[5..9],
			],
		myArray => [0..9],
		Arr_in_Hash => [
			{A=>1, B=>[2,6..8], C=>3, D=>4, E=>5,},
		],
		emptyArray => [],
		ArrayArray => [[0..3],[10..13]],
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // []; # debug => 0

my $msg_ref_19_2 = [
	'~~> l.16 WARNING#4: wrong type (not SCALAR|ARRAY|HASH) of \'RefSub\' in %%%V:RefSub',
	'~~> l.59 WARNING#6: mixed types (ARRAY with HASH with SCALAR or other) of %%%VAR:Mixed',
	'~~> l.61 WARNING#3: unknown sub-key \'@\' in %%%V:@',
	'~~> l.64 WARNING#7: empty ARRAY of %%%VAR:emptyArray'
];

is_deeply( $msg, $msg_ref_19_2, "Test #19.2: '$file_s'");



###Test 20
lives_ok { $msg = read_file( $ofile_s ) } "Test #20.1: $ofile_s read";

$msg_ref_s = [
'',
'\mbox{',
'ParamI:',
1234567890,
'~',
'%%%V: RefSub',
'~',
'myArray 1st:',
'~0',
'~',
'myArray 2nd:',
'~9',
'~8',
'~7',
'~6',
'~5',
'~7',
'*~',
'ArrRefs:',
'(11)',
'~33',
'~11',
'~22',
'~',
'Arr_in_Hash:',
'A1~',
'B2~',
'B6~',
'B7~',
'B8~',
'C3~',
'D4~',
'E5~',
'%%%VAR: Mixed',
'~ %%%ADD:%',
'SPECIFY VALUE %%%V:@',
'emptyArray:',
'%%%VAR: emptyArray',
'~ %%%ADD:%',
'aa0',
'aa1',
'aa2',
'aa3',
'aa10',
'aa11',
'aa12',
'aa13',
'}',
];

is_deeply( $msg, $msg_ref_s, "Test #20.2: '%%%VAR:' nested within another '%%%VAR:'");

unlink $file_s, $ofile_s;


###Test 23
$tex = q|
SPECIFY Y ELEMENT ! %%%V: /1/Y \$
~
%%%VAR: 1
~ %%%ADDA:% is wrong tag!
SPECIFY X ELEMENT of HASH ! %%%V: X
%%%END:
%%%VAR: subParam
SPECIFY ELEMENT %%%V: key
%%%END:
~
\mbox{
%%%VAR: /0/7
SPECIFY ELEMENT of ARRAY !
~
%%%ENDT:
}
|;

lives_ok { &save_file( $file_s, \$tex ) } "Test #23.1: $file_s save";

$info = [ [0..9], {Y=>'~10', X=>11, S=>sub{ $_ = 1234567890 }, }, ];

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0, esc=>'~' ) // [];

my $msg_ref_23_2 = [
	'~~> l.8 WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key \'subParam\' in %%%VAR:subParam',
	'~~> l.9 WARNING#3: unknown sub-key \'key\' in %%%V:key',
];

is_deeply( $msg, $msg_ref_23_2, "Test #23.2: wrong input info as subroutine");


###Test #24
lives_ok { $msg = read_file( $ofile_s ) } "Test #24.1: $ofile_s read";

$msg_ref_s = [
'',
'\\texttt{\\~{}}10\$',
'~',
11,
'%%%VAR: subParam',
'SPECIFY ELEMENT %%%V: key',
'~',
'\mbox{',
7,
'}',
];

is_deeply( $msg, $msg_ref_s, 'Test #24.2: ARAAY.ARRAY %%%VAR:');

unlink $ofile_s;

$msg = replication( $file_s, sub{ $_ = 1234567890 }, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( $msg->[0], '!!! ERROR#2: EMPTY or WRONG data!', 'Test #24.3: SUB %%%VAR:');

unlink $file_s, $ofile_s;

###Test #25
$msg = replication( undef, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

is( $msg->[0], '!!! ERROR#0: undefined input FILE or ARRAY!', 'Test #25: undefined input name of TeX file');

unlink $ofile_s;


###Test #26
my $tex2 = q|
%%%TDZ:  %-- beginning of The Dead Zone
\documentclass[10pt,a4paper]{article}
\usepackage[english]{babel}
\usepackage{amsmath}
\usepackage{color}
\usepackage{url}
\title{ChiTaRS-${}_{3.1}$-the enhanced chimeric transcripts and RNA-seq database etc...}
\author{Alessandro Gorohovski, etc...}
\begin{document}
\maketitle
%%%ENDZ: -- end of The Dead Zone
SPECIFY VALUE of myParam! %%%V: myParam  %-- substitutes Variable
etc...
\begin{tcolorbox}
\rule{0mm}{4.5em}%%%VAR: myParam -- substitutes Variable as well
...
... SPECIFY VALUE of myParam!
...
%%%END:
\end{tcolorbox}
\begin{tabular}{%
c
%%%VAR: myArray
l %%%ADD:%  -- column "l" type will repeat as many times as myArray size, e.g. 'lll...l'
 lllll
%%%END:
}
% head of table
Expense item &
%%%VAR: myArray
%-- eXcept 1st (0) row (record)
%%%ADDX: &
\multicolumn{1}{c}{ %%%ADD:%  -- there will be no line break
% there will be no line break also
2020 %%%V:@%
} %%%ADDE:  -- final part of '@' variables
& 2021 & 2022 & 2023 & 2024 & 2025  % All of this will be replaced until %%%END:
%%%END:
\\\\ \hline
etc...
\\\\ \hline
HASH Summary
%%%VAR: myHash
& %%%ADD:
00000 %%%V: year0
& %%%ADD:
11111 %%%V: year1
& %%%ADD:
22222 %%%V: year2%
 &  %%%ADD:%
33333 %%%V: year3
& 44444  &  55555
%%%END:
%%%VAR: myTable_array
\\\\ \hline %%%ADD:
 SPECIFY VALUE 0!  %%%V:0
&  %%%ADD:
\multicolumn{1}{c}{ %%%ADD:% -- there will be no line break
 SPECIFY VALUES from 3 to last element of array! %%%V:3-%
} %%%ADDE:
& %%%ADD:%
 SPECIFY VALUES 1 and 2 %%%V:1,2
&  22222  &  33333  & 44444  &  55555
%%%TDZ: -- beginning of The Dead Zone. Yes, you can use this instead of %%%END:
\\\\ \hline
\end{tabular}
...
\begin{tabular}{cccc}
 column2 & column1 & column0 \\\\
 \toprule
%%%ENDZ: -- end of The Dead Zone
%%%VAR: myTable_array
SPECIFY VALUE 4 %%%V: 4
 & %%%ADD:%  % add " &" without line breaks ("\n")
SPECIFY VALUES 2, 1, and 0! %%%V: -3-%
 & VALUE 1
 & VALUE 0
\\\\ %%%ADD:
\midrule %%%ADDX:
...
VALUE 4 & VALUE 2 & VALUE 1 & VALUE 0
\\\\
\midrule
...
%%%TDZ: %-- beginning of The Dead Zone.
\end{tabular}
...
\begin{tabbing}
%%%ENDZ: -- end of The Dead Zone
%%%VAR: myTable_hash
%%%ADDX: \\\\
   SPECIFY VALUE 'A'! %%%V: A%
 \= %%%ADD:%
   SPECIFY VALUE 'B'! %%%V: B%
 \= %%%ADD:%
   SPECIFY VALUE 'C'! %%%V: C
%%%ENDT: -- end of Template area (and myTable_hash also)
\end{tabbing}
etc...
\end{document}
|;

lives_ok { &save_file( $file_s, \$tex2 ) } "Test #26.1: $file_s save of USAGE";

$info = {
		myParam => 'Blah-blah blah-blah blah-blah',
		myArray => [2024, 2025, 2026, 2027],
		myHash => {year0 => 123456, year1 => 789012, year2 => 345678, year3 => 901234},
		myTable_array => [ # custom user variable ARRAY-ARRAY
			['00', '01', '02', '03', '04',], # row 0
			[10, 11, 12, 13, 14,], # row 1
			[20, 21, 22, 23, 24,], # row 2
		],
		myTable_hash => [ # custom user variable ARRAY-HASH
			{A=>'00', B=>'01', C=>'02', }, # row 0
			{A=>10, B=>11, C=>12, }, # row 1
		],
	};

$msg = replication( $file_s, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // []; # debug => 0

is( @$msg, 0, "Test #26.2: '$file_s' of USAGE");


###Test 27
lives_ok { $msg = read_file( $ofile_s ) } "Test #27.1: $ofile_s read of USAGE";

$msg_ref_s = [
'',
' %-- beginning of The Dead Zone',
'\\documentclass[10pt,a4paper]{article}',
'\\usepackage[english]{babel}',
'\\usepackage{amsmath}',
'\\usepackage{color}',
'\\usepackage{url}',
'\\title{ChiTaRS-${}_{3.1}$-the enhanced chimeric transcripts and RNA-seq database etc...}',
'\\author{Alessandro Gorohovski, etc...}',
'\\begin{document}',
'\\maketitle',
'Blah-blah blah-blah blah-blah %-- substitutes Variable',
'etc...',
'\\begin{tcolorbox}',
'\\rule{0mm}{4.5em}Blah-blah blah-blah blah-blah-- substitutes Variable as well',
'\\end{tcolorbox}',
'\\begin{tabular}{%',
'c',
'llll}',
'% head of table',
'Expense item &',
'\\multicolumn{1}{c}{2024}',
'&',
'\\multicolumn{1}{c}{2025}',
'&',
'\\multicolumn{1}{c}{2026}',
'&',
'\\multicolumn{1}{c}{2027}',
'\\\\ \\hline',
'etc...',
'\\\\ \\hline',
'HASH Summary',
'&',
'123456',
'&',
'789012',
'&',
'345678 & 901234',
'\\\\ \\hline',
'00',
'&',
'\\multicolumn{1}{c}{03}',
'&',
'\\multicolumn{1}{c}{04}',
'&01',
'&02',
'\\\\ \hline',
'10',
'&',
'\\multicolumn{1}{c}{13}',
'&',
'\\multicolumn{1}{c}{14}',
'&11',
'&12',
'\\\\ \\hline',
'20',
'&',
'\\multicolumn{1}{c}{23}',
'&',
'\\multicolumn{1}{c}{24}',
'&21',
'&22',
'\\\\ \\hline',
'\\end{tabular}',
'...',
'\\begin{tabular}{cccc}',
' column2 & column1 & column0 \\\\',
' \\toprule',
'04',
' &02 &01 &00\\\\',
'\\midrule',
'14',
' &12 &11 &10\\\\',
'\\midrule',
'24',
' &22 &21 &20\\\\',
'\\end{tabular}',
'...',
'\\begin{tabbing}',
'00 \=01 \=02',
'\\\\',
'10 \=11 \=12',
'\\end{tabbing}',
'etc...',
'\\end{document}',
];

is_deeply( $msg, $msg_ref_s, "Test #27.2: main example of USAGE");

# Clean up
unlink $file_s, $ofile_s;


###Test 28
my @tex3 = map{"$_\n"} split /\n/, $tex2;

$msg = replication( \@tex3, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];
is( @$msg, 0, "Test #28.1: ARRAY input of USAGE");

lives_ok { $msg = read_file( $ofile_s ) } "Test #28.2: $ofile_s filling ARRAY read of USAGE";

is_deeply( $msg, $msg_ref_s, "Test #28.3: main example filling ARRAY of USAGE");

unlink $ofile_s;


###Test 29
$msg = replication( {0 => "test\n"}, $info, ofile => $ofile_s, silent =>1, debug => 0 ) // [];

$msg_ref = [
	"!!! ERROR#6: invalid FILE or ARRAY input!",
];

is_deeply( $msg, $msg_ref, "Test #29: HASH input of USAGE");

unlink $ofile_s;


###Test 30

# my $msg_ref_out = join("\n", map{s/\s+$//;$_} @$msg_ref_s ) . "\n";
# use Test::Output;
# stdout_is {replication( \@tex3, $info, ofile => *STDOUT, silent =>1, debug => 0 )} $msg_ref_out, "Test #30: STDOUT filling ARRAY";

my $old_stdout;
lives_ok {
	open $old_stdout, '>&', STDOUT or die "Can't dup STDOUT: $!";
	open STDOUT, '>', $ofile_s or die "Can't redirect STDOUT: $!";
} "Test #30.1: Redirect STDOUT to a temporary file";

$msg = replication( \@tex3, $info, ofile => *STDOUT, silent =>1, debug => 0 ) // [];

lives_ok {
	close STDOUT;
	open STDOUT, '>&', $old_stdout or die "Can't restore STDOUT: $!";
} "Test #30.2: Restore original STDOUT";

# Read contents of temporary file
lives_ok { $msg = read_file( $ofile_s ) } "Test #30.3: $ofile_s read";

# Test the content
is_deeply( $msg, $msg_ref_s, "Test #30.4: STDOUT content was captured correctly");

unlink $ofile_s;


rmtree('t/tmp');

###DEL###
# open F, ">test.log";
# print F Dumper($msg);
# close F;
# exit;

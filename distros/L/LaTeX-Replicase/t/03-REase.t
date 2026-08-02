# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01-replication.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 33;
use Test::More::UTF8;

BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(:all);

##### Test REase() #####

### Test 2-8
my $t = 2;
my @arr = (
	['1-2','1-2'], # 2
	['1--2', '1--2'], # 3
	['1---2', '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2'], # 4
	['1----2', '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}-{\hskip0pt plus .02em}2'], # 5
	['1-----2', '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}--{\hskip0pt plus .02em}2'], # 6
	['1------2', '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2'], # 7
	['1-------2', '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}---{\hskip0pt plus .02em}-{\hskip0pt plus .02em}2'], # 8
);
my $r_mflag = [0,0, (0b0111)x5];

my $i = 0;
for( @arr ) {
	my( $v, $r ) = @$_;
	$_ = $v;
	my $mflag = REase($_); # by default, tail = 3
	is_deeply( [$_, $mflag], [ $r, $r_mflag->[$i]], 'Test #'.$t. ": '$v' to '$r' with tail = 3");
	++$t;
	++$i;
}

###Test 9-11
for my $v ( undef, 0, '') { # 9,10,11
	my $mflag = REase($v);
	is_deeply( [$v, $mflag], [$v, 0], 'Test #'. $t .': check value -> '. ($v // "'undef'") .' unchanged, with check mflag -> '. $mflag);
	++$t;
}

###Test 12-20
my $v = '~$&,%,$,#,_,{,},^,\2qw\ea-sdf-124-590\\\\\\>>>>---1';
my $r = [
	#12: tail = 2
'{\hskip0pt plus .02em}~$&'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}%,$'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}#,_'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}{,}'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}^,\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}5'.
'{\hskip0pt plus .02em}90\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#13: tail = 3
'{\hskip0pt plus .02em}~$&,'.
'{\hskip0pt plus .02em}%'.
'{\hskip0pt plus .02em},$,#'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}_,{,'.
'{\hskip0pt plus .02em}}'.
'{\hskip0pt plus .02em},^,\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}5'.
'{\hskip0pt plus .02em}9'.
'{\hskip0pt plus .02em}0\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#14: tail = 4
'{\hskip0pt plus .02em}~$&,%'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}$,#,_'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}{,},^'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}59'.
'{\hskip0pt plus .02em}0'.
'{\hskip0pt plus .02em}\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#15: tail = 5
'{\hskip0pt plus .02em}~$&,%,'.
'{\hskip0pt plus .02em}$'.
'{\hskip0pt plus .02em},#,_,{'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}},^'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}59'.
'{\hskip0pt plus .02em}0'.
'{\hskip0pt plus .02em}\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#16: tail = 6
'{\hskip0pt plus .02em}~$&,%,$'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}#,_,{,}'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}^,\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}59'.
'{\hskip0pt plus .02em}0'.
'{\hskip0pt plus .02em}\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#17: tail = 7
'{\hskip0pt plus .02em}~$&,%,$,'.
'{\hskip0pt plus .02em}#'.
'{\hskip0pt plus .02em},_,{,},^'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}59'.
'{\hskip0pt plus .02em}0'.
'{\hskip0pt plus .02em}\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#18: tail = 8
'{\hskip0pt plus .02em}~$&,%,$,#'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}_,{,},^'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}59'.
'{\hskip0pt plus .02em}0'.
'{\hskip0pt plus .02em}\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#19: tail = 9
'{\hskip0pt plus .02em}~$&,%,$,#'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}_,{,},^'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}59'.
'{\hskip0pt plus .02em}0'.
'{\hskip0pt plus .02em}\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

	#20: tail = 'X' -- INVALID value
'{\hskip0pt plus .02em}~$&,'.
'{\hskip0pt plus .02em}%'.
'{\hskip0pt plus .02em},$,#'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}_,{,'.
'{\hskip0pt plus .02em}}'.
'{\hskip0pt plus .02em},^,\2'.
'{\hskip0pt plus .02em}qw\ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}5'.
'{\hskip0pt plus .02em}9'.
'{\hskip0pt plus .02em}0\\\\\\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1',

];

$i = 0;
for my $tile (2..9, 'X'){ #12 -- #20
	$_ = $v;
	my $mflag = REase( $_, { tile => $tile } );
	is_deeply( [$_, $mflag], [$r->[$i], 0b0111 ], 'Test #'.$t. ": '$v' to '$r->[$i]' with tail = $tile");
	++$t;
	++$i
}

###Test #21
$r = $v = 'q we rtyuiopasdfghjklzxcvbnm yuiopasdfg yuiopasdfghjklzxc\relax'."\t\t\t";
my $mflag = REase($v);
is_deeply( [$v, $mflag], [$r, 0 ], 'Test #'.$t. ": '$v' without changing the value");
++$t;


###Test #22
$v = $_ = '\~{}\$\&,\%,\$,\#,\_,\{,\},\^{},\char92{}2qw\char92{}ea"=sdf-124-590\char92{}\char92{}\char92{}>>>>---1';
$r = '{\hskip0pt plus .02em}\~'.
'{\hskip0pt plus .02em}\$\&'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\%,\$'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\#,\_'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\{,\}'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\^'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\char92'.
'{\hskip0pt plus .02em}2'.
'{\hskip0pt plus .02em}qw\char92'.
'{\hskip0pt plus .02em}ea"=sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}5'.
'{\hskip0pt plus .02em}9'.
'{\hskip0pt plus .02em}0\char92'.
'{\hskip0pt plus .02em}\char92'.
'{\hskip0pt plus .02em}\char92'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1';

$mflag = REase($_);
is_deeply( [$_, $mflag], [$r, 0b0111 ], 'Test #'.$t. ": '$v' to '$r' after sub 'tex_escape'");
++$t;


###Test #23
$v = $_= q({{{124244234}}sdsdfdsfsdf{}{});
$r = '{\hskip0pt plus .02em}{{{1{\hskip0pt plus .02em}2'.
'{\hskip0pt plus .02em}4244'.
'{\hskip0pt plus .02em}2'.
'{\hskip0pt plus .02em}34}'.
'{\hskip0pt plus .02em}}'.
'{\hskip0pt plus .02em}sdsdfdsfsdf';

$mflag = REase($_);
is_deeply( [$_, $mflag], [$r, 0b0111 ], 'Test #'.$t. ": '$v' to '$r' nested parentheses");
++$t;

###Test #24
$v = $_= q(   \{\{\{124244234\}\}sdsdfdsfsdf\{\}\{\}\{\}\relax)."\t\t\t";
$r = '{\hskip0pt plus .02em} \{\{\{1'.
'{\hskip0pt plus .02em}2424'.
'{\hskip0pt plus .02em}4'.
'{\hskip0pt plus .02em}234\}\}sdsdfdsfsdf\{\}\{\}\{\}\relax'."\t\t\t";

$mflag = REase($_);
is_deeply( [$_, $mflag], [$r, 0b0111 ], 'Test #'.$t. ": '$v' to '$r with \\relax<tab><tab><tab>");
++$t;

###Test #25
$r = $v = $_= q(   \{\{\{124244234\}\}sdsdfdsfsdf\{\}\{\}\{\}\relax\\/);
$mflag = REase($_);
is_deeply( [$_, $mflag], [$r, 0], 'Test #'.$t. ": SKIPP '$v' with \\relax\\/");
++$t;

###Test #26
$r = $v = $_= '~!#$';
$mflag = REase($_);
is_deeply( [$_, $mflag], [$r, 0 ], 'Test #'.$t. ": '$v' to '$r'");
++$t;

###Test #27
REase($_);
is( $_, $r, 'Test #'.$t. ": '$v' to '$r' without check output 'mflag'");
++$t;

###Test #28
$mflag = REase($_, [0..3]);
is_deeply( [$_, $mflag], [$r, 0 ], 'Test #'.$t. ": '$v' to '$r' with IGNORE option -- ARRAY");
++$t;

###Test #29
my $op = { _MFLAGS_ => 0b0111 };
$v = $_= '1---2';
$r = $v;
$mflag = REase( $_, $op );
is_deeply( [$_, $mflag], [$r, 0], 'Test #'.$t. ": '$v' to '$r' with option '_MFLAGS_' => $op->{_MFLAGS_}");
++$t;

###Test #30
$op = [ 0..3 ];
$v = $_= '1---2';
$r = '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2';
$mflag = REase( $_, $op );
is_deeply( [$_, $mflag], [$r, 0b0111], 'Test #'.$t. ": '$v' to '$r' with INVALID option => 'ARRAY'");
++$t;

###Test #31
$op = '!stag';
$v = $_= '%%%:1---2';
$r = '%%%:{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2';
$mflag = REase( $_, $op );
is_deeply( [$_, $mflag], [$r, 0b0111], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #32
$_ = $v;
REase( $_, $op );
is( $_, $r, 'Test #'.$t. ": '$v' to '$r' with option '$op', and without check return 'mflag'");
++$t;

###Test #33
$r = $v = $_= '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2';
$mflag = REase( $_ );
is_deeply( [$_, $mflag], [$r, 0], 'Test #'.$t. ": '$v' to '$r'");
++$t;



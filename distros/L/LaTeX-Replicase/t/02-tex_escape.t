# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01-replication.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 69;
use Test::More::UTF8;
# use Test::NoWarnings;

BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(:all);

##### Test tex_escape() #####

### Test #2-10
my $t = 2;
my @arr = (
	['&','\&'], # 2
	['%','\%'], # 3
	['$','\$'], # 4
	['#','\#'], # 5
	['_','\_'], # 6
	['{','\{'], # 7
	['}','\}'], # 8
	['^','\^\\/'], # 9
	['\\','\char92\\/'], # 10
);

for( @arr ) {
	my( $v, $r ) = @$_;
	my $mflag = tex_escape($v);

	is_deeply( [$v, $mflag], [$r, 0b0010], 'Test #'. $t .": '$_->[0]' to '$r'");
	++$t;
}

###Test #11
$_ = '~';
tex_escape( $_, '~');
is( $_, '\~\\/', "Test #11: '~'");

###Test #12
my $r = $_ = 'qwertyuiopasdfghjklzxcvbnm1234567890';
my $mflag = tex_escape($_);
is_deeply( [$_, $mflag], [$r, 0], 'Test #12: without changing the value');

###Test 13
$_ = '%%%:~\frac{12345}{67890}';
$mflag = tex_escape($_);
is_deeply( [$_, $mflag], ['~\frac{12345}{67890}', 1], "Test #13: '%%%:'");

###Test #14
$t = 14;
my $v = $_ = '%%%:~\frac{12345}{67890}';
$r = '%%%:~\frac{12345}{67890}';
my $op = '~ +stag';
$mflag = tex_escape( $_, $op);
is_deeply( [$_, $mflag], [$r, 0], 'Test #'.$t. ": '$v' to '$r' with BAD option '$op'");

###Test #15
$t = 15;
undef $_;
$mflag = tex_escape($_);
is_deeply( [$_, $mflag], [undef, 0], 'Test #'.$t. ': checking a undef value');

###Test #16
++$t;
$v = '~\frac{12345}{67890}';
$r = '~\char92\\/frac\{12345\}\{67890\}';
$mflag = tex_escape($v, []);
is_deeply( [$v, $mflag], [$r, 2], 'Test #'.$t. ': checking BAD option is ARRAY');

###Test #17-18
$v = '123~456';
$r = '123\~\\/456';
++$t;
@arr = (
	['~', $r], # 17
	[$v, $r], # 18
);

for( @arr ) {
	my $s = $v;
	my( $op, $r ) = @$_;
	tex_escape( $s, $op );
	is( $s, $r, 'Test #'.$t. ": '$v' to '$r' with option = '$op'");
	++$t;
}

###Test #19-24
$r = $v = '%%%:~\frac{12345}{67890}';
for my $op ('~_+stag', '~ +stag', '~,+stag', '+stag', '+stag~','+stag_'){
	$_ = $v;
	my $mflag = tex_escape($_, $op );
	is_deeply( [$_, $mflag], [$r, 0], 'Test #'.$t. ": '$v' with option '$op' -- save '%%%:'");
	++$t;
}

###Test #25-30
$v = '%%%:%%';
$r = '\%\%\%:\%\%';
for my $op ('~_!stag', '~ !stag', '~,!stag', '!stag', '!stag~', '!stag_'){
	$_ = $v;
	my $mflag = tex_escape( $_, $op );
	is_deeply( $_, $r, 'Test #'.$t. ": '$v' with option '$op'");
	++$t;
}


###Test #31
$r = $_ = 'qw~e/sds|dg';
$mflag = tex_escape($_);
is_deeply( [$_, $mflag], [$r, 0], 'Test #'. $t .': without changing the value');
++$t;


###Test #32
$v = $_ = 'qw~e/sds|dg';
$r = 'qw\~\\/e/sds|dg';
$op = '~';
$mflag = tex_escape($_, $op);
is_deeply( [$_, $mflag], [$r, 0b0010], 'Test #'. $t .": '$v' to '$r' with option ''");
++$t;


###Test #33-36
$_ = '~qwertyuiopasdfghjklzxcvbnm1234567890~';
$r = '\~\\/qwertyuiopasdfghjklzxcvbnm1234567890\~\\/';
my $r_mflag = [0b0010, 0, 0, 0];

for my $i (0..3) {
	$v = $_;
	my $mflag = tex_escape($_, { _MFLAGS_ => $i, esc => '~',} );
	is_deeply( [$_, $mflag], [$r, $r_mflag->[$i] ], 'Test #'. $t .": '$v' to '$r' with _MFLAG = $i");
	++$t;
}


###Test #37-42
$v = '~-qwertyuiopa-sdfghjklzx-cvbnm-1234-567890~-';
$r = [('\~\\/-qwertyuiopa"=sdfghjklzx"=cvbnm-1234-567890\~\\/-') x 4, ('~-qwertyuiopa"=sdfghjklzx"=cvbnm-1234-567890~-') x 2];

my $i = 0;
for my $op ('~ hyphen', '~_hyphen', '~,hyphen', 'hyphen~', 'hyphen', 'hyphen_'){
	$_ = $v;
	my $mflag = tex_escape( $_, $op );
	is_deeply( [$_, $mflag], [ $r->[$i], 0b0010 ], 'Test #'.$t. ": '$v' to '$r->[$i]' with option '$op'");
	++$t;
	++$i
}

###Test #43
$r = $v = $_ = '~-1234-567890~';
$op = 'hyphen';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #44
$v = $_ = '~$&,%,$,#,_,{,},^,\2qw\ea-sdf-124-590\\\\\\>>>>---1\relax'."\t\t\t";
$r = '\~\\/\$\&,\%,\$,\#,\_,\{,\},\^\\/,\char92\\/2qw\char92\\/ea"=sdf-124-590\char92\char92\\>>>>---1\relax'."\t\t\t";
$op = '~ hyphen';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0010], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #45
$v = $_ = '~$&,%,$,#,_,{,},^,\2qw\ea-sdf-124-590\\\\\\>>>>---1\relax\\/';
$r = '\~\\/\$\&,\%,\$,\#,\_,\{,\},\^\\/,\char92\\/2qw\char92\\/ea"=sdf-124-590\char92\char92\>>>>---1\relax\\/';
$op = '~ hyphen,REase';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0010], 'Test #'.$t. ": '$v' to '$r' with option '$op' and end tag '\\relax\\/' for REase");
++$t;

###Test #46
$v = $_ = '1---2';
$r = '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2';
$op = 'REase';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0111], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;


###Test #47
$v = $_ = '%%%:1---2';
$r = '{\hskip0pt plus .02em}\%\%\%{\hskip0pt plus .02em}:{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2';
$op = '!stag REase';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0111], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;


###Test #48
$v = $_ = '%%%:%%%:1---2';
$r = '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2';
$op = '-stag +stag REase';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0111], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #49
$_ = $v;
$r = '%%%:1---2';
$op = '+stag REase';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0001], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #50
$_ = $v;
$r = '1---2';
$op = 'REase';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0001], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;


### Test #51-60
@arr = (
	['\&','\&', 0], # 51
	['\%','\%', 0], # 52
	['\$','\$', 0], # 53
	['\#','\#', 0], # 54
	['\_','\_', 0], # 55
	['\{','\{', 0], # 56
	['\}','\}', 0], # 57
	['\^','\^', 0], # 58
	['\\\\','\char92\char92\\/', 0b0010], # 59
	['\\)\\(','\char92)\char92(', 0b0010], # 60
);

for( @arr ) {
	my( $v, $r, $r_mflag ) = @$_;
	my $mflag = tex_escape($v);

	is_deeply( [$v, $mflag], [$r, $r_mflag], 'Test #'. $t .": '$_->[0]' to '$r'");
	++$t;
}

###Test #61
$op = '~ REase hyphen';
$v = $_ = '~$&,%,$,#,_,{,},^,\2qw\ea-sdf-124-590\\\\\\>>>>---1';

$r = '{\hskip0pt plus .02em}\~\\/\$\&'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\%,\$'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\#,\_'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\{,\}'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\^\\/'.
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
'{\hskip0pt plus .02em}0\char92\char92\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1';

$mflag = tex_escape( $_, $op ); # by default, tail = 3
is_deeply( [$_, $mflag], [ $r, 0b0111], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #62
$op = { esc => 'REase', tile => 5 };
$_ = $v;

$r = '{\hskip0pt plus .02em}~\$\&'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\%,\$'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\#,\_'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\{,\}'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\^\\/'.
'{\hskip0pt plus .02em},'.
'{\hskip0pt plus .02em}\char92'.
'{\hskip0pt plus .02em}2'.
'{\hskip0pt plus .02em}qw\char92'.
'{\hskip0pt plus .02em}ea'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}sdf'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}1'.
'{\hskip0pt plus .02em}24'.
'{\hskip0pt plus .02em}-'.
'{\hskip0pt plus .02em}59'.
'{\hskip0pt plus .02em}0'.
'{\hskip0pt plus .02em}\char92'.
'{\hskip0pt plus .02em}\char92'.
'{\hskip0pt plus .02em}\>>'.
'{\hskip0pt plus .02em}>>'.
'{\hskip0pt plus .02em}---'.
'{\hskip0pt plus .02em}1';

$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [$r, 0b0111 ], 'Test #'.$t. ": '$v' to '$r' with options esc = '$op->{esc}', tile = '$op->{tile}'");
++$t;

###Test #63
$op = { _MFLAGS_ => 0b0111 };
$v = $_;

$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [$r, 0 ], 'Test #'.$t. ": '$v' to '$r' with options _MFLAGS_ = '$op->{_MFLAGS_}'");
++$t;


###Test #64
$v = $_ = '%%%:%%%:%%%:%%%:%%%:1---2';
$r = '{\hskip0pt plus .02em}1{\hskip0pt plus .02em}---{\hskip0pt plus .02em}2';
$op = '-stag REase';
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0111], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;


###Test #65
$op = '~';
$v = $_ = q{\	,\ ,\$,\%,\&,\},\{,\-,\*,\/,\=,\.,\_,\^,\~,\#,\\',\`,\",\,,\;,\!,\>,\textbackslash,\hskip 0pt,\relax,\\\\\command}; # active symbols allowed in LaTeX
$r = q{\	,\char92 ,\$,\%,\&,\},\{,\-,\*,\/,\=,\.,\_,\^,\~,\#,\\',\`,\",\,,\;,\!,\>,\textbackslash,\hskip 0pt,\relax,\char92\char92\char92\\/command};
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0010], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #66
$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #67
tex_escape( $_, $op );
is( $_, $r, 'Test #'.$t. ": '$v' to '$r' with option '$op' without check output 'mflag'");
++$t;


###Test #68
$op = '~ mutual';
$v = $_ = q(\	,\ ,\$,\%,\&,\},\{,\-,\*,\/,\=,\.,\_,\^,\~,\#,\\',\`,\",\,,\;,\!,\>,\textbackslash,\hskip 0pt,\relax,\\\\\command);
$r = q(\	,\char92 ,\$,\%,\&,\},\{,\-,\*,\/,\=,\.,\_,\^,\~,\#,\\',\`,\",\char92,,\char92;,\char92!,\char92>,\textbackslash,\hskip 0pt,\relax,\char92\char92\char92\\/command);

$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0010], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;

###Test #69
$op = '~ mutual strong';
$v = $_ = q(\	,\ ,\$,\%,\&,\},\{,\-,\*,\/,\=,\.,\_,\^,\~,\#,\\',\`,\",\,,\;,\!,\>,\textbackslash,\hskip 0pt,\relax,\\\\\command);
$r = q(\char92	,\char92 ,\char92\$,\char92\%,\char92\&,\char92\},\char92\{,\char92-,\char92*,\char92/,).
q(\char92=,\char92.,\char92\_,\char92\^\/,\char92\~\/,\char92\#,\char92',\char92`,\char92",\char92,,).
q(\char92;,\char92!,\char92>,\textbackslash,\hskip 0pt,\relax,\char92\char92\char92\/command);

$mflag = tex_escape( $_, $op );
is_deeply( [$_, $mflag], [ $r, 0b0010], 'Test #'.$t. ": '$v' to '$r' with option '$op'");
++$t;


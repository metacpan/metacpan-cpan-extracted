# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 06-onecell.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 54;
use Test::More::UTF8;
use Test::Exception;
use Test::Warn;
use Storable qw(nstore retrieve);
use Data::Dumper;
use Text::Hyphen;
use Text::Hyphen::RU;

BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(font_metrics onecell); # :all

##### Test unicellular() #####

### Test 2
my $AFMfile = 't/PTC55F.afm';
my $glyphlist = 't/glyphlist.txt';
my $op = { glyphlist =>$glyphlist, noBbox =>1 }; #, noBbox =>1, noKPX =>1, mate =>'glyph'|'symbol'|'hex'

my $font_metrics;

my $msg = 'Undefined glyph:';
my $msgs = [
	qr/$msg 'afii10055.alt'/,
	qr/$msg 'afii10103.alt'/,
	qr/$msg 'caron.l'/,
	qr/$msg 'fraction.alt'/,
	qr/$msg 'l.var'/,
	qr/$msg 'one.numerator'/,
];

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Test #2: Checked carp warning';


my $mm2pt = 2.845276; # 1mm ~= 2.845276pt

my $cell_width = 30; #20; # (mm)
$cell_width *= $mm2pt; # (pt)

my $hyp_en = new Text::Hyphen( min_word =>4);
my $hyp_ru = new Text::Hyphen::RU( min_word =>4);

$op = {
	cell_width => $cell_width, # width of cell/box, (pt)
	font_metrics => $font_metrics, # table of font metrics for decimal Unicode number
#	font_metrics => font_metrics('PTC55F.afm', { glyphlist => 'glyphlist.txt', noBbox =>1 }),
	base_font_size => 10, # depending on the document's base font size (pt), see \documentclass[...pt]
#	font_size => 'normalsize', # TeX-font size of text in cell/box, e.g. 'small', 'normalsize', 'large', etc.
	space => 2.43, # Regular space between words (pt), see fontdimen 2
	shrink => 0.81, # whitespace shrink (pt), see fontdimen 4
	# merge => 1,
	# offset => 0,
	# limit => 25,
	# hyphenation => [],
};

my $string = "I was going to do something today but I haven't finished doing nothing from yesterday.
Я собирался кое-что сделать сегодня, но еще не закончил ничегонеделание со вчерашнего дня    ";

### Test 4.1
my $cell = [];

warnings_are {
	( $cell ) = onecell( $string, $op );
} [], 'Checked carp warning for Test #4.1';

my $cell_ref = {
	'lines' => [ # arrays of no empty lines
                       'I was going to do ', #0
                       'something today ', #1
                       'but I haven\'t finis\\-',
                       'hed doing nothin\\-',
                       'g from yesterday. ',
                       "\x{42f} \x{441}\x{43e}\x{431}\x{438}\x{440}\x{430}\x{43b}\x{441}\x{44f} \x{43a}\x{43e}\x{435}-{\\hskip0pt plus .02em}",
                       "\x{447}\x{442}\x{43e} \x{441}\x{434}\x{435}\x{43b}\x{430}\x{442}\x{44c} \x{441}\x{435}\x{433}\x{43e}\\-",
                       "\x{434}\x{43d}\x{44f}, \x{43d}\x{43e} \x{435}\x{449}\x{435} \x{43d}\x{435} \x{437}\x{430}\\-",
                       "\x{43a}\x{43e}\x{43d}\x{447}\x{438}\x{43b} \x{43d}\x{438}\x{447}\x{435}\x{433}\x{43e}\x{43d}\x{435}\\-",
                       "\x{434}\x{435}\x{43b}\x{430}\x{43d}\x{438}\x{435} \x{441}\x{43e} \x{432}\x{447}\x{435}\x{440}\\-",
                       "\x{430}\x{448}\x{43d}\x{435}\x{433}\x{43e} \x{434}\x{43d}\x{44f}"
                     ],
	'stop' => 176, # position in $string where the extraction of symbols into cell stopped
	'wxL' => [ # arrays of line widths (*100pt) for 'lines'
                     8257, #0  Ok: 398 +(space=243-81)=162 +840 +582 +499 +(space)=162 +627 +631 +317 +641 +627 +(space)=162 +405+631-11 +(space)=162 +629 +631 +(space)=162
                     8398, #1  Ok: 499 +631 +948 +598 +405 +641 +317 +641 +627 +(space)=162 +405+631-11 +629 +582 +531+(space)=162 -36?
                     8346,
                     8313,
                     8344,
                     8413,
                     7964,
                     8342,
                     8432,
                     8053,
                     5684
                   ],
	'numL' => 11 # number of no empty lines
};

is_deeply( $cell, $cell_ref, "Test #4.1: 'onecell()' without 'hyphenation' option");

$op->{hyphenation} = 'Blah-Blah';
( $cell ) = onecell( $string, $op );

is_deeply( $cell, $cell_ref, "Test #4.4: 'onecell()' with BAD 'hyphenation' option");

$op->{hyphenation} = [];
( $cell ) = onecell( $string, $op );

is_deeply( $cell, $cell_ref, "Test #4.5: 'onecell()' with EMPTY ARRAY of 'hyphenation' option");

###DEL###
# open F, ">test.log";
# print F Dumper($cell);
# close F;
# exit;


$op->{hyphenation} = [
		{ name =>'en', action => $hyp_en, }, # English
	# OR
	# { msk => qr/[a-zA-Z]+/o, action => $hyp_en, },
#		{ name =>'ru', action => $hyp_ru, }, # Russian
	# OR
		{ msk => qr/[а-яА-Я]+/o, action => $hyp_ru, },
		{ name =>'Blah', action => $hyp_en, },
	];

my $nLines;
warnings_are {
	$nLines = onecell( $string, $op );
} [], 'Checked carp warning for Test #3';

is( $nLines, 12, "Test #4.2: 'onecell()' returns SCALAR number of lines");
undef $nLines;


### Test 4.2

warnings_are {
	( $cell ) = onecell( $string, $op );
} [], 'Checked carp warning for Test #4.3';

$cell_ref = {
	'lines' => [ # arrays of no empty lines
                       'I was going to do ', #0
                       'something today ', #1
                       'but I haven\'t fin\\-', #2
                       'ished doing noth\\-', #3
                       'ing from yes\\-ter\\-', #4
                       'day. Я собирался ', #5
                       'кое-что сделать ', #6
                       'сегодня, но еще ', #7
                       'не закончил ни\\-', #8
                       'че\\-го\\-не\\-де\\-ла\\-ние ', #9
                       'со вчерашнего ', #10
                       'дня' #11
                     ],
	'stop' => 176, # position in $string where the extraction of symbols into cell stopped
	'wxL' => [ # arrays of line widths (*100pt) for 'lines'
                     8257, #0  Ok: 398 +(space=243-81)=162 +840 +582 +499 +(space)=162 +627 +631 +317 +641 +627 +(space)=162 +405+631-11 +(space)=162 +629 +631 +(space)=162
                     8398, #1  Ok: 499 +631 +948 +598 +405 +641 +317 +641 +627 +(space)=162 +405+631-11 +629 +582 +531+(space)=162 -36?
                     7530, #2
                     8171, #3
                     7232, #4  Ok: 317 +641 +627 +162 +364 +380 +631 +948 +162 +531 +598 +499 +('\-')=0 +405+598-11 +380 +('\-')=0
                     8324, #5  Ok: 629 +582 +531+(period)238-72 +(space)=162 -30? +(Я=afii10049)=624 +(space)=162 +(с=afii10083)=529+(о=afii10080)=631-23 +(б=afii10066)=635 +(и=afii10074)=631 +(р=afii10082)=630 +(а=afii10065)=582 +(л=afii10077)=584 +(с=afii10083)=529 +(я=afii10097)=578 +(space)=162
                     7989, #6 
                     8000, #7 
                     7479, #8 
                     7794, #9  
                     7546, #10 Ok: +(с=afii10083)=529+(о=afii10080)=631-23 +(space)=162 +(в=afii10067)=582 +(ч=afii10089)=574 +(е=afii10070)=598 +(р=afii10082)=630 +(а=afii10065)=582 +(ш=afii10090)=856 +(н=afii10079)=624 +(е=afii10070)=598 +(г=afii10068)=426 +(о=afii10080)=631 +(space)=162
                     1826  #11 Ok: +(д=afii10069)=624 +(н=afii10079)=624 +(я=afii10097)=578
                   ],
	'numL' => 12 # number of no empty lines
};

is_deeply( $cell, $cell_ref, "Test #4.3: 'onecell()' returns HASH.ARRAYS");


### Test 3 ???


### Test 5
$op->{merge} = 1;
$op->{offset} = 0;
$op->{limit} = 0;
$op->{font_size} = 'normalsize';
delete $op->{base_font_size};

warnings_are {
	( $cell ) = onecell( $string, $op );
} [], 'Checked carp warning for Test #5';

my $cell_ref5 = {
	'wxL' => [ 88546 ],
	'lines' => ["I was going to do something today but I haven't fin\\-ished doing noth\\-ing from yes\\-ter\\-day. Я собирался кое-что сделать сегодня, но еще не закончил ни\\-че\\-го\\-не\\-де\\-ла\\-ние со вчерашнего дня"],
	'numL' => 12,
	'stop' => 176
};

is_deeply( $cell, $cell_ref5, "Test #5: 'onecell()' with 'merge' option");


### Test 16
delete $op->{merge};
$op->{limit} = 20;

$cell_ref->{stop} = -1;

warnings_are {
	( $cell ) = onecell( $string, $op );
} [], 'Checked carp warning for Test #16.1';

is_deeply( $cell, $cell_ref, "Test #16.1: 'onecell()' with option 'limit'(20) > MAX line (12)");

$op->{limit} = 6;
( $cell ) = onecell( $string, $op );

my $cell_ref16 = {
	'lines' => [ # arrays of no empty lines
                       'I was going to do ', #0
                       'something today ', #1
                       'but I haven\'t fin\\-', #2
                       'ished doing noth\\-', #3
                       'ing from yes\\-ter\\-', #4
                       'day. Я собирался', #5
                     ],
	'wxL' => [ # arrays of line widths (*100pt) for 'lines'
                     8257, #0  Ok: 398 +(space=243-81)=162 +840 +582 +499 +(space)=162 +627 +631 +317 +641 +627 +(space)=162 +405+631-11 +(space)=162 +629 +631 +(space)=162
                     8398, #1  Ok: 499 +631 +948 +598 +405 +641 +317 +641 +627 +(space)=162 +405+631-11 +629 +582 +531+(space)=162 -36?
                     7530, #2
                     8171, #3
                     7232, #4  Ok: 317 +641 +627 +162 +364 +380 +631 +948 +162 +531 +598 +499 +('\-')=0 +405+598-11 +380 +('\-')=0
                     8162, #5  Ok: 629 +582 +531+(period)238-72 +(space)=162 -30? +(Я=afii10049)=624 +(space)=162 +(с=afii10083)=529+(о=afii10080)=631-23 +(б=afii10066)=635 +(и=afii10074)=631 +(р=afii10082)=630 +(а=afii10065)=582 +(л=afii10077)=584 +(с=afii10083)=529 +(я=afii10097)=578
                   ],
	'stop' => 99,
	'numL' => 6
};

is_deeply( $cell, $cell_ref16, "Test #16.2: 'onecell()' with option 'limit'(6) < MAX line (12)");


### Test 6
warnings_are {
	$nLines = onecell( undef, $op );
} [], 'Checked carp warning for Test #6';

is( $nLines, undef, "Test #6: 'onecell()' returns undef for UNDEFINED string");
undef $nLines;


### Test 7
warnings_are {
	$nLines = onecell( \$string, $op );
} [], 'Checked carp warning for Test #7';

is( $nLines, undef, "Test #7: 'onecell()' returns undef for NOT SCALAR string");
undef $nLines;


### Test 8
warnings_are {
	$nLines = onecell( $string );
} [], 'Checked carp warning for Test #8';

is( $nLines, undef, "Test #8: 'onecell()' returns undef for UNDEFINED options");
undef $nLines;


### Test 9
warnings_are {
	$nLines = onecell( $string, $string );
} [], 'Checked carp warning for Test #9';

is( $nLines, undef, "Test #9: 'onecell()' returns undef for NOT HASH options");
undef $nLines;

### Test 10
warnings_are {
	$nLines = onecell(' ', $op );
} [
#	qr//,
], 'Checked carp warning for Test #10';

is( $nLines, 0, "Test #10.1: 'onecell()' returns 0 for EMPTY string");
undef $nLines;

( $cell ) = onecell(' ', $op );
is_deeply( $cell, {lines => [' '], wxL => [0], numL => 0, stop => 0,}, "Test #10.2: 'onecell()' returns HASH for EMPTY string");


### Test 11
delete $op->{merge};
delete $op->{cell_width}, # width of cell/box, (pt)

throws_ok {
	$nLines = onecell('QWERTY', $op );
} qr/Cell width is NOT specified/, 'Checked croak for Test #11';

is( $nLines, undef, "Test #11: 'onecell()' returns undef for UNDEFINED 'cell_width' option");
undef $nLines;


### Test 12
$op->{cell_width} = 1;
$op->{offset} = -1;
$nLines = onecell('QWERTY', $op );

is( $nLines, undef, "Test #12.1: 'onecell()' returns undef for option 'offset' = -1");
undef $nLines;

$op->{offset} = 100;
$nLines = onecell('QWERTY', $op );

is( $nLines, undef, "Test #12.2: 'onecell()' returns undef for option 'offset' > length of string");
undef $nLines;


### Test 13
$op->{cell_width} = 2; # (pt)
$op->{offset} = 0;
$op->{limit} = -100;

warnings_are {
	( $cell ) = onecell('QWERTY, QWERTY~123', $op );
} [], 'Checked carp warning for Test #13';

$cell_ref = {
          'wxL' => [
                     747,
                     913,
                     585,
                     653,
                     610,
                     617,
                     387,
                     747,
                     913,
                     585,
                     653,
                     610,
                     617,
                     554,
                     594,
                     594,
                     594
                   ],
          'numL' => 17,
          'stop' => 18,
          'lines' => [
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\-',
                       'T\\-',
                       'Y',
                       ', ',
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\-',
                       'T\\-',
                       'Y{\hskip0pt plus .02em}',
                       '~{\\hskip0pt plus .02em}',
                       '1{\\hskip0pt plus .02em}',
                       '2{\\hskip0pt plus .02em}',
                       '3'
                     ]
};

is_deeply( $cell, $cell_ref, "Test #13: 'onecell()' option 'cell_width' < symbol size and limit < 0");

### Test 14
$op->{cell_width} = 12; # (pt)

warnings_are {
	( $cell ) = onecell('QWERTY, QWERTY~123   ', $op );
} [], 'Checked carp warning for Test #14';

$cell_ref = {
          'wxL' => [
                     747,
                     893,
                     585,
                     653,
                     610,
                     '889',
                     747,
                     893,
                     585,
                     653,
                     610,
                     1163,
                     1188,
                     594
                   ],
          'numL' => 14,
          'lines' => [
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\-',
                       'T\\-',
                       'Y, ',
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\-',
                       'T\\-',
                       'Y~{\\hskip0pt plus .02em}',
                       '12{\\hskip0pt plus .02em}',
                       '3'
                     ],
          'stop' => 18
};

is_deeply( $cell, $cell_ref, "Test #14: 'onecell()' option 'cell_width' < symbol size");


### Test 15
$op->{cell_width} = 11; # (pt)

warnings_are {
	( $cell ) = onecell('WWWWW @W@W, @@@', $op );
} [], 'Checked carp warning for Test #15';

$cell_ref = {
          'numL' => 12,
          'wxL' => [
                     913, # 'W'
                     907, # 'W' +KPX{W}{W} = 913-6
                     907,
                     907,
                     '1069', # 'W' +KPX{W}{W} +'space' = 913-6+162
                     1163,
                     913,
                     1163,
                     '1226',
                     1163,
                     1163,
                     '1163'
                   ],
          'lines' => [
                       'W\\-',
                       'W\\-',
                       'W\\-',
                       'W\\-',
                       'W ',
                       '@{\\hskip0pt plus .02em}',
                       'W\\-',
                       '@{\\hskip0pt plus .02em}',
                       'W, ',
                       '@{\\hskip0pt plus .02em}',
                       '@{\\hskip0pt plus .02em}',
                       '@'
                     ],
          'stop' => 15
};

is_deeply( $cell, $cell_ref, "Test #15: 'onecell()' option 'cell_width' = 11 < symbol size");


### Test 97
warnings_exist {
	( $cell ) = onecell("A\x{3400} ", $op );
} [ qr/Undefined width for symbol with hexcode:/ ], 'Checked carp warning for Test #97.1';

is_deeply( $cell, { lines => [ 'A\\-', "\x{3400}" ], stop => 2, wxL => [ 645, 1163 ], numL => 2 }, "Test #97.1 onecell(): chinese character");

warnings_exist {
	$nLines = onecell("A\x{3400}", $op );
} [ qr/Undefined width for symbol with hexcode:/ ], 'Checked carp warning for Test #97.2';

is( $nLines, 2, "Test #97.2 onecell(): chinese character");
undef $nLines;

$op->{limit} = 1;
warnings_exist {
	( $cell ) = onecell("A\x{3400} ", $op );
} [ qr/Undefined width for symbol with hexcode:/ ], 'Checked carp warning for Test #97.3';

delete $op->{limit};

is_deeply( $cell, { lines => [ 'A\\-', ], stop => 1, wxL => [ 645, ], numL => 1 }, "Test #97.3 onecell(): chinese character");

### Test 98
$op->{cell_width} = 10; # (pt)
my $space = $op->{space}; delete $op->{space};

warnings_are {
	( $cell ) = onecell('A B C', $op );
} [], 'Checked carp warning for Test #98.1';

$cell_ref = {
          'stop' => 5,
          'numL' => 3,
          'wxL' => [
                     855, # +645 +('space')291 -(shrink)81
                     851, # +641 +('space')291 -(shrink)81
                     598 # Ok
                   ],
          'lines' => [
                       'A ',
                       'B ',
                       'C'
                     ]
        };

is_deeply( $cell, $cell_ref, "Test #98.1 onecell(): for UNDEFINED 'space' option");


my $shrink = $op->{shrink}; delete $op->{shrink};

warnings_are {
	( $cell ) = onecell('A B C', $op );
} [], 'Checked carp warning for Test #98.2';

my $cell_ref2 = {
          'numL' => 3,
          'stop' => 5,
          'lines' => [
                       'A ',
                       'B ',
                       'C'
                     ],
          'wxL' => [
                     936, # +645 +('space')291
                     932, # +641 +('space')291
                     598
                   ]
        };


is_deeply( $cell, $cell_ref2, "Test #98.2 onecell(): for UNDEFINED 'shrink' option");

my $spaceWX = $op->{font_metrics}{WX}{32}; delete $op->{font_metrics}{WX}{32};

throws_ok {
	$nLines = onecell('A B C', $op );
} qr/Base whitespace width is NOT specified/, 'Checked croak for Test #98.3';

is( $nLines, undef, "Test #98.3 onecell(): returns undef for UNDEFINED 'space' option and 'WX' of space");
undef $nLines;


# Restoring values
$op->{space} = $space;
$op->{font_metrics}{WX}{32} = $spaceWX;
$op->{shrink} = $shrink;

### Test 99
$op->{cell_width} = 100; # (pt)

warnings_are {
	( $cell ) = onecell('WA', $op );
} [], 'Checked carp warning for Test #99.1';

is_deeply( $cell,  { 'numL' => 1, 'lines' => ['WA'], 'wxL' => [1530], 'stop' => 2 }, "Test #99.1: 'onecell()' with 'font_metrics'->'KPX' option");

delete $op->{font_metrics}{KPX};

warnings_are {
	( $cell ) = onecell('WA', $op );
} [], 'Checked carp warning for Test #99.2';

is_deeply( $cell,  { 'numL' => 1, 'lines' => ['WA'], 'wxL' => [1558], 'stop' => 2 }, "Test #99.2: 'onecell()' without 'font_metrics'->'KPX' option");

delete $op->{font_metrics};

throws_ok {
	$nLines = onecell('QWERTY', $op );
} qr/Font metrics are NOT specified/, 'Checked croak for Test #99.3';

is( $nLines, undef, "Test #99.3: 'onecell()' returns undef for UNDEFINED 'font_metrics' option");
undef $nLines;


###DEL###
# open F, ">test.log";
# print F Dumper($cell);
# close F;
# exit;

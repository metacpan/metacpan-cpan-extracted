# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 07-multicell.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 51;
use Test::More::UTF8;
# use Test::Number::Delta within => 1e-9;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use Text::Hyphen;
use Text::Hyphen::RU;

### Test 1.1
BEGIN { use_ok('LaTeX::Replicase') };
use LaTeX::Replicase qw(font_metrics multicell); # :all

##### Test multicell() #####

### Test 2
my $AFMfile = 't/PTC55F.afm';

my $op = { noBbox =>1 }; # glyphlist =>$glyphlist, noKPX =>1, mate =>'glyph'|'symbol'|'hex'

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
#	done_lines => 2,
#	cell_limit => 3,
#	orphan => 0,
	cell_width => $cell_width, # width of cell/box, (pt)
	font_metrics => $font_metrics, # table of font metrics for decimal Unicode number
#	font_metrics => font_metrics('PTC55F.afm', { glyphlist => 'glyphlist.txt', noBbox =>1 }),
	base_font_size => 10, # depending on the document's base font size (pt), see \documentclass[...pt]
#	font_size => 'normalsize', # TeX-font size of text in cell/box, e.g. 'small', 'normalsize', 'large', etc.
	space => 2.43, # Regular space between words (pt), see fontdimen 2
	shrink => 0.81, # whitespace shrink (pt), see fontdimen 4
	# merge => 1,
	# offset => 0,
	limit => 5,
	# hyphenation => [],
};

my $string = "I was going to do something today but I haven't finished doing nothing from yesterday.
Я собирался кое-что сделать сегодня, но еще не закончил ничегонеделание со вчерашнего дня    ";

### Test 4.1
my $cells = [];

warnings_are {
	( $cells ) = multicell( $string, $op );
} [], 'Checked carp warning for Test #4.1';

my $cells_ref = {
          numC => 3, # number of no empty cells
          stopC => [ # position in $string where the extraction of symbols into cell stopped
                       87,
                       166,
                       -1
                     ],
          done_lines => 1,
          end => -1,
          scale => 1,
          numL => [ # number of lines
                      5,
                      5,
                      1
                    ],
          wxC => [ # arrays of line widths (*100pt) for 'cells'
                     41496, # 8257+8398+8346+8313+8344 -(space=243-81)=162
                     41204, # 8413+7964+8342+8432+8053
                     5684
                   ],
          cells => [ # arrays of no empty cells
                       'I was going to do something today but I haven\'t finis\\-hed doing nothin\\-g from yesterday.', #0
                       'Я собирался кое-\\hskip0pt plus.02em\\/что сделать сего\\-дня, но еще не за\\-кончил ничегоне\\-делание со вчер\\-', #1
                       'ашнего дня' #2
                     ]
};

is_deeply( $cells, $cells_ref, "Test #4.1: 'multicell()' without 'hyphenation' option");

$op->{hyphenation} = 'Blah-Blah';
( $cells ) = multicell( $string, $op );

is_deeply( $cells, $cells_ref, "Test #4.4: 'multicell()' with BAD 'hyphenation' option");

$op->{hyphenation} = [];
( $cells ) = multicell( $string, $op );

is_deeply( $cells, $cells_ref, "Test #4.5: 'multicell()' with EMPTY ARRAY of 'hyphenation' option");

### Test 4.2

$op->{hyphenation} = [
		{ name =>'en', action => $hyp_en, }, # English
	# OR
	# { msk => qr/[a-zA-Z]+/o, action => $hyp_en, },
#		{ name =>'ru', action => $hyp_ru, }, # Russian
	# OR
		{ msk => qr/[а-яА-Я]+/o, action => $hyp_ru, },
		{ name =>'Blah', action => $hyp_en, },
	];

my $numCells;
warnings_are {
	$numCells = multicell( $string, $op );
} [], 'Checked carp warning for Test #4.2';

is( $numCells, 3, "Test #4.2: 'multicell()' returns SCALAR number of cells");
undef $numCells;


### Test 4.3
warnings_are {
	( $cells ) = multicell( $string, $op );
} [], 'Checked carp warning for Test #4.3';

$cells_ref = {
          numC => 3, # number of no empty cells
          numL => [ # number of lines
                      5,
                      5,
                      2
                    ],
          done_lines => 2,
          cells => [ # arrays of no empty cells
                       'I was going to do something today but I haven\'t fin\\-ished doing noth\\-ing from yes\\-ter\\-', #0
                       'day. Я собирался кое-что сделать сегодня, но еще не закончил ни\\-че\\-го\\-не\\-де\\-ла\\-ние', #1
                       'со вчерашнего дня' #2
                     ],
          stopC => [ # position in $string where the extraction of symbols into cell stopped
                       82,
                       159,
                       -1
                     ],
          end => -1,
          scale => 1,
          wxC => [ # arrays of line widths (*100pt) for 'cells'
                     39588, # 8257+8398+7530+8171+7232
                     39424, # 8324+7989+8000+7479+7794 +(space)=162
                     9372 # 7546+1826
                   ]
};

is_deeply( $cells, $cells_ref, "Test #4.3: 'multicell()' returns HASH.ARRAYS");

### Test 4.4
$op->{cell_limit} = -1;
( $cells ) = multicell( $string, $op );

is_deeply( $cells, $cells_ref, "Test #4.4: 'multicell()' with defined 'cell_limit' < 0 option");


### Test 4.5
$op->{cell_limit} = 2;
( $cells ) = multicell( $string, $op );

my $cells_ref_4_5 = {
          numC => 2, # number of no empty cells
          numL => [ # number of lines
                      5,
                      5,
                    ],
          done_lines => 5,
          cells => [ # arrays of no empty cells
                       'I was going to do something today but I haven\'t fin\\-ished doing noth\\-ing from yes\\-ter\\-', #0
                       'day. Я собирался кое-что сделать сегодня, но еще не закончил ни\\-че\\-го\\-не\\-де\\-ла\\-ние', #1
#                       'со вчерашнего дня' #2
                     ],
          stopC => [
                       82,
                       159,
                     ],
          end => 159,
          scale => 1,
          wxC => [
                     39588,
                     39424,
                   ]
};

is_deeply( $cells, $cells_ref_4_5, "Test #4.5: 'multicell()' with defined 'cell_limit' > 0 option");

delete $op->{cell_limit};


### Test 16.0
$op->{merge} = 0;
$op->{offset} = 0;
$op->{limit} = 0;
$op->{font_size} = 'normalsize';
delete $op->{base_font_size};

warnings_are {
	( $cells ) = multicell( $string, $op );
} [], 'Checked carp warning for Test #16.0';

my $cells_ref3 = {
	'wxC' => [ 88546 ],
	'cells' => ["I was going to do something today but I haven't fin\\-ished doing noth\\-ing from yes\\-ter\\-day. Я собирался кое-что сделать сегодня, но еще не закончил ни\\-че\\-го\\-не\\-де\\-ла\\-ние со вчерашнего дня"],
	'done_lines' => 12,
	'numL' => [12],
	'numC' => 1,
	'stopC' => [176],
	scale => 1,
	'end' => 176
};

is_deeply( $cells, $cells_ref3, "Test #16.0: 'multicell()' with 'merge' option");


### Test 16.1
$numCells = multicell( $string, $op );
is( $numCells, 12, "Test #16.1: 'multicell()' returns SCALAR number of cells for option 'limit' = 0");
undef $numCells;


### Test 16.2
delete $op->{merge};
$op->{limit} = 20;

$cells_ref3->{end} = $cells_ref3->{stopC}[0] = -1;

warnings_are {
	( $cells ) = multicell( $string, $op );
} [], 'Checked carp warning for Test #16.2';

is_deeply( $cells, $cells_ref3, "Test #16.2: 'multicell()' with option 'limit'(20) > MAX line (12)");


### Test 6
warnings_are {
	$numCells = multicell( undef, $op );
} [], 'Checked carp warning for Test #6';

is( $numCells, undef, "Test #6: 'multicell()' returns undef for UNDEFINED string");
undef $numCells;


### Test 7
warnings_are {
	$numCells = multicell( \$string, $op );
} [], 'Checked carp warning for Test #7';

is( $numCells, undef, "Test #7: 'multicell()' returns undef for NOT SCALAR string");
undef $numCells;


### Test 8
warnings_are {
	$numCells = multicell( $string );
} [], 'Checked carp warning for Test #8';

is( $numCells, undef, "Test #8: 'multicell()' returns undef for UNDEFINED options");
undef $numCells;


### Test 9
warnings_are {
	$numCells = multicell( $string, $string );
} [], 'Checked carp warning for Test #9';

is( $numCells, undef, "Test #9: 'multicell()' returns undef for NOT HASH options");
undef $numCells;


### Test 10
warnings_are {
	$numCells = multicell(' ', $op );
} [
#	qr//,
], 'Checked carp warning for Test #10';

is( $numCells, 0, "Test #10.1: 'multicell()' returns 0 for EMPTY string");
undef $numCells;

( $cells ) = multicell(' ', $op );
is_deeply( $cells, { 'end' => 0, 'stopC' => [], 'cells' => [], 'done_lines' => 0, 'numL' => [], 'numC' => 0, 'wxC' => [], scale => undef }, "Test #10.2: 'multicell()' returns HASH for EMPTY string");
$cells = {};


### Test 11
delete $op->{merge};
delete $op->{cell_width}, # width of cell/box, (pt)

throws_ok {
	$numCells = multicell('QWERTY', $op );
} qr/Cell width is NOT specified/, 'Checked croak for Test #11';

is( $numCells, undef, "Test #11: 'multicell()' returns undef for UNDEFINED 'cell_width' option");
undef $numCells;


### Test 12
$op->{cell_width} = 1;
$op->{offset} = -1;
( $cells ) = multicell('QWERTY', $op );
is_deeply( $cells, { done_lines => 6, numL => [6], stopC => [-1], cells => ['Q\\-W\\-E\\-R\\-T\\-Y'], wxC => [4125], end => -1, numC => 1, scale => 1,}, "Test #12.1: 'multicell()' with option 'offset' = -1");
$cells = {};

$op->{offset} = 100;
$numCells = multicell('QWERTY', $op );

is( $numCells, 0, "Test #12.2: 'multicell()' returns 0 for option 'offset' > length of string");
undef $numCells;


### Test 13
$op->{cell_width} = 2; # (pt)
$op->{offset} = 0;
$op->{limit} = -100;

warnings_are {
	( $cells ) = multicell('QWERTY, QWERTY~123', $op );
} [], 'Checked carp warning for Test #13';

$cells_ref = {
          'numC' => 17,
          'stopC' => [ 1..7, 9..17, -1 ],
          'cells' => [
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\hskip0pt plus.02em\\/',
                       'T\\hskip0pt plus.02em\\/',
                       'Y\\hskip0pt plus.02em\\/',
                       ',',
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\hskip0pt plus.02em\\/',
                       'T\\hskip0pt plus.02em\\/',
                       'Y\\hskip0pt plus.02em\\/',
                       '~\\hskip0pt plus.02em\\/',
                       '1\\hskip0pt plus.02em\\/',
                       '2\\hskip0pt plus.02em\\/',
                       '3'
                     ],
          'wxC' => [
                     747,
                     913,
                     585,
                     653,
                     610,
                     617,
                     '225',
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
          'numL' => [ (1)x17 ],
          'done_lines' => 1,
          scale => 1,
          'end' => -1
};

is_deeply( $cells, $cells_ref, "Test #13: 'multicell()' option 'cell_width' < symbol size and limit < 0");


### Test 14
$op->{cell_width} = 12; # (pt)

warnings_are {
	( $cells ) = multicell('QWERTY, QWERTY~123   ', $op );
} [], 'Checked carp warning for Test #14';

$cells_ref = {
          'numC' => 14,
          'numL' => [ (1)x14, ],
          scale => 1,
          'stopC' => [
                       1,
                       2,
                       3,
                       4,
                       5,
                       8,
                       9,
                       10,
                       11,
                       12,
                       13,
                       15,
                       17,
                       -1
                     ],
          'wxC' => [
                     747,
                     913,
                     585,
                     653,
                     610,
                     735,
                     747,
                     913,
                     585,
                     653,
                     610,
                     1171,
                     1188,
                     594
                   ],
          'end' => -1,
          'cells' => [
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\hskip0pt plus.02em\\/',
                       'T\\hskip0pt plus.02em\\/',
                       'Y,',
                       'Q\\-',
                       'W\\-',
                       'E\\-',
                       'R\\hskip0pt plus.02em\\/',
                       'T\\hskip0pt plus.02em\\/',
                       'Y~\\hskip0pt plus.02em\\/',
                       '12\\hskip0pt plus.02em\\/',
                       '3'
                     ],
          'done_lines' => 1
};

is_deeply( $cells, $cells_ref, "Test #14: 'multicell()' option 'cell_width' < symbol size");


### Test 15
$op->{cell_width} = 11; # (pt)

warnings_are {
	( $cells ) = multicell('WWWWW @W@W, @@@', $op );
} [], 'Checked carp warning for Test #15';

$cells_ref = {
          'numC' => 12,
          'numL' => [ (1)x12, ],
          scale => 1,
          'stopC' => [
                       1,
                       2,
                       3,
                       4,
                       6,
                       7,
                       8,
                       9,
                       12,
                       13,
                       14,
                       -1
                     ],
          'wxC' => [
                     913,
                     913,
                     913,
                     913,
                     913,
                     1163,
                     913,
                     1163,
                     1064,
                     1163,
                     1163,
                     1163
                   ],
          'cells' => [
                       'W\\-',
                       'W\\-',
                       'W\\-',
                       'W\\-',
                       'W',
                       '@\\hskip0pt plus.02em\\/',
                       'W\\-',
                       '@\\hskip0pt plus.02em\\/',
                       'W,',
                       '@\\hskip0pt plus.02em\\/',
                       '@\\hskip0pt plus.02em\\/',
                       '@'
                     ],
          'done_lines' => 1,
          'end' => -1
};

is_deeply( $cells, $cells_ref, "Test #15: 'multicell()' option 'cell_width' = 11 < symbol size");


### Test 97
# warnings_exist 
{
	local $SIG{__WARN__} = sub {
		my $warning = shift;
		warn $warning unless $warning =~ /Undefined width for symbol with hexcode:/;
	};

	( $cells ) = multicell("A\x{3400} ", $op );
}
# [ qr/Undefined width for symbol with hexcode:/ ], 'Checked carp warning for Test #97.1';

is_deeply( $cells, { scale => 1, cells => [ 'A\\-', "\x{3400}" ], stopC => [1, -1], wxC => [ 645, 1163 ], numL => [1, 1], numC => 2, end => -1, done_lines => 1 },
	"Test #97.1 multicell(): chinese character");


### Test 98
$op->{cell_width} = 10; # (pt)
my $space = $op->{space}; delete $op->{space};

warnings_are {
	( $cells ) = multicell('A B C', $op );
} [], 'Checked carp warning for Test #98.1';

$cells_ref = {
          'numC' => 3,
          scale => 1,
          'stopC' => [
                       2,
                       4,
                       -1
                     ],
          'wxC' => [
                     645,
                     641,
                     624
                   ],
          'numL' => [
                      1,
                      1,
                      1
                    ],
          'cells' => [
                       'A',
                       'B',
                       'C'
                     ],
          'done_lines' => 1,
          'end' => -1
        };

is_deeply( $cells, $cells_ref, "Test #98.1 multicell(): for UNDEFINED 'space' option");


my $shrink = $op->{shrink}; delete $op->{shrink};

warnings_are {
	( $cells ) = multicell('A B C', $op );
} [], 'Checked carp warning for Test #98.2';

is_deeply( $cells, $cells_ref, "Test #98.2 multicell(): for UNDEFINED 'shrink' option");


my $spaceWX = $op->{font_metrics}{WX}{32}; delete $op->{font_metrics}{WX}{32};

throws_ok {
	$numCells = multicell('A B C', $op );
} qr/Base whitespace width is NOT specified/, 'Checked croak for Test #98.3';

is( $numCells, undef, "Test #98.3 multicell(): returns undef for UNDEFINED 'space' option and 'WX' of space");
undef $numCells;

# Restoring values
$op->{space} = $space;
$op->{font_metrics}{WX}{32} = $spaceWX;
$op->{shrink} = $shrink;

### Test 99
$op->{cell_width} = 100; # (pt)

warnings_are {
	( $cells ) = multicell('WA', $op );
} [], 'Checked carp warning for Test #99.1';

is_deeply( $cells,  { scale => 1, end => -1, cells => ['WA'], wxC => [1530], numC => 1, done_lines => 1, stopC => [-1], numL => [1] }, 
	"Test #99.1: 'multicell()' with 'font_metrics'->'KPX' option");


delete $op->{font_metrics}{KPX};

warnings_are {
	( $cells ) = multicell('WA', $op );
} [], 'Checked carp warning for Test #99.2';

is_deeply( $cells, { scale => 1, end => -1, cells => ['WA'], wxC => [1558], numC => 1, done_lines => 1, stopC => [-1], numL => [1] }, 
	"Test #99.2: 'multicell()' without 'font_metrics'->'KPX' option");

delete $op->{font_metrics};

throws_ok {
	$numCells = multicell('QWERTY', $op );
} qr/Font metrics are NOT specified/, 'Checked croak for Test #99.3';

is( $numCells, undef, "Test #99.3: 'multicell()' returns undef for UNDEFINED 'font_metrics' option");
undef $numCells;


###DEL###
# open F, ">test.log";
# print F Dumper($cells);
# close F;
# exit;

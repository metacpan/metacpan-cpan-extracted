package main;

use strict;
use warnings;

use HTML::TableContentParser;
use Test::More 0.88;

my $obj = HTML::TableContentParser->new();

eval {
    $obj->parse();
    fail( 'parse() with no argument did not fail' );
    1;
} or like( $@, qr{ \A \QArgument must be defined\E }smx,
    'parse() with no argument failed correctly (RT 7262)' );

## Test basic functionality. Create a table, and make sure parsing it returns
## the correct values to the callback.

note( 'Test basic functionality' );

my $table_caption  = 'This is a caption';
my $table_content1 = 'This is table cell content 1';
my $table_content2 = 'This is table cell content 2';
my $table_content3 = '<a href="SomeLink">This is table cell content 3, a link</a>';
my $table_content4 = 'Some more text wrapping <a href="SomeLink">This is table cell content 4</a> a link.';
my $header_text = 'Header text';

my $html = qq{
<!DOCTYPE HTML SYSTEM>
<html>
<head>
<title>Test</title>
</head>
<body>
Some text that should /not/ get picked up by the parser.
<TABLE id='foo' border='0'>
<CAPTION id='test'>$table_caption</CAPTION>
<tr><th>$header_text</th></tr>
<tr><td>$table_content1</td></tr>
<tr><td>$table_content2</td></tr>
<tr><td>$table_content3</td></tr>
<tr><td>$table_content4</td></tr>
</table>
</body>
</html>
};

$HTML::TableContentParser::DEBUG = 0;

my $tables = $obj->parse($html);
is( $tables->[0]->{caption}->{data}, $table_caption, 'Table caption' );
is( $tables->[0]->{rows}->[0]->{headers}->[0]->{data}, $header_text,
    'First row' );
is( $tables->[0]->{rows}->[1]->{cells}->[0]->{data}, $table_content1,
    'First row' );
is( $tables->[0]->{rows}->[2]->{cells}->[0]->{data}, $table_content2,
    'Second row' );
is( $tables->[0]->{rows}->[3]->{cells}->[0]->{data}, $table_content3,
    'Third row' );
is( $tables->[0]->{rows}->[4]->{cells}->[0]->{data}, $table_content4,
    'Fourth row' );

is_deeply( $tables, [
	{
	    border	=> 0,
	    caption	=> {
		data	=> $table_caption,
		id	=> 'test',
	    },
	    headers	=> [
		{
		    data	=> $header_text,
		},
	    ],
	    id		=> 'foo',
	    rows	=> [
		{
		    headers	=> [
			{
			    data	=> $header_text,
			},
		    ],
		},
		{
		    cells	=> [
			{
			    data	=> $table_content1,
			},
		    ],
		},
		{
		    cells	=> [
			{
			    data	=> $table_content2,
			},
		    ],
		},
		{
		    cells	=> [
			{
			    data	=> $table_content3,
			},
		    ],
		},
		{
		    cells	=> [
			{
			    data	=> $table_content4,
			},
		    ],
		},
	    ],
	},
    ], 'Complete returned structure' );

{
    note( 'Test basic functionality, classic parse' );

    local $HTML::TableContentParser::CLASSIC = 1;
    my $o = HTML::TableContentParser->new();
    
    cmp_ok( $o->classic(), '==', 1, q<'classic' attr set by default> );

    my $t = $o->parse($html);

    is_deeply( $t, [
	    {
		border	=> 0,
		caption	=> {
		    data	=> $table_caption,
		    id	=> 'test',
		},
		headers	=> [
		    {
			data	=> $header_text,
		    },
		],
		id		=> 'foo',
		rows	=> [
		    {},
		    {
			cells	=> [
			    {
				data	=> $table_content1,
			    },
			],
		    },
		    {
			cells	=> [
			    {
				data	=> $table_content2,
			    },
			],
		    },
		    {
			cells	=> [
			    {
				data	=> $table_content3,
			    },
			],
		    },
		    {
			cells	=> [
			    {
				data	=> $table_content4,
			    },
			],
		    },
		],
	    },
	], 'Complete returned structure, classic parse' );
}


note( 'More complex HTML' );


## Some more complicated tables..

my @rows = (
	['r1td1', 'r1td2', 'r1td3'],
	['r2td1', 'r2td2', 'r2td3'],
	['r3td1', 'r3td2', 'r3td3'],
);

my @hdrs = qw(h1 h2 h3);


$html = qq{
<!DOCTYPE HTML SYSTEM>
<html>
<head>
<title>Test</title>
</head>
<body>
Some text that should /not/ get picked up by the parser.
<table id='fruznit' border='0'>
};

$html .= '<tr><th>' . join('</th><th>', @hdrs) . "</th></tr>\n";

for (@rows) {
	$html .= '<tr><td>' . join('</td><td>', @$_) . "</td></tr>\n";
}

$html .= qq{
</table>
Some more intermediary text which should be ignored.
<TABLE id='crumhorn' border='0'>
};


$html .= '<tr><th>' . join('</th><th>', @hdrs) . "</th></tr>\n";

for (@rows) {
	$html .= '<tr><td>' . join('</td><td>', @$_) . "</td></tr>\n";
}


$html .= qq{
</table>
</body>
</html>
};


## Set to 1 to debug this parse.
$HTML::TableContentParser::DEBUG = 0;
$tables = $obj->parse($html);

## We should have two tables..
cmp_ok( @$tables, '==', 2, 'Have 2 tables' );

## and three headers for each table
for my $t ( 0 .. $#$tables ) {
	for ( 0 .. $#hdrs ) {
		is( $tables->[$t]->{headers}->[$_]->{data}, $hdrs[$_],
		    "Table $t column $_ header" );
	}
}


## and three rows of three cells each, for each table.. (18 total).
for my $t ( 0 .. $#$tables ) {
	for my $r ( 0 .. $#rows ) {
		for (0..2) {
			is(
			    $tables->[$t]->{rows}->[$r+1]->{cells}->[$_]->{data},
			    $rows[$r]->[$_],
			    "Table $t row $r column $_",
			);
		}
	}
}

# Nested table

note( 'Nested table' );

$tables = $obj->parse( qq{
<!DOCTYPE HTML SYSTEM>
<html>
<head>
<title>Test</title>
</head>
<body>
Some text that should /not/ get picked up by the parser.
<TABLE id='foo' border='0'>
<tr><td>Before nested table. <table>
<tr><td>Inside nested table.</td></tr>
</table> After nested table.</td><td>Second column.</td></tr>
</table>
</body>
</html>
} );

is( $tables->[1]{rows}[0]{cells}[0]{data},
    'Inside nested table.',
    'Nested table' );

is( $tables->[0]{rows}[0]{cells}[0]{data},
    'Before nested table.  After nested table.',
    'Cell containing nested table' );

is( $tables->[0]{rows}[0]{cells}[1]{data},
    'Second column.',
    'Cell after nested table.' );

done_testing;

1;

# ex: set textwidth=72 :

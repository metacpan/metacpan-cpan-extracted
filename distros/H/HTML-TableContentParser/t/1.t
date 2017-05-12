# $Id: 1.t,v 1.5 2002/07/14 15:00:43 simon Exp $


use Test;

BEGIN { plan tests => 34 }

## If in @INC, should succeed
use HTML::TableContentParser;
ok(1);

## make sure we can turn on debugging..
$HTML::TableContentParser::DEBUG = 1;
ok(1);

## ..and back off.
$HTML::TableContentParser::DEBUG = 0;
ok(1);


## Test object creation

$obj = HTML::TableContentParser->new();
ok(defined $obj, 1, $@);



## Test basic functionality. Create a table, and make sure parsing it returns
## the correct values to the callback.


$table_caption  = 'This is a caption';
$table_content1 = 'This is table cell content 1';
$table_content2 = 'This is table cell content 2';
$table_content3 = '<a href="SomeLink">This is table cell content 3, a link</a>';
$table_content4 = 'Some more text wrapping <a href="SomeLink">This is table cell content 4</a> a link.';
$header_text = 'Header text';

$html = qq{
<html>
<head>
</head>
<body>
Some text that should /not/ get picked up by the parser.
<TABLE id='foo' name='bar' border='0'>
<CAPTION id='test'>$table_caption</CAPTION>
<th>$header_text</th>
<tr><td>$table_content1</td></tr>
<tr><td>$table_content2</td></tr>
<tr><td>$table_content3</td></tr>
<tr><td>$table_content4</td></tr>
</table>
</body>
</html>
};





$HTML::TableContentParser::DEBUG = 0;
$tables = $obj->parse($html);
ok($tables->[0]->{caption}->{data}, $table_caption, $@);
ok($tables->[0]->{rows}->[0]->{cells}->[0]->{data}, $table_content1, $@);
ok($tables->[0]->{rows}->[1]->{cells}->[0]->{data}, $table_content2, $@);
ok($tables->[0]->{rows}->[2]->{cells}->[0]->{data}, $table_content3, $@);
ok($tables->[0]->{rows}->[3]->{cells}->[0]->{data}, $table_content4, $@);




## Some more complicated tables..

my @rows = (
	['r1td1', 'r1td2', 'r1td3'],
	['r2td1', 'r2td2', 'r2td3'],
	['r3td1', 'r3td2', 'r3td3'],
);

my @hdrs = qw(h1 h2 h3);


$html = qq{
<html>
<head>
</head>
<body>
Some text that should /not/ get picked up by the parser.
<table id='fruznit' name='braknor' border='0'>
};

$html .= '<th>' . join('</th><th>', @hdrs) . "</th>\n";

for (@rows) {
	$html .= '<tr><td>' . join('</td><td>', @$_) . "</td></tr>\n";
}

$html .= qq{
</table>
Some more intermediary text which should be ignored.
<TABLE id='crumhorn' name='wallaby' border='0'>
};


$html .= '<th>' . join('</th><th>', @hdrs) . "</th>\n";

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
ok(@$tables, 2, @_);

## and three headers for each table
for $t (0..$#{@$tables}) {
	for (0..$#hdrs) {
		ok($tables->[$t]->{headers}->[$_]->{data}, $hdrs[$_], $@);
	}
}


## and three rows of three cells each, for each table.. (18 total).
for $t (0..$#{@$tables}) {
	for $r (0..$#rows) {
		for (0..2) {
			ok($tables->[$t]->{rows}->[$r]->{cells}->[$_]->{data}, $rows[$r]->[$_], $@);
		}
	}
}


### Tests for broken table removed in v0.12. 


## A nested table, tests added in v0.13
#####
#####my @rows = (
#####	['r1td1', 'r1td2', 'r1td3'],
#####	['r2td1', 'r2td2', 'r2td3'],
#####	['r3td1', 'r3td2', 'r3td3'],
#####);
#####
#####my @hdrs = qw(h1 h2 h3);
#####
#####$html = qq{
#####<html>
#####<head>
#####</head>
#####<body>
#####Some text that should /not/ get picked up by the parser.
#####};
#####
#####for $i (1..2) {
#####	$html .= "<table id='fruznit$i' name='braknor$i' border='0'>\n";
#####	$html .= '<th>' . join('</th><th>', @hdrs) . "</th>\n";
#####
#####	for (@rows) {
#####		$html .= "<tr><td>t$i" . join("</td><td>t$i", @$_) . "</td></tr>\n";
#####	}
#####
#####	$html .= "</table>\n";
#####}
#####
#####$html .= qq{
#####Some more intermediary text which should be ignored.
#####</body>
#####</html>
#####};
#####
#####
####### Set to 1 to debug this parse.
#####$HTML::TableContentParser::DEBUG = 0;
#####$tables = $obj->parse($html);
#####
####### We should have two tables..
#####ok(@$tables, 2, @_);
#####
####### and three headers for each table
#####for $t (0..$#{@$tables}) {
#####	for (0..$#hdrs) {
#####		ok($tables->[$t]->{headers}->[$_]->{data}, $hdrs[$_], $@);
#####	}
#####}
#####
#####
####### and three rows of three cells each, for each table.. (18 total).
#####for $t (0..$#{@$tables}) {
#####	for $r (0..$#rows) {
#####		for (0..2) {
#####			my $table = $t + 1;
#####			ok($tables->[$t]->{rows}->[$r]->{cells}->[$_]->{data},
#####				"t$table" . $rows[$r]->[$_], $@);
#####		}
#####	}
#####}
#####

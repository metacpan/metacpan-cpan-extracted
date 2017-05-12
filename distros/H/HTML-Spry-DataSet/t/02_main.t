#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::LongString;
use HTML::Spry::DataSet ();
use File::Remove        ();

File::Remove::clear('dataset.html');

# Create the object
my $dataset = HTML::Spry::DataSet->new;
isa_ok( $dataset, 'HTML::Spry::DataSet' );

# Add the tables to the object
$dataset->add( 'ds1',
	[ 'Rank', 'Dependencies', 'Author',   'Distribution'           ],
	[ '1',    '748',          'APOCAL',   'Task-POE-All'           ],
	[ '2',    '276',          'MRAMBERG', 'MojoMojo-Formatter-RSS' ],
);

# Add the tables to the object
$dataset->add( 'ds2',
	[ 'Rank', 'Dependents', 'Author',   'Distribution'           ],
	[ '1',    '748',        'APOCAL',   'Task-POE-All'           ],
	[ '2',    '276',        'MRAMBERG', 'MojoMojo-Formatter-RSS' ],
);

# Write out to the HTML file
ok( $dataset->write('dataset.html'), '->write returns ok' );

# Read the file back in
open( FILE, '<', 'dataset.html');
local $/ = undef;
my $buffer = <FILE>;
close FILE;

is_string( $buffer, <<'END_HTML', '->write creates the correct file' );
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
<table id='ds1'>
  <tr>
    <td>Rank</td>
    <td>Dependencies</td>
    <td>Author</td>
    <td>Distribution</td>
  </tr>
  <tr>
    <td>1</td>
    <td>748</td>
    <td>APOCAL</td>
    <td>Task-POE-All</td>
  </tr>
  <tr>
    <td>2</td>
    <td>276</td>
    <td>MRAMBERG</td>
    <td>MojoMojo-Formatter-RSS</td>
  </tr>
</table>
<table id='ds2'>
  <tr>
    <td>Rank</td>
    <td>Dependents</td>
    <td>Author</td>
    <td>Distribution</td>
  </tr>
  <tr>
    <td>1</td>
    <td>748</td>
    <td>APOCAL</td>
    <td>Task-POE-All</td>
  </tr>
  <tr>
    <td>2</td>
    <td>276</td>
    <td>MRAMBERG</td>
    <td>MojoMojo-Formatter-RSS</td>
  </tr>
</table>
</body>
</html>
END_HTML

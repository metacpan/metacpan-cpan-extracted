#!perl -w
use strict;
use Test::More tests => 1;
use HTML::TableTiler;

my $matrix = [[1..5],[6..10],[11..15]];

my $expected = << '__EOT__';
<table border="0" cellspacing="1" cellpadding="3">

<tr>
	<td bgcolor="#9999cc">1</td>
	<td bgcolor="#9999cc">2</td>
	<td bgcolor="#9999cc">3</td>
	<td bgcolor="#9999cc">4</td>
	<td bgcolor="#9999cc">5</td>
</tr>
<tr>
	<td bgcolor="#ccccff">6</td>
	<td bgcolor="#ccccff">7</td>
	<td bgcolor="#ccccff">8</td>
	<td bgcolor="#ccccff">9</td>
	<td bgcolor="#ccccff">10</td>
</tr>
<tr>
	<td bgcolor="#ccccff">11</td>
	<td bgcolor="#ccccff">12</td>
	<td bgcolor="#ccccff">13</td>
	<td bgcolor="#ccccff">14</td>
	<td bgcolor="#ccccff">15</td>
</tr>

</table>
__EOT__


my $tt = new HTML::TableTiler( *DATA );
my $tiled_table = $tt->tile_table($matrix);

is ($tiled_table, $expected);

__DATA__
<table border="0" cellspacing="1" cellpadding="3">
<tr>
	<td bgcolor="#9999cc">placeholder</td>
</tr>
<tr>
	<td bgcolor="#ccccff">placeholder</td>
</tr>
</table>

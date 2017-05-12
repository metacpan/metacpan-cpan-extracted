#!perl -w
use strict;
use Test::More tests => 1;
use HTML::TableTiler;


my $matrix = [[1..5],[6..10],[11..15]];

my $expected = << "__EOT__";
<table>
<tr>
	<td>1</td>
	<td>2</td>
	<td>3</td>
	<td>4</td>
	<td>5</td>
</tr>
<tr>
	<td>6</td>
	<td>7</td>
	<td>8</td>
	<td>9</td>
	<td>10</td>
</tr>
<tr>
	<td>11</td>
	<td>12</td>
	<td>13</td>
	<td>14</td>
	<td>15</td>
</tr>
</table>
__EOT__

my $tt = new HTML::TableTiler;
my $tiled_table = $tt->tile_table($matrix)."\n";

is ($tiled_table, $expected);

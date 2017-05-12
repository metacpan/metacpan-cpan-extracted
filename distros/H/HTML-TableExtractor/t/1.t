# $Id: 1.t,v 1.2 2002/06/11 15:54:24 simon Exp $


use Test;

BEGIN { plan tests => 5 }

## If in @INC, should succeed
use HTML::TableExtractor;
ok(1);


## Test object creation

$obj = HTML::TableExtractor->new();
ok(defined $obj, 1, $@);



## Test basic functionality. Create a table, and make sure parsing it returns
## the correct values to the callback.

$tablebits1 = '';

$tablebits2 = '';

$table_text = "<TABLE id='foo' name='bar' border='0'>";
$header_text = "<TH>";
$row_text = "<TR>";
$cell_text = "<TD>";

$html = qq{
<html>
<head>
</head>
Some text that should /not/ get picked up by the parser.
$table_text
$header_text</th>
$row_text
$cell_text
</td>
</tr>

</table>
</body>
</html>
};

sub table_callback
{
  my ($attr, $orig) = @_;
	$tablebits1 = "<TABLE";
	for (qw(id name border)) {
		$tablebits1 .= " $_='$attr->{$_}'";
	}
	$tablebits1 .= ">";
	$tablebits2 = $orig;
}


sub input_callback
{
}


$obj->parse($html,
		start_table => \&table_callback,
	);

ok($tablebits1, $table_text, $@);
ok($tablebits2, $table_text, $@);



## Now test that each callback gets called whenever it should. To do
## this we'll just store a count of how many times the callback gets 
## called, for all tags. It should be 16 times: 4 times for the table
## (start, normal, normal, end) and four each for the tags th,tr,td
$count = 0;

sub callback { ++$count }

$obj->parse($html, 
		start_table => \&callback,
		table       => \&callback,
		end_table   => \&callback,

		start_th    => \&callback,
		th          => \&callback,
		end_th      => \&callback,

		start_tr    => \&callback,
		tr          => \&callback,
		end_tr      => \&callback,

		start_td    => \&callback,
		td          => \&callback,
		end_td      => \&callback,

		);

ok($count, 16, $@);



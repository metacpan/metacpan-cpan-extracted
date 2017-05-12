#!/usr/bin/perl

use HTML::TreeBuilder;

# --------------------

my($root)      = HTML::TreeBuilder -> new();
my($file_name) = '/var/www/misc/color.html';
my($result)    = $root -> parse_file($file_name) || die "Can't parse: $file_name";
my(@node)      = $root -> look_down(_tag => 'table');
my(@td)        = $node[2] -> look_down(_tag => 'td');
my($i)         = 0;

my($hex, @hex);
my(%seen);
my($td);

for $td (@td)
{
	$i++;

	if ( ($i % 4) == 0)
	{
		$hex = substr(${$td -> content_array_ref()}[0], 1, 6);

		if ( (length($hex) == 6) && ! $seen{$hex})
		{
			push @hex, $hex;

			$seen{$hex} = 1;
		}
	}
}

$root -> delete();

print map{"$_\n"} sort @hex;

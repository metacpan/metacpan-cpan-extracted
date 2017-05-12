#!/usr/bin/env perl

use File::Spec;

use HTML::TreeBuilder;

use HTTP::Tiny;

# --------------------

my($file_name) = File::Spec -> catfile('data', 'node.shapes.html');

if (! -e $file_name)
{
	my($page_name) = 'http://www.graphviz.org/content/node-shapes';
	my($client)    = HTTP::Tiny -> new -> get($page_name);

	if ($$client{success})
	{
		open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";
		print OUT $$client{content};
		close OUT;
	}
	else
	{
		print "Failed to get $page_name: $$client{reason}. \n";
	}
}

my($root)      = HTML::TreeBuilder -> new();
my($result)    = $root -> parse_file($file_name) || die "Can't parse: $file_name";
my(@node)      = $root -> look_down(_tag => 'table');
my(@td)        = $node[2] -> look_down(_tag => 'td');

my(@a);
my(@content);
my(@shape);
my($td);

for $td (@td)
{
	@a = $td -> look_down(_tag => 'a');

	next if (! @a);

	@content = $a[0] -> content_list;

	push @shape, $content[0];
}

$root -> delete();

$file_name = File::Spec -> catfile('data', 'node.shapes.dat');

open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";
print OUT map{"$_\n"} sort @shape;
close OUT;


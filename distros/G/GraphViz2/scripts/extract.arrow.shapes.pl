#!/usr/bin/env perl

use File::Spec;

use HTML::TreeBuilder;

use HTTP::Tiny;

# --------------------

my($file_name) = File::Spec -> catfile('data', 'arrow.shapes.html');

if (! -e $file_name)
{
	my($page_name) = 'http://www.graphviz.org/content/arrow-shapes';
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
my(@td)        = $node[3] -> look_down(_tag => 'td');

my(@content);
my(@shape);
my($td);

for $td (@td)
{
	@content = $td -> content_list;

	if ($content[0] =~ /"(.+)"/)
	{
		push @shape, $1;
	}
}

$root -> delete();

$file_name = File::Spec -> catfile('data', 'arrow.shapes.dat');

open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";
print OUT map{"$_\n"} sort @shape;
close OUT;

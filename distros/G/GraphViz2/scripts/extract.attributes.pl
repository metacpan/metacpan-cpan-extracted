#!/usr/bin/env perl

use File::Spec;

use HTML::TreeBuilder;

use HTTP::Tiny;

# --------------------

my($file_name) = File::Spec -> catfile('data', 'attributes.html');

if (! -e $file_name)
{
	my($page_name) = 'http://www.graphviz.org/content/attrs';
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

my($root)    = HTML::TreeBuilder -> new();
my($result)  = $root -> parse_file($file_name) || die "Can't parse: $file_name";
my(@node)    = $root -> look_down(_tag => 'table');
my(@td)      = $node[5] -> look_down(_tag => 'td');
my($column)  = 0;
my(%context) =
	(
	 C => 'cluster',
	 E => 'edge',
	 G => 'graph',
	 N => 'node',
	 S => 'subgraph',
	);

my(@attribute);
my(@content, @column);
my(@row);
my($td);
my(@user);

for $td (@td)
{
	@content = $td -> content_list;

	if (ref $content[0])
	{
		$content[0] = ($content[0] -> content_list)[0];
	}

	$column++;

	$column = $column % 6;

	if ($column == 1)
	{
		push @column, $content[0];
	}
	elsif ($column == 2)
	{
		push @user, join(', ', map{$context{$_} } split(//, $content[0]) );
	}
}

$root -> delete();

$file_name = File::Spec -> catfile('data', 'attributes.dat');

open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";
print OUT map{"$column[$_] => $user[$_]\n"} 0 .. $#column;
close OUT;

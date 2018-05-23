use warnings;
use strict;
use HTML5::DOM;

# create parser object
my $parser = HTML5::DOM->new;

# parse some html
my $tree = $parser->parse('
	<label>Some list of OS:</lbnel>
	<ul class="list" data-what="os" title="OS list">
	   <li>UNIX</li>
	   <li>Linux</li>
	   <!-- comment -->
	   <li>OSX</li>
	   <li>Windows</li>
	   <li>FreeBSD</li>
	</ul>
');

# find one element by CSS selector
my $ul = $tree->at('ul.list');

# prints tag
print $ul->tag."\n"; # ul

# check if <ul> has class list
print "<ul> has class .list\n" if ($ul->classList->has('list'));

# add some class
$ul->classList->add('os-list');

# prints <ul> classes
print $ul->className."\n"; # list os-list

# prints <ul> attribute title
print $ul->attr("title")."\n"; # OS list

# changing <ul> attribute title
$ul->attr("title", "OS names list");

# find all os names
$ul->find('li')->each(sub {
	my ($node, $index) = @_;
	print "OS #$index: ".$node->text."\n";
});

# we can use precompiled selectors
my $css_parser = HTML5::DOM::CSS->new;
my $selector = $css_parser->parseSelector('li');

# remove OSX from OS
$ul->find($selector)->[2]->remove();

# serialize tree
print $tree->html."\n";

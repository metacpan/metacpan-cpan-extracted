use strict;
use warnings;

use Test::More tests => 1;

use HTML::TreeBuilder::LibXML;

my $tree = HTML::TreeBuilder::LibXML->new;
$tree->parse( '<div><l>this</l> <l>that</l></div>' );
$tree->eof;

is $tree->as_XML, '<html><body><div><l>this</l> <l>that</l></div></body></html>';

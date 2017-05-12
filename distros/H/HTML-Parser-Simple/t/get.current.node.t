use strict;
use warnings;

use HTML::Parser::Simple;

use Test::More 'no_plan';

# -----------------------

my $p = HTML::Parser::Simple -> new;

$p -> parse('<html><body><form><input type="text" name="my_name" value="my_value"></form></body></html>');

is( (ref $p -> current_node)
    , 'Tree::Simple'
    , 'get_current_node() returns an Tree::Simple object');

# This might look like shell script, but it's actually -*- perl -*-
use strict;
use lib 't/';


use TestUtils;
use Test::More qw(no_plan);

use html::content_handler;


my $tree = html::content_handler->new;

$tree->look_down(id => 'name')->replace_content('terrence brannon');
$tree->look_down(id => 'date')->replace_content('5/11/1969');

my $generated_html = 't/html/content_handler.gen';
my $expected_html  = 't/html/content_handler.exp';

ptree $tree, $generated_html;

is(File::Slurp::read_file($generated_html), 
   File::Slurp::read_file($expected_html), 
   "name and date templated correctly");



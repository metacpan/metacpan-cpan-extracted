#!/usr/bin/perl
use HTML::Seamstress;

my $html_file = 'tag_handler.html';
my $tree = HTML::Seamstress->new_from_file($html_file);

$tree->objectify_text;

$tree->dump;

$tree->set_child_content('id' => 'name', 'Chucka Chucka Slim Shady');
$tree->look_down(src => 'fixed_img')->set_sibling_content('NEW CONTENT');

$tree->objectify_text;

warn $tree->as_HTML;


1;

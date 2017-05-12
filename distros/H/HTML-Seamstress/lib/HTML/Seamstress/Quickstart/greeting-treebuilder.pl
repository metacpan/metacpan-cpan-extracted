use strict;
use warnings;

use HTML::TreeBuilder;

my $name   = 'Redd Foxx';
my $number = 887;

my $tree = HTML::TreeBuilder->new_from_file('html/greeting.html');

my $name_elem = $tree->look_down(id => 'name');
$name_elem->delete_content;
$name_elem->push_content($name);

my $number_elem = $tree->look_down(id => 'lucky_number');
$number_elem->delete_content;
$number_elem->push_content($number);


print $tree->as_HTML(undef, ' ');

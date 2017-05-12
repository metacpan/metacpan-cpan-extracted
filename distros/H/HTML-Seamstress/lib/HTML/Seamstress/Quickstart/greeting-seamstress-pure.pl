use strict;
use warnings;

use HTML::Seamstress;

my $name   = 'Redd Foxx';
my $number = 887;

my $tree = HTML::Seamstress->new_from_file('html/greeting.html');


my $elem = $tree->look_down(id => 'name');
$elem->replace_content($name);

$elem = $tree->look_down(id => 'lucky_number');
$elem->replace_content($number);


print $tree->as_HTML(undef, ' ');

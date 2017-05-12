use strict;
use warnings;

use HTML::Seamstress;

my $name    = 'Redd Foxx';
my $number  = 887;

my $tree    = HTML::Seamstress->new_from_file('html/greeting.html');


my %replace = (
  name         => $name,
  lucky_number => $number
 );


$tree->look_down(id => $_)->replace_content($replace{$_})
    for (keys %replace) ;


print $tree->as_HTML(undef, ' ');

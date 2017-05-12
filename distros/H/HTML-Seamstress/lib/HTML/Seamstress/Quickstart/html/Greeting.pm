package html::Greeting;

use strict;
use warnings;

use base qw(HTML::Seamstress);


sub new {
  my $tree  = __PACKAGE__->new_from_file('html/greeting.html');
  $tree;
}


sub process {
  
  my $tree = shift;

  my %replace = (
    name         => 'Jim Rays',
    lucky_number => 222
   );

  $tree->look_down(id => $_)->replace_content($replace{$_})
    for (keys %replace) ;
}


1;

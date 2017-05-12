package html::Greeting;

use strict;
use warnings;

use base qw(Local::Seamstress::Base); # not HTML::Seamstress!
                                     # we need an intermediate base class
                                     # with the comp_root() method so that
                                     # we can get an absolute path to the 
                                     # HTML file... remember this is an
                                     # example where the LOOM is in a 
                                     # different directory to the the HTML
                                     # file it operates on.


sub new {
  my $comp_root = __PACKAGE__->comp_root();
  my $html_file = "$comp_root/greeting.html";
  warn "html_file: $html_file";
  my $tree  = __PACKAGE__->new_from_file($html_file);
  $tree;
}


sub process {
  
  my $tree = shift;

  my %replace = (
    name         => 'Slow Clean Greeting Machine',
    lucky_number => 737
   );

  $tree->look_down(id => $_)->replace_content($replace{$_})
    for (keys %replace) ;
}


1;

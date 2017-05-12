package html::GreetingAbs;

use strict;
use warnings;

use base qw(HTML::Seamstress);

use Data::Dumper;
print Dumper \%INC;

our $html = __PACKAGE__->html(__FILE__ , 'html'); 

{
  last;
  
# The stuff in these braces is not for the first reading of this!

# $html is 
# /ernest/dev/seamstress/lib/HTML/Seamstress/Quickstart/html/GreetingAbs.html
# but the real HTML file is greeting.html not GreetingAbs.html
$html =~ s!Abs!!;

# change Greeting to greeting since file is greeting.html not Greeting.html
$html =~ s!Greeting!greeting!;
}



sub new {
  my $tree  = __PACKAGE__->new_from_file($html);
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

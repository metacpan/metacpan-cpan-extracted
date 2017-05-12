package html::hello_world;
use strict;
use warnings;
use base qw(HTML::Seamstress);

my $tree;

my ($name,$date);
sub new {
$tree = __PACKAGE__->new_from_file('/home/terry/perl/hax/HTML-Seamstress-2.6/ctb/html/hello_world.html');

# content_accessors
$name = $tree->look_down(id => q/name/);
$date = $tree->look_down(id => q/date/);

# highlander_accessors
;

$tree;
}

# content subs

sub name {
   my $self = shift;
   my $content = shift;
   if (defined($content)) {
      $name->content_handler(name => $content);
      return $tree
   } else {
      return $name
   }

}



sub date {
   my $self = shift;
   my $content = shift;
   if (defined($content)) {
      $date->content_handler(date => $content);
      return $tree
   } else {
      return $date
   }

}


# highlander subs


sub tree {
  $tree
}


1;


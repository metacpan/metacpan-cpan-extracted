package %s;

use strict;
use warnings;
use base qw(%s);

our $tree;

sub new {
  $tree = __PACKAGE__->new_from_file(
    __PACKAGE__->comp_root(), 'content_handler.html'
   );
  $tree;
}

1;

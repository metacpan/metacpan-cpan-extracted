package Ftree::Picture;
use strict;
use warnings;
use version; our $VERSION = qv('2.3.41');

use Class::Std::Fast::Storable;
{
  my %file_name_of : ATTR(:name<file_name>);
  my %comment_of : ATTR(:name<comment>);
}

1;

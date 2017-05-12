
package Email::Blaster::Model;

use strict;
use warnings 'all';
use Email::Blaster::Model::Dynamic;
use Email::Blaster::ConfigLoader;


sub connection
{
  my $s = shift;
  warn "$s: Connection";
  $s->SUPER::connection( @_ );
}


#==============================================================================
sub config
{
  Email::Blaster::ConfigLoader->load()
}# end config()

1;# return true:


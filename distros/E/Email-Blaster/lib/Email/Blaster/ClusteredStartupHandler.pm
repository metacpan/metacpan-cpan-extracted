
package Email::Blaster::ClusteredStartupHandler;

use strict;
use warnings 'all';
use base 'Email::Blaster::EventHandler';
use Email::Blaster;


#==============================================================================
sub run
{
  my ($s, $event) = @_;
  
  my $blaster = Email::Blaster->current;
  
  my $servers = $blaster->memd->get("connected_servers") || [ ];
  push @$servers, $blaster->config->hostname;
  $blaster->memd->set("connected_servers", $servers);
  $blaster->memd->set(
    # An indicator of this hostname's active status:
    "Connected." . $blaster->config->hostname,
    # True:
    1,
    # Expires 60 seconds from now:
    60
  );
}# end run()

1;# return true:


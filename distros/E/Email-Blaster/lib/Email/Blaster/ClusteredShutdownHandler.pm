
package Email::Blaster::ClusteredShutdownHandler;

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
  @$servers = grep { $_ ne $blaster->config->hostname } @$servers;
  $blaster->memd->set("connected_servers", $servers);
  
  # Remove our active status indicator:
  $blaster->memd->delete(
    "Connected." . $blaster->config->hostname
  );
}# end run()

1;# return true:


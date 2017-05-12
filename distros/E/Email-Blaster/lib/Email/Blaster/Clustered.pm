
package Email::Blaster::Clustered;

use strict;
use warnings 'all';
use base 'Email::Blaster';
use Cache::Memcached;

local $Email::Blaster::InstanceClass = __PACKAGE__;


#==============================================================================
sub new
{
  my ($class) = shift;
  
  my $s = $class->SUPER::new( @_ );
  
  # Just set up our memcached connection and defer to our super:
  $s->{memd} = Cache::Memcached->new({
    'servers' => [ $s->config->cluster->servers ],
    'debug'   => $s->config->is_testing,
    'compress_threshold' => 10_000,
    'namespace' => 'EmailBlaster',
  });
  
  return $s;
}# end run()


#==============================================================================
sub wait_cycle
{
  my ($s, $running, $processed) = @_;
  
  $s->SUPER::wait_cycle( $running, $processed );
  
  # Let everyone know that we're still active...:
  $s->memd->set(
    # An indicator of this hostname's active status:
    "Connected." . $s->config->hostname,
    # True:
    1,
    # Expires 60 seconds from now:
    60
  );
}# end wait_cycle()


#==============================================================================
sub memd { shift->{memd} }


#==============================================================================
sub find_new_transmission
{
  my ($s) = @_;
  
  $s->memd->set(
    # An indicator of this hostname's active status:
    "Connected." . $s->config->hostname,
    # True:
    1,
    # Expires 60 seconds from now:
    60
  );
  my $servers = $s->memd->get("connected_servers");
  my $param = join ",", (1,
    map {"'$_'"}
      # Only the "Active" servers:
      grep { $s->memd->get("Connected.$_") }
        @$servers
  );
  
  my $sth = Email::Blaster::Transmission->db_Main->prepare(<<"SQL");
SELECT *
FROM transmissions
WHERE is_queued = 1
AND (
  is_started = 0
)
OR (
  -- Clean up after another (possibly offline) server:
  is_started = 1
  AND is_completed = 0
  AND blaster_hostname NOT IN ( $param )
)
OR (
  -- Clean up after ourselves, if we rebooted:
  is_started = 1
  AND is_completed = 0
  AND blaster_hostname = ?
)
ORDER BY queued_on DESC
LIMIT 0, 1
SQL
  $sth->execute( $s->config->hostname );
  return unless my ($trans) = Email::Blaster::Transmission->sth_to_objects( $sth );
  
  return $trans;
}# end find_new_transmission()

1;# return true:

__END__

=pod

=head1 NAME

Email::Blaster::Clustered - Clustered email blaster.

=head1 DESCRIPTION

Email::Blaster::Clustered is used by L<sbin/email-blaster-clustered.pl>.

=head1 SUPPORT

Visit L<http://www.devstack.com/contact/> or email the author at <jdrago_999@yahoo.com>

Commercial support and installation is available.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>
 
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by John Drago

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


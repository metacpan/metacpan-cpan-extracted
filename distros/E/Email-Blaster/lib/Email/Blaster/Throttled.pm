
package Email::Blaster::Throttled;

use strict;
use warnings 'all';
use base 'Email::Blaster';
use Email::Blaster::Sendlog;
use POSIX 'ceil';
use Time::HiRes qw( usleep gettimeofday );
use HTTP::Date 'time2iso';

local $Email::Blaster::InstanceClass = __PACKAGE__;


#==============================================================================
sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  
  $s->_load_class( $s->config->maillog_watcher );
  $s->{maillog_watcher} = $s->config->maillog_watcher->new( );
  
  return $s;
}# end new()


#==============================================================================
sub maillog_watcher { shift->{maillog_watcher} }


#==============================================================================
sub run
{
  my ($s, $domain, $hourly_limit) = @_;
  
  # For quick reference later:
  $s->{domain} = $domain;
  $s->{hourly_limit} = $hourly_limit;
  
  # Wait until we have some sendlogs for our domain:
  while( $s->continue_running )
  {
    warn "Looking for sendlogs to '@{[ $s->domain ]}'...\n";
    my @sendlogs = $s->find_sendlogs();
    unless( @sendlogs )
    {
      sleep(5);
      next;
    }# end unless()
    
    # We found some sendlogs - send them...slowly:
    my $delay = 3600 / $s->hourly_limit * 1000000;
    warn "Delay for $domain: $delay\n";
    
    my $last_time = gettimeofday();
    foreach my $sendlog ( @sendlogs )
    {
      my $queued_as = $s->send_message(
        $sendlog,
        $sendlog->transmission
      );
      $sendlog->queued_as( $queued_as );
      $sendlog->is_sent( 1 );
      $sendlog->sent_on( time2iso() );
      $sendlog->update;
      
      # Wait until the message has been processed by our MTA:
      my $is_successful = $s->maillog_watcher->watch_maillog(
        $s->config->maillog_path,
        $queued_as
      );
      $sendlog->is_successful( $is_successful );
      $sendlog->update();
      
      # How much time has passed since our last message was sent?:
      my $diff = gettimeofday() - $last_time;

      # We might have some time left to sleep through:
      if( $diff < $delay )
      {
        usleep( $delay - $diff );
      }# end if()
      
      # Mark the time that we finished with this sendlog:
      $last_time = gettimeofday();
    }# end foreach()
  }# end while()
}# end run()


#==============================================================================
sub watch_maillog
{
  my ($s, $queued_as) = @_;
  
  my $path = $s->config->maillog_path;
  warn "Waiting for the message ($queued_as) to go out...\n";
  while( 1 )
  {
    my $wanted = `grep $queued_as $path*`;
    unless( $wanted =~ m/\sstatus\=sent\s/i )
    {
      usleep(500000);
      next;
    }# end until()
    
    # We have sent it:
    last;
  }# end while()
}# end watch_maillog()


#==============================================================================
sub domain        { shift->{domain}       }
sub hourly_limit  { shift->{hourly_limit} }


#==============================================================================
sub find_sendlogs
{
  my ($s) = @_;
  
  my $sth = Email::Blaster::Sendlog->db_Main->prepare(<<"SQL");
SELECT sendlogs.*
FROM sendlogs
  INNER JOIN transmissions
    ON transmissions.transmission_id = sendlogs.transmission_id
WHERE sendlogs.throttled_domain = ?
AND sendlogs.is_sent = 0
ORDER BY transmissions.queued_on ASC
SQL
  $sth->execute( $s->domain );
  
  return Email::Blaster::Sendlog->sth_to_objects( $sth );
}# end find_sendlogs()

1;# return true:


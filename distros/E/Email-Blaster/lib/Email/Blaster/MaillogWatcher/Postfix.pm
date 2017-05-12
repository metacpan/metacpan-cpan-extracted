
package Email::Blaster::MaillogWatcher::Postfix;

use strict;
use warnings 'all';
use base 'Email::Blaster::MaillogWatcher';
use Time::HiRes 'usleep';


#==============================================================================
sub watch_maillog
{
  my ($s, $maillog_path, $queued_as) = @_;
  
  warn "Waiting for the message ($queued_as) to go out...\n";
  while( 1 )
  {
    my $wanted = `grep $queued_as $maillog_path*`;
    my $status;
    
    unless( ($status) = $wanted =~ m/status\=(sent|bounced|deferred)\s+/io )
    {
      usleep(500000);
      next;
    }# end unless()
    
    # We have sent it:
    return lc($status) eq 'sent';
  }# end while()
}# end watch_maillog()

1;# return true:


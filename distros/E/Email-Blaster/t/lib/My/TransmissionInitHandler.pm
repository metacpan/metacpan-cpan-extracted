
package My::TransmissionInitHandler;

use strict;
use warnings 'all';
use base 'Email::Blaster::TransmissionInitHandler';
use Email::Blaster::Transmission;
use My::Contact;


#==============================================================================
sub run
{
  my ($s, $event) = @_;
  
  my $trans = Email::Blaster::Transmission->retrieve( $event->transmission_id );
  my %emails = ( );
  
  my %throttled = (
    map { $_->domain => 1 }
      $trans->config->throttled
  );
  
  RECIP: foreach my $recip ( $trans->recipients )
  {
    if( $recip->contact_list_id )
    {
      my $sth = $recip->db_Main->prepare(<<"SQL");
SELECT contacts.*
FROM contacts
  INNER JOIN contact_subscriptions
    ON contact_subscriptions.contact_id = contacts.contact_id
WHERE contact_subscriptions.contact_list_id = ?
AND contacts.is_subscribed = 1
SQL
      $sth->execute( $recip->contact_list_id );
      CONTACT: foreach my $contact ( My::Contact->sth_to_objects( $sth ) )
      {
        next CONTACT if $emails{ $contact->email }++;
        my ($domain) = grep { $contact->email =~ m/\@\Q$_\E$/i } keys(%throttled);
        $trans->add_to_sendlogs(
          contact_id        => $contact->id,
          first_name        => $contact->first_name,
          last_name         => $contact->last_name,
          email             => $contact->email,
          is_sent           => 0,
          assigned_to_host  => $trans->config->hostname,
          throttled_domain  => $domain || '',
        );
      }# end foreach()
    }
    elsif( $recip->contact_id )
    {
      my $contact = My::Contact->retrieve( $recip->contact_id )
        or next RECIP;
      next RECIP if $emails{ $contact->email }++;
      my ($domain) = grep { $contact->email =~ m/\@\Q$_\E$/i } keys(%throttled);
      $trans->add_to_sendlogs(
        contact_id        => $contact->id,
        first_name        => $contact->first_name,
        last_name         => $contact->last_name,
        email             => $contact->email,
        is_sent           => 0,
        assigned_to_host  => $trans->config->hostname,
        throttled_domain  => $domain || '',
      );
    }# end if()
  }# end foreach()
}# end run()


#==============================================================================

1;# return true:


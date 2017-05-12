#!/usr/bin/perl -w

use strict;
use warnings 'all';
use My::Contact;
use My::Contact::List;
use Email::Blaster::Transmission;
use Email::Blaster::Recipient;
use HTTP::Date 'time2iso';


# Create a few contacts:
$_->delete foreach My::Contact->retrieve_all;
my @contacts = ( );
for( 1...100 )
{
  push @contacts, My::Contact->create(
    first_name    => "TestFirst$_",
    last_name     => "TestLast$_",
    email         => $_ % 2 ? "email$_\@aol.com" : "email$_\@test.com",
    # The first contact will not be subscribed.
    is_subscribed => $_ == 1 ? 0 : 1,
  );
}# end for()

# Set up a couple contact lists:
$_->delete foreach My::Contact::List->retrieve_all;
for( 1...2 )
{
  my $outer = $_;
  my $list = My::Contact::List->create(
    contact_list_name => "ContactList$_"
  );
  
  # Make some subscriptions:
  for( 0...$#contacts )
  {
    next if $_ % $outer;
    $contacts[$_]->add_to_contact_subscriptions(
      contact_list_id => $list->id,
    );
  }# end for()
}# end for()

# Make a transmission:
$_->delete foreach Email::Blaster::Transmission->retrieve_all; 
my $trans = Email::Blaster::Transmission->create(
  from_name     => "Test From",
  from_address  => 'test@from.com',
  reply_to      => 'reply-to@from.com',
  subject       => "Test Subject",
  content       => "Test email from YOU!<br>"x80,
  content_type  => 'text/html',
  is_started    => 0,
  is_completed  => 0,
);

# Add some recipient records:
$_->delete foreach Email::Blaster::Recipient->retrieve_all;
foreach my $list ( My::Contact::List->retrieve_all )
{
  $trans->add_to_recipients(
    contact_list_id => $list->id,
  );
}# end foreach()

# Mark the transmission as "queued":
$trans->is_queued( 1 );
$trans->queued_on( time2iso() );
$trans->update();



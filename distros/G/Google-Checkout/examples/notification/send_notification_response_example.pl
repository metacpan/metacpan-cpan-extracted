#!/usr/bin/perl -w
use strict;
 
use Google::Checkout::General::GCO;

#--
#-- The following shows how to use NotificationResponseXmlWriter. When
#-- a notifcation arrive, Checkout expects a response to indicate
#-- that the notification has been accepted. The following shows what
#-- partner's code should do in minimum to return a valid response back to
#-- Checkout. Note the use of the NotificationResponseXmlWriter is abstracted
#-- away from the user. send_notification_response takes care of creating
#-- the NotificationResponseXmlWriter object and sends it back to Checkout.
#--
Google::Checkout::General::GCO->new->send_notification_response;

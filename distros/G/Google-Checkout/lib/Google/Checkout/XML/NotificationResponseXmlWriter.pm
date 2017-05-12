package Google::Checkout::XML::NotificationResponseXmlWriter;

#--
#-- Always return a valid response XML for the various Google checkout notifications.
#--

use strict;
use warnings;

use Google::Checkout::XML::Writer;
use Google::Checkout::XML::Constants;
our @ISA = qw/Google::Checkout::XML::Writer/;

sub new 
{
  my ($class, %args) = @_;
  
  delete $args{root};

  my $self = $class->SUPER::new(%args);

  my $xml_schema = $args{gco}->reader() ?
                   $args{gco}->reader()->get(Google::Checkout::XML::Constants::XML_SCHEMA) :
                   $args{gco}->{__xml_schema};

  $self->add_element(name => Google::Checkout::XML::Constants::NOTIFICATION_ACKNOWLEDGMENT,
                     attr => [xmlns => $xml_schema]);

  return bless $self => $class;
}

1;

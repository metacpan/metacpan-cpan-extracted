package Google::Checkout::XML::CommandXmlWriter;

#--
#-- Writes a generic command XML.
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/make_xml_safe/;

use Google::Checkout::XML::Writer;
our @ISA = qw/Google::Checkout::XML::Writer/;

sub new 
{
  my ($class, %args) = @_;

  delete $args{root};

  my $self = $class->SUPER::new(%args);

  my $xml_schema = '';
  my $currency_supported = '';

  if ($args{gco}->reader()) {

    my $reader = $args{gco}->reader();
    
    $xml_schema = $reader->get(Google::Checkout::XML::Constants::XML_SCHEMA);
    $currency_supported = $reader->get(Google::Checkout::XML::Constants::CURRENCY_SUPPORTED);

  } else {
    $xml_schema = $args{gco}->{__xml_schema};
    $currency_supported = $args{gco}->{__currency_supported};
  }

  $self->add_element(name => $args{command}->get_name,
                     attr => [xmlns => $xml_schema,
                              Google::Checkout::XML::Constants::ORDER_NUMBER,
                                $args{command}->get_order_number]);

  if ($args{command}->get_amount)
  {
    $self->add_element(close => 1,
                       name => Google::Checkout::XML::Constants::AMOUNT, 
                       data => $args{command}->get_amount,
                       attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY,
                                $currency_supported]);
  }
  
  if ($args{command}->get_reason)
  {
    $self->add_element(close => 1,
                       name => Google::Checkout::XML::Constants::REASON,
                       data => $args{command}->get_reason);
  }

  return bless $self => $class;
}

1;

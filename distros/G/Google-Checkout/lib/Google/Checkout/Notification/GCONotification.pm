package Google::Checkout::Notification::GCONotification;

=head1 NAME

Google::Checkout::Notification::GCONotification

=head1 DESCRIPTION

Generic notification class. You normally do not have to use 
this class directly.

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=cut

#--
#-- Parent class of various *Notification classes
#--

use strict;
use warnings;

use XML::Simple;
use Google::Checkout::General::Error;
use Google::Checkout::XML::Constants;

sub new 
{
  my ($class, %args) = @_;

  my $self = { xml => $args{xml} || '' };

  eval { $self->{data} = XMLin($self->{xml}) if $self->{xml} };

  return Google::Checkout::General::Error->new(-1, "XML Error: $@") if $@;

  return bless $self => $class;
}

sub get_xml 
{
  my ($self) = @_;
 
  return $self->{xml}; 
}

sub set_xml
{
  my ($self, $xml) = @_;

  my $need_reload = 0;

  if ($self->{xml})
  {
    if ($xml && $xml ne $self->{xml})
    {
      $self->{xml} = $xml;
      $need_reload = 1;
    }
  }
  else
  {
    $self->{xml} = $xml;
    $need_reload = 1;
  }

  eval { $self->{data} = XMLin($self->{xml}) 
    if ($need_reload && $self->{xml}) };

  return $@ ? Google::Checkout::General::Error->new(
                $Google::Checkout::General::Error::ERRORS{INVALID_XML}->[0],
                $Google::Checkout::General::Error::ERRORS{INVALID_XML}->[1] . ": $@") : 1;
}

sub get_data 
{
  my ($self) = @_;
 
  return $self->{data} || {};
}

#--
#-- The following 3 API are here because they are common to all notifications
#--
sub get_order_number  
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::ORDER_NUMBER} || ''; 
}

sub get_serial_number 
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::SERIAL_NUMBER} || ''; 
}

sub get_timestamp     
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::TIMESTAMP} || ''; 
}

1;

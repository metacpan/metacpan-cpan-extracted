package Google::Checkout::General::Error;

=head1 NAME

Google::Checkout::General::Error

=head1 SYNOPSIS

  use Google::Checkout::General::Error;

  my $error = Google::Checkout::General::Error->new(-1, "Error message");
  print "$error\n";

=head1 DESCRIPTION

Module to manage errors. All errors are handled by this object.

=over 4

=item new ERROR_CODE, ERROR_STRING

Constructor. Takes an error code and string.  The '""' string operator 
is overloaded so it's possible to just 'print $error'.

=item code

Returns the error code.

=item string

Returns the error string.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

=cut

#--
#-- Error object. All errors are reported through this object.
#--

use strict;
use warnings;

use overload '""' => sub { return $_[0]->code . ': ' . $_[0]->string };

#--
#-- A list of error code and description
#--
our %ERRORS = (

MISSING_ORDER_NUMBER      => [1000, "Missing order number"],
MISSING_CARRIER           => [1001, "Missing carrier"],
MISSING_TRACKING_NUMBER   => [1002, "Missing tracking number"],
MISSING_MESSAGE           => [1003, "Missing message"],
MISSING_URL               => [1004, "Missing URL"],
MISSING_CART              => [1005, "Missing cart"],
MISSING_ELEMENT_NAME      => [1006, "Missing element name"],
MISSING_ITEM_NAME         => [1007, "Missing item name"],
MISSING_ITEM_DESCRIPTION  => [1008, "Missing item description"],
MISSING_ITEM_PRICE        => [1009, "Missing item price"],
MISSING_ITEM_QUANTITY     => [1010, "Missing item quantity"],
MISSING_CONFIG_ITEM       => [1011, "Missing configration option"],
INVALID_XML               => [2000, "Invalid XML"],
INVALID_VALUE             => [2001, "Invalid value"],
INVALID_SHIPPING_METHOD   => [2002, "Invalid shipping method"],
INVALID_CARRIER           => [2003, "Invalid carrier"],
INVALID_DATE_STRING       => [2004, "Invalid date string"],
INVALID_MERCHANT_ID       => [2005, "Invalid merchant ID"],
INVALID_MERCHANT_KEY      => [2006, "Invlaid merchant key"],
INVALID_COMMAND           => [2007, "Invalid command"],
REQUIRE_REASON_FOR_CANCEL => [3000, "Require reason for cancel"],
REQUIRE_REASON_FOR_REFUND => [3001, "Require reason for refund"]

);

sub new 
{
  my ($class, $code, $string) = @_;

  return bless { code   => $code   || -1, 
                 string => $string || ''} => $class;
}

sub code   
{ 
  my ($self) = @_;

  return $self->{code};
}

sub string 
{ 
  my ($self) = @_;

  return $self->{string};
}

1;

package Marketplace::Ebay::Response;

use 5.010001;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use DateTime;
use DateTime::Format::ISO8601;
use namespace::clean;

=head1 NAME

Marketplace::Ebay::Response - Generic response parser for ebay api calls

=head1 SYNOPSIS

  my $ebay = Marketplace::Ebay->new(...);
  my $res = $ebay->api_call('GeteBayOfficialTime', {});
  if (defined($res)) {
      my $parsed = Marketplace::Ebay::Response->new(struct => $res);
      print "OK" if $parsed->is_success;
      if (defined $parsed->fees) {
          print "Total fees are " . $parsed->total_fees;
      }
  }

=head1 ACCESSORS

The constructor asks for a C<struct> key where the C<api_call> return
value should be saved. This module provide some convenience routines.

=head2 struct

The XML data deserialized into a perl hashref. It should be the return
value of L<Marketplace::Ebay>'s api_call, if defined.

=cut

has struct => (is => 'ro',
               isa => HashRef,
               required => 1);


=head1 SHORTCUTS

Given that we can't know beforehand which kind of response we have,
depending on the API version and on the used XSD, the convention for
all these shortcuts is to return undef when we can't reliably provide
an answer (this is true for booleans as well, which return 0 or 1).
C<undef> means that we don't know, so you're recommend to inspect the
C<struct> yourself to make sense of the unknown, if you're expecting
something.

=head2 is_success

Boolean.

=head2 version

The API version of the remote site.

=head2 item_id

The ItemID (if any) of the response

=head2 ack

The Ack key of the response (acknowledge)

=head2 start_time

The StartTime (if any) of the response (auction start time)

=head2 start_time_dt

The StartTime (if any) of the response (auction start time) as a
DateTime object.

=head2 end_time

The EndTime (if any) of the response (auction end time)

=head2 end_time_dt

The EndTime (if any) as a DateTime object

=head2 timestamp

The timestamp of the response.

=head2 timestamp_dt

The timestamp of the response as a DateTime object.

=head2 errors

The unmodified Errors structure

=head2 errors_as_string

A single string with the errors found in the response. If you need
more detailed info, you have to inspect C<errors> yourself.

=head2 is_failure

Return true if the acknowledge says C<Failure> or C<PartialFailure>.

=head2 is_warning

Return true if the acknowledge says C<Warning>.

=head2 request_ok

Return true if the response was successful or just with warnings.

=head2 sku

The SKU key of the response data.

=cut

sub ack {
    return shift->_get_struct_key('Ack');
}

sub is_success {
    my $self = shift;
    my $ack = $self->ack;
    return unless $ack;
    if ($ack eq 'Success') {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_warning {
    my $self = shift;
    my $ack = $self->ack;
    return unless $ack;
    if ($ack eq 'Warning') {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_failure {
    my $self = shift;
    my $ack = $self->ack;
    return unless $ack;
    if ($ack eq 'Failure' or $ack eq 'PartialFailure') {
        return 1;
    }
    else {
        return 0;
    }
}

sub request_ok {
    my $self = shift;
    if ($self->is_success || $self->is_warning) {
        return 1;
    }
    else {
        return 0;
    }
}

sub version {
    return shift->_get_struct_key('Version');
}

sub item_id {
    return shift->_get_struct_key('ItemID');
}

sub start_time {
    return shift->_get_struct_key('StartTime');
}

sub start_time_dt {
    return shift->_dt_from_string('start_time');
}

sub end_time {
    return shift->_get_struct_key('EndTime');
}

sub end_time_dt {
    return shift->_dt_from_string('end_time');
}

sub _dt_from_string {
    my ($self, $method) = @_;
    if (my $string = $self->$method) {
        return DateTime::Format::ISO8601->parse_datetime($string);
    }
    return;
}

sub sku {
    shift->_get_struct_key('SKU');
}


sub timestamp {
    return shift->_get_struct_key('Timestamp');
}

sub timestamp_dt {
    return shift->_dt_from_string('timestamp');
}


sub errors {
    return shift->_get_struct_key('Errors');
}

sub _get_struct_key {
    my ($self, $key) = @_;
    my $struct = $self->struct;
    if (exists $struct->{$key}) {
        return $struct->{$key};
    }
    return;
}

sub errors_as_string {
    my $self = shift;
    if (my $errors = $self->errors) {
        if (ref($errors) eq 'ARRAY') {
            my @errors;
            my $count = 0;
            foreach my $error (@$errors) {
                $count++;
                my @err_details = ($count . '.');
                foreach my $key (qw/SeverityCode
                                    ErrorClassification
                                    ErrorCode
                                    ShortMessage
                                    LongMessage/) {
                    if (exists $error->{$key}) {
                        if (defined $error->{$key}) {
                            push @err_details, $error->{$key};
                        }
                    }
                }
                push @errors, join(' ', @err_details);
            }
            return join("\n", @errors) . "\n";
        }
        else {
            die "Array expected! Please fix this code";
        }
    }
    return;
}

=head2 fees

The fees detail returned by an add_item (or equivalent) call.

=head2 total_listing_fee

As per documentation: The total cost of all listing features is found
in the Fees container whose Name is ListingFee. This does not reflect
the full cost of listing and selling an item on eBay, for the Final
Value Fee cannot be calculated by eBay until the listing has ended,
when a final sale price is known. Total cost is then the sum of the
Final Value Fee and the Fee corresponding to ListingFee.

L<http://developer.ebay.com/DevZone/guides/ebayfeatures/Development/Listing-Fees.html>

=cut

sub fees {
    my $self = shift;
    my $struct = $self->struct;
    if (exists $struct->{Fees}) {
        if (exists $struct->{Fees}->{Fee}) {
            my $fees = $struct->{Fees}->{Fee};
            if ($fees && @$fees) {
                my %out;
                FEE: foreach my $fee (@$fees) {
                      # we hope this structure is stable...
                      foreach my $k (qw/Name Fee/) {
                          unless (exists $fee->{$k}) {
                              warn "$k not found in fee:" . Dumper($fee);
                              next FEE;
                          }
                      }
                      $out{$fee->{Name}} ||= 0;
                      $out{$fee->{Name}} += $fee->{Fee}->{_};
                  }
                foreach my $k (keys %out) {
                    my $float = $out{$k};
                    $out{$k} = sprintf('%.2f', $float);
                }
                return \%out;
            }
        }
    }
    return;
}

sub total_listing_fee {
    my $self = shift;
    if (my $fees = $self->fees) {
        if (exists $fees->{ListingFee}) {
            return $fees->{ListingFee};
        }
    }
    return;
}


1;

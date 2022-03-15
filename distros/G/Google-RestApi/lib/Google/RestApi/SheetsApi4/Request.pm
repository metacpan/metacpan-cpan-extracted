package Google::RestApi::SheetsApi4::Request;

our $VERSION = '1.0.2';

use Google::RestApi::Setup;

use Hash::Merge ();
use List::MoreUtils qw( first_index );
use Storable ();

sub submit_requests { LOGDIE "Pure virtual function 'submit_requests' must be overridden"; }

sub batch_requests {
  my $self = shift;

  my %request = @_;

  $self->{requests} ||= [];
  my $requests = $self->{requests};

  if (%request) {
    delete $self->{requests_response};  # any previous responses are no longer valid.
    push(@$requests, \%request) if !$self->merge_request(\%request);
  }

  return @$requests;
}

sub merge_request {
  my $self = shift;

  state $check = compile(HashRef);
  my ($request) = $check->(@_);

  my $requests = $self->{requests} or return;
  my ($index) = first_index {
    $self->_can_merge($request, $_);
  } @$requests;
  return if $index < 0;

  my $other_request = $requests->[$index];

  my $key = (keys %$request)[0];
  my $fields = $request->{$key}->{fields};
  my $other_fields = $other_request->{$key}->{fields};

  my %fields;
  %fields = map { $_ => 1 } split(',', $fields), split(',', $other_fields)
    if $fields && $other_fields;
  $other_request = Hash::Merge::merge($request, $other_request);
  $other_request->{$key}->{fields} = join(',', sort keys %fields) if %fields;

  $requests->[$index] = $other_request;

  return $other_request;
}

sub _can_merge {
  my $self = shift;

  my ($request, $other_request) = @_;
  my $key = (keys %$request)[0];
  my $other_key = (keys %$other_request)[0];

  return if $key ne $other_key;
  return if $key =~ /^(deleteProtected|deleteNamed|deleteEmbeded)/;

  if ($key =~ /^updateProtected/) {
    my $id = $request->{$key}->{protectedRangeId} or return;
    my $other_id = $other_request->{$key}->{protectedRangeId} or return;
    return $id == $other_id;
  }

  if ($key =~ /^updateNamedRange/) {
    my $id = $request->{$key}->{namedRange}->{namedRangeId} or return;
    my $other_id = $other_request->{$key}->{namedRange}->{namedRangeId} or return;
    return $id == $other_id;
  }

  if ($key =~ /^updateEmbededObject/) {
    my $id = $request->{$key}->{objectId} or return;
    my $other_id = $other_request->{$key}->{objectId} or return;
    return $id == $other_id;
  }

  return 1;
}

sub requests_response_from_api {
  my $self = shift;

  # we didn't ask for any requests, nothing more to do.
  return if @_ && !$self->{requests};

  state $check = compile(ArrayRef, { optional => 1 });
  my ($requests) = $check->(@_);
  return $self->{requests_response} if !$requests;

  # strip off a response for each request made.
  $self->{requests_response} = [];
  push(@{ $self->{requests_response} }, shift @$requests)
    for (1..scalar @{ $self->{requests} });

  # don't store the original requests now that they've been done.
  delete $self->{requests};

  return $self->{requests_response};
}

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request - A base class to build Google API's batchRequest.

=head1 DESCRIPTION

A Request is a lightweight object that is used to collect and then
submit a number of batch requests such as formatting, spreadsheet
properties, worksheet properties etc.

Other classes in this api derive from this object and its child
objects. You would not normally have to interact with this object
directly as it is already built in to the other classes in this
api. It is documented here for background understanding.

Batch requests are formulated and queued up to be submitted later
via 'submit_requests'. This class hierarchy encapsulates the
tedious work of constructing the complex, deep hashes required for
cell formatting or setting various properties.

 Spreadsheet: Derives from Request::Spreadsheet.
 Worksheet: Derives from Request::Spreadsheet::Worksheet.
 Range: Derives from Request::Spreadsheet::Worksheet::Range.

A Spreadsheet object can only submit requests that have to do with
spreadsheets. A Worksheet object can submit requests that have to
do with worksheets, and also for parent spreadsheets. A Range object
can submit requests that have to do with ranges, worksheets, and
spreadsheets.

In some cases, multiple calls for the same-named request can be
merged into a single request. For example $range->bold()->blue()->center()
targets three Google API requests of the same name: 'repeatCell'.
Instead of sending three small 'repeatCell' requests, these are
all merged together into one 'repeatCell' request for efficiency.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item batch_requests(%request);

Returns all the queued requests if none is passed, or adds the passed
request to the queue. A request may be merged into an already-existing
request of the same name.

=item submit_requests(%args);

This is a pure virtual function that must be overridden in the derived
class. The derived class must decide what to do when the queued requests
are ready to be sumitted. It must eventually pass the requests to the
parent SheetsApi4 object.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

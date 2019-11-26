package Google::RestApi::SheetsApi4::Request;

use strict;
use warnings;

our $VERSION = '0.4';

use 5.010_000;

use autodie;
use Hash::Merge;
use List::MoreUtils qw(first_index);
use Storable qw(dclone);
use Type::Params qw(compile compile_named);
use Types::Standard qw(ArrayRef HashRef);
use YAML::Any qw(Dump);

no autovivification;

do 'Google/RestApi/logger_init.pl';

sub submit_requests { die "Pure virtual function 'submit_requests' must be overridden"; }

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

  keys %$request;   # reset each.
  my ($key) = each(%$request);
  return if !$self->_can_merge($key, $request->{$key});

  my $requests = $self->{requests} or return;
  my $index = first_index {
    keys %$_;
    my ($other_key) = each(%$_);
    $key eq $other_key;
  } @$requests;
  return if $index < 0;

  my $fields = $request->{$key}->{fields};
  my $other_request = $requests->[$index];
  my $other_fields = $other_request->{$key}->{fields};

  my %fields;
  %fields = map { $_ => 1 } split(',', $fields), split(',', $other_fields)
    if $fields && $other_fields;
  $requests->[$index] = Hash::Merge::merge($request, $other_request);
  $other_request = $requests->[$index];
  $other_request->{$key}->{fields} = join(',', sort keys %fields) if %fields;

  return $other_request;
}

# this is not private to the class, it's private to the overall framework.
sub requests_response {
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

# TODO: figure out what can be merged and what can't.
# need a decent way to quickly analyze the request.
sub _can_merge {
  my $self = shift;
  my ($key, $request) = @_;
  return 1 if $key =~ /^(repeatCell|mergeCells|updateBorders)$/;
  return;
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

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

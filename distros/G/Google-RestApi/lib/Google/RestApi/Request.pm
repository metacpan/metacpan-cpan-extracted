package Google::RestApi::Request;

our $VERSION = '2.2.2';

use Google::RestApi::Setup;

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

sub merge_request { return; }

sub requests_response_from_api {
  my $self = shift;

  # we didn't ask for any requests, nothing more to do.
  return if @_ && !$self->{requests};

  state $check = signature(positional => [ArrayRef, { optional => 1 }]);
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

Google::RestApi::Request - A base class for building Google API batchUpdate requests.

=head1 DESCRIPTION

A Request is a lightweight base class that provides generic batch
request queuing and response infrastructure. It is used by both
Google Sheets (via SheetsApi4::Request) and Google Docs (via
DocsApi1::Document) to collect requests and distribute responses.

Batch requests are formulated and queued up to be submitted later
via 'submit_requests'. Derived classes must override submit_requests
to implement the actual API call.

The default merge_request returns false (no merging). Sheets overrides
this with its own merge logic for combining compatible requests.

=head1 SUBROUTINES

=over

=item batch_requests(%request);

Returns all the queued requests if none is passed, or adds the passed
request to the queue. A request may be merged into an already-existing
request of the same name if merge_request returns true.

=item merge_request(\%request);

Hook for derived classes to merge a new request with an existing one.
Returns false by default (no merging). Sheets overrides this to merge
compatible formatting requests.

=item submit_requests(%args);

This is a pure virtual function that must be overridden in the derived
class. The derived class must decide what to do when the queued requests
are ready to be submitted.

=item requests_response_from_api(\@responses);

Strips off responses from the API response array corresponding to the
requests that were submitted. Called after submit_requests to distribute
responses to the correct requestor.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

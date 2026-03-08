package Google::RestApi::SheetsApi4::Request;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

use Hash::Merge ();
use List::MoreUtils qw( first_index );
use Storable ();

use parent "Google::RestApi::Request";

sub merge_request {
  my $self = shift;

  state $check = signature(positional => [HashRef]);
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

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request - Build Google Sheets API batchRequests with merge support.

=head1 DESCRIPTION

Inherits from L<Google::RestApi::Request> and adds Sheets-specific
request merging logic. Multiple calls for the same-named request
(e.g. repeatCell) can be merged into a single request for efficiency.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item merge_request(\%request);

Attempts to merge the given request with an existing queued request
of the same type. For example, $range->bold()->blue()->center()
targets three 'repeatCell' requests that get merged into one.

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

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

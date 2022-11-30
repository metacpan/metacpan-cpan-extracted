package Google::RestApi::SheetsApi4::Spreadsheet;

our $VERSION = '1.0.4';

use Google::RestApi::Setup;

use Cache::Memory::Simple ();

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Worksheet';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie';

use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet";

sub new {
  my $class = shift;

  my $qr_id = SheetsApi4->Spreadsheet_Id;
  my $qr_uri = SheetsApi4->Spreadsheet_Uri;
  # pass one of id/name/title/uri and this will work out the others.
  state $check = compile_named(
    sheets_api => HasApi,
    # https://developers.google.com/sheets/api/guides/concepts
    id         => StrMatch[qr/^$qr_id$/], { optional => 1 },
    name       => Str, { optional => 1 },
    title      => Str, { optional => 1 },
    uri        => StrMatch[qr|^$qr_uri/$qr_id/?|], { optional => 1 },
    cache_seconds => PositiveOrZeroNum, { default => 5 },
  );
  my $self = $check->(@_);

  $self = bless $self, $class;
  $self->{name} ||= $self->{title};
  delete $self->{title};

  $self->{id} || $self->{name} || $self->{uri} or LOGDIE "At least one of id, name, or uri must be specified";

  return $self;
}

# take the passed uri from worksheet/range/rangegroup etc, and tack on the spreadsheet id,
# then pass it up to G::R::SheetsApi4 which will tack on the endpoint.
sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str, { default => '' },
    _extra_ => slurpy Any,             # we'll just pass the params/content etc up for processing.
  );
  my $p = named_extra($check->(@_));
  $p->{uri} = $self->spreadsheet_id() . $p->{uri};
  return $self->sheets_api()->api(%$p);
}

# work out the id from the uri or the name/title.
sub spreadsheet_id {
  my $self = shift;

  if (!$self->{id}) {
    if ($self->{uri}) {
      my $qr_id = SheetsApi4->Spreadsheet_Id;
      my $qr_uri = SheetsApi4->Spreadsheet_Uri;
      ($self->{id}) = $self->{uri} =~ m|^$qr_uri/($qr_id)|;   # can end with '/edit'
      LOGDIE "Unable to extract a sheet id from uri" if !$self->{id};
      DEBUG("Got sheet ID '$self->{id}' via URI '$self->{uri}'.");
    } else {
      my @spreadsheets = grep { $_->{name} eq $self->{name}; } $self->sheets_api()->spreadsheets();
      LOGDIE "Sheet '$self->{name}' not found on Google Drive" if !@spreadsheets;
      LOGDIE "More than one spreadsheet found with name '$self->{name}'. Specify 'id' or 'uri' instead."
        if scalar @spreadsheets > 1;
      $self->{id} = $spreadsheets[0]->{id};
      DEBUG("Got sheet id '$self->{id}' via spreadsheet list.");
    }
  }

  return $self->{id};
}

# when 'api' is eventually called, id will be worked out if we don't already have it.
# the resolving of id/name/title/uri is deferred until the first api call.
sub spreadsheet_name {
  my $self = shift;
  $self->{name} ||= $self->properties('title')->{title}
    or LOGDIE "No properties title present in properties";
  return $self->{name};
}
sub spreadsheet_title { spreadsheet_name(@_); }

# see above routine.
sub spreadsheet_uri {
  my $self = shift;
  $self->{uri} ||= $self->attrs('spreadsheetUrl')->{spreadsheetUrl}
    or LOGDIE "No spreadsheet URI found from get results";
  $self->{uri} =~ s[/(edit|copy)$][]; # this isn't necessary but keeps things cleaner.
  return $self->{uri};
}

# return one of the attributes of the spreadsheet.
sub attrs {
  my $self = shift;
  my $fields = shift;
  return $self->_cache($fields, sub {
    $self->api(params => { fields => $fields })
  });
}

# return one of the property attributes of the spreadsheet.
sub properties {
  my $self = shift;
  state $check = compile(Str);
  my ($what) = $check->(@_);
  my $fields = _fields('properties', $what);
  return $self->attrs($fields)->{properties};
}

# GET https://sheets.googleapis.com/v4/spreadsheets/spreadsheetId?&fields=sheets.properties
# returns properties for each worksheet in the spreadsheet.
sub worksheet_properties {
  my $self = shift;
  state $check = compile(Str);
  my ($what) = $check->(@_);
  my $fields = _fields('sheets.properties', $what);
  my $properties = $self->attrs($fields)->{sheets};
  my @properties = map { $_->{properties}; } @$properties;
  return \@properties;
}

sub _fields {
  my ($fields, $what) = @_;
  if ($what =~ /^\(/) {
    $fields .= $what;
  } else {
    $fields .= ".$what";
  }
  return $fields;
}

# if multiple attributes are called for, it can hammer the api unnecessarily, so cache the results
# for a few seconds (default 5).
sub _cache {
  my $self = shift;

  state $check = compile(Str, CodeRef);
  my ($key, $code) = $check->(@_);
  return $code->() if !$self->{cache_seconds};

  $self->{_cache} ||= Cache::Memory::Simple->new();
  # will run the code and store the result for x seconds.
  return $self->{_cache}->get_or_set(
    $key, $code, $self->{cache_seconds}
  );
}

sub _cache_delete {
  my $self = shift;
  delete $self->{_cache};
  return;
}

# sets the number of seconds that attrs will be cached. this can be adjusted
# to suit your use-case. if there are lots of people updating things, then a 
# lower cache value would suit. if you know you are the only one using it, then
# a higher cache value will prevent unnecessary calls to the api.
sub cache_seconds {
  my $self = shift;

  state $check = compile(PositiveOrZeroNum);
  my ($cache_seconds) = $check->(@_);

  $self->{_cache}->delete_all() if $self->{_cache};

  if (!$cache_seconds) {
    $self->_cache_delete();
    delete $self->{cache_seconds};
  } else {
    $self->{cache_seconds} = $cache_seconds;
  }

  return;
}

sub copy_spreadsheet {
  my $self = shift;
  return $self->sheets_api()->copy_spreadsheet(
    spreadsheet_id => $self->spreadsheet_id(), @_,
  );
}

sub delete_spreadsheet {
  my $self = shift;
  return $self->sheets_api()->delete_spreadsheet($self->spreadsheet_id());
}

sub range_group {
  my $self = shift;
  state $check = compile(slurpy ArrayRef[HasRange]);
  my ($ranges) = $check->(@_);
  return RangeGroup->new(
    spreadsheet => $self,
    ranges      => $ranges,
  );
}

# ties a key => range set of pairs to this spreadsheet.
sub tie {
  my $self = shift;
  my %ranges = @_;
  tie my %tie, Tie, $self;
  tied(%tie)->add_ranges(%ranges);
  return \%tie;
}

# this is done simply to allow open_worksheet to return the same worksheet instance
# each time it's called for the same remote worksheet. this is to avoid working on
# multiple local copies of the same remote worksheet.
# TODO: if worksheet is renamed, registration should be updated too.
sub _register_worksheet {
  my $self = shift;
  state $check = compile(HasApi);
  my ($worksheet) = $check->(@_);
  my $name = $worksheet->worksheet_name();
  return $self->{registered_worksheet}->{$name} if $self->{registered_worksheet}->{$name};
  $self->{registered_worksheet}->{$name} = $worksheet;
  return $worksheet;
}

# sends batch values to the api.
sub submit_values {
  my $self = shift;

  state $check = compile_named(
    ranges  => ArrayRef[HasMethods[qw(has_values batch_values values_response_from_api)]],
    content => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  # find out which ranges have something to send.
  my @ranges = grep { $_->has_values(); } @{ delete $p->{ranges} };
  my @values = map { $_->batch_values(); } @ranges;
  return if !@values;

  $p->{content}->{data} = \@values;
  $p->{content}->{valueInputOption} //= 'USER_ENTERED';
  $p->{method} = 'post';
  $p->{uri} = "/values:batchUpdate";
  my $api = $self->api(%$p);             # this is where the rubber hits the road.

  # each range that had values should strip off the response from the api's
  # responses array. if everything is in sync, there should be no responses left.
  my $responses = delete $api->{responses};
  $_->values_response_from_api($responses) foreach @ranges;
  LOGDIE "Returned batch values update responses were not consumed" if @$responses;

  # return whatever's left over.
  return $api;
}

# sends batch requests (formatting etc) to the api.
sub submit_requests {
  my $self = shift;

  state $check = compile_named(
    ranges  => ArrayRef[HasMethods[qw(batch_requests requests_response_from_api)]], { default => [] }, # might just be self.
    content => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  my @all_requests = (@{ delete $p->{ranges} }, $self);   # add myself to the list.

  # for each object that has requests to submit, store them so that
  # they can process the responses that come back.
  my @ranges = map {
    $_->batch_requests() ? $_ : ();
  } @all_requests;
  return if !@ranges;

  # pull out the requests hashes to be sent to the rest api.
  my @batch_requests = map {
    $_->batch_requests();
  } @all_requests;
  return if !@batch_requests;

  # we're about to do a bunch of requests that could affect what's in the cache.
  # TODO: selectively invalidate the cache based on what's being submitted.
  $self->_cache_delete();

  # call the batch request api.
  $p->{content}->{requests} = \@batch_requests;
  $p->{method} = 'post';
  $p->{uri} = ':batchUpdate';
  my $api = $self->api(%$p);

  # grab the json decoded replies from the response.
  my $responses = delete $api->{replies};
  # present the responses back to those who are waiting, each will strip off the ones they requested.
  $_->requests_response_from_api($responses) foreach @ranges;
  # if there are any left over, it sux. we are out of sync somewhere. all requestors should
  # process their corresponding response.
  LOGDIE "Returned batch request responses were not consumed" if @$responses;

  return $api;
}

sub named_ranges {
  my $self = shift;

  state $check = compile(RangeNamed, { optional => 1 });
  my ($named_range_name) = $check->(@_);

  my $named_ranges = $self->attrs('namedRanges')->{namedRanges};
  return $named_ranges if !$named_range_name;

  my ($named_range) = grep { $_->{name} eq $named_range_name; } @$named_ranges;
  return $named_range;
}

# takes a named range and works out the actual range it represents.
sub normalize_named {
  my $self = shift;

  state $check = compile(RangeNamed);
  my ($named_range_name) = $check->(@_);

  my $named_range = $self->named_ranges($named_range_name) or return;
  $named_range = $named_range->{range};
  my $range = [
    [ $named_range->{startColumnIndex} + 1, $named_range->{startRowIndex} + 1 ],
    [ $named_range->{endColumnIndex}, $named_range->{endRowIndex} ],
  ];

  return ($named_range->{sheetId}, $range);
}

sub protected_ranges { shift->attrs('sheets.protectedRanges')->{sheets}; }

# each worksheet has an entry:
# ---
# - protectedRanges:
#   - editors:
#       users:
#       - xxx@gmail.com
#       - yyy@gmail.com
#     protectedRangeId: 1161285259
#     range: {}
#     requestingUserCanEdit: !!perl/scalar:JSON::PP::Boolean 1
#     warningOnly: !!perl/scalar:JSON::PP::Boolean 1
# - {}
# - {}
# submit_requests needs to be called by the caller after this.
sub delete_all_protected_ranges {
  my $self = shift;
  foreach my $worksheet (@{ $self->protected_ranges() }) {
    my $ranges = $worksheet->{protectedRanges} or next;
    $self->delete_protected_range($_->{protectedRangeId}) foreach (@$ranges);
  }
  return $self;
}

sub open_worksheet { Worksheet->new(spreadsheet => shift, @_); }
sub sheets_api { shift->{sheets_api}; }
sub rest_api { shift->sheets_api()->rest_api(); }
sub transaction { shift->sheets_api()->transaction(); }
sub stats { shift->sheets_api()->stats(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Spreadsheet - Represents a Google Spreadsheet.

=head1 DESCRIPTION

See the description and synopsis at L<Google::RestApi::SheetsApi4>.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::SheetsApi4>

=item * L<Google::RestApi::SheetsApi4::Spreadsheet>

=item * L<Google::RestApi::SheetsApi4::Worksheet>

=item * L<Google::RestApi::SheetsApi4::Range>

=item * L<Google::RestApi::SheetsApi4::Range::All>

=item * L<Google::RestApi::SheetsApi4::Range::Col>

=item * L<Google::RestApi::SheetsApi4::Range::Row>

=item * L<Google::RestApi::SheetsApi4::Range::Cell>

=item * L<Google::RestApi::SheetsApi4::RangeGroup>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Iterator>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Tie>

=item * L<Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet>

=item * L<Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range>

=back

=head1 SUBROUTINES

=over

=item new(%args);

Creates a new instance of a Spreadsheet object.

%args consists of:

=over

=item * C<sheets_api> <SheetsApi4>: The parent SheetsApi4 object.

=item * C<id> <string>: The id of the spreadsheet (Google Drive file ID).

=item * C<name> <string>: The name of the spreadsheet (as shown in Google Drive).

=item * C<title> <string>: An alias for name.

=item * C<uri> <string>: The spreadsheet ID extracted from the overall URI.

=item * C<cache_seconds> <int>: Cache information for this many seconds (default to 5, 0 disables).

=back

You would not normally call this directly, you would obtain it from the SheetsApi4::open_spreadsheet routine.

Only one of id/name/title/uri should be specified and this API will derive the others as necessary.

The cache exists so that repeated calls for the same attributes or worksheet properties doesn't keep hammering the Google API over and over.
The default is 5 seconds. See 'cache_seconds' below.

=item api(%args);

Calls the parent SheetsApi4's 'api' routine adding the sheet file ID, and passing through any args such as content, params, headers, etc.

You would not normally call this directly unless you were making a Google API call not currently supported by this API framework.

Returns the response hash from Google API.

=item spreadsheet_id();

Returns the spreadsheet id (the Google Drive file id).

=item spreadsheet_uri();

Returns the URI of this spreadsheet.

=item spreadsheet_name();

Returns the name of the spreadsheet.

=item spreadsheet_title();

An alias for 'spreadsheet_name'.

=item attrs(fields<string>);

Returns the spreadsheet attributes of the specified fields.

=item properties(properties<string>);

Returns the spreadsheet property attributes of the specified fields.

=item worksheet_properties(what<string>);

Returns an array ref of the properties of the worksheets owned by this spreadsheet.

=item cache_seconds(seconds<int>)

Sets the caching time in seconds. Calling will always delete the existing cache. 0 disables the cache (not recommended).

=item delete_all_protected_ranges();

Deletes all the protected ranges from all the worksheets owned by this spreadsheet.

=item named_ranges(name<string>);

Returns the properties of the named range passed, or if false is passed, all the named ranges for this spreadsheet.

=item copy_spreadsheet(%args);

Creates a copy of this spreadsheet and passes any args to the Google Drive file copy routine.

=item delete_spreadsheet();

Deletes this spreadsheet from Google Drive.

=item range_group(range<array>...);

Creates a range group with the contained ranges. See the RangeGroup object.

=item tie(%args);

%args is a hash of key => Range object pairs.

Ties the given 'key => range' pairs into a tied range group. The range group can be used to send batch values (API batchUpdate) and
batch requests (API batchRequests) as a single call once all the changes have been made to the overall hash.

Turning on the 'fetch_range' property will return the underlying ranges on fetch so that formatting for the ranges can be set. You
would normally only turn this on for a short time, and turn it off when the underlying batch requests have been submitted.

 $tied = $ss->tie(id => $range_cell);
 tied(%$tied)->fetch_range(1);
 $tied->{id}->bold()->red()->background_blue();
 tied(%$tied)->fetch_range(0)->submit_requests();

See also Worksheet::tie.

=item submit_values(%args);

%args consists of:

=over

=item * C<ranges> <arrayref>: The ranges that have requests to be sent in one batchUpdate Google API call.

=item * C<content> <hashref>: Any additional content to be sent to the Google API for this batch submit, for any customized content that needs to be passed.

=back

Submits the batch values (Google API's batchUpdate) for the specified ranges. Content is passed to the SheetsApi4's 'api' call for any customized
content you may need to pass.

=item submit_requests(%args);

%args consists of:

=over

=item * C<ranges> <arrayref>: The ranges that have requests to be sent in one batchRequest Google API call.

=item * C<content> <hashref>: Any additional content to be sent to the Google API for this batch submit, for any customized content that needs to be passed.

=back

Submits the batch requests (Google API's batchRequest) for the specified ranges. Content is passed to the SheetsApi4's 'api' call for any customized
content you may need to pass.

=item protected_ranges();

Returns all the protected ranges for this spreadsheet.

=item open_worksheet(%args);

Creates a new Worksheet object, passing the args to that object's 'new' routine (which see).

=item sheets_api();

Returns the SheetsApi4 object.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

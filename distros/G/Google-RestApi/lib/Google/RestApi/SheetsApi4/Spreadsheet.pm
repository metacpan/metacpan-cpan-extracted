  package Google::RestApi::SheetsApi4::Spreadsheet;

use strict;
use warnings;

our $VERSION = '0.2';

use 5.010_000;

use autodie;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str StrMatch ArrayRef HashRef HasMethods Any slurpy);
use YAML::Any qw(Dump);

no autovivification;

use Google::RestApi::Utils qw(named_extra);
use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Worksheet';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup';

use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet";

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  my $qr_id = SheetsApi4->Spreadsheet_Id;
  my $qr_uri = SheetsApi4->Spreadsheet_Uri;
  state $check = compile_named(
    sheets    => HasMethods[qw(api config spreadsheets)],
    id        => StrMatch[qr/$qr_id/], { optional => 1 },  # https://developers.google.com/sheets/api/guides/concepts
    name      => Str, { optional => 1 },
    title     => Str, { optional => 1 },
    uri       => StrMatch[qr|$qr_uri/$qr_id/|], { optional => 1 },
    config_id => Str, { optional => 1 },
  );
  my $self = $check->(@_);

  $self = bless $self, $class;
  $self->{name} ||= $self->{title};
  delete $self->{title};

  if ($self->{config_id}) {
    my $config = $self->sheets_config($self->{config_id})
      or die "Config '$self->{config_id}' is missing";
    foreach (qw(id name uri)) {
      $self->{$_} = $config->{$_} if defined $config->{$_};
    }
    $self->{config} = $config->{worksheets} if $config->{worksheets};
  }

  $self->{id} || $self->{name} || $self->{uri} or die "At least one of id, name, or uri must be specified";

  return $self;
}

sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str, { default => '' },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{uri} = $self->spreadsheet_id() . $p->{uri};
  return $self->sheets()->api(%$p);
}

sub spreadsheet_id {
  my $self = shift;

  if (!$self->{id}) {
    if ($self->{uri}) {
      my $qr_id = SheetsApi4->Spreadsheet_Id;
      my $qr_uri = SheetsApi4->Spreadsheet_Uri;
      ($self->{id}) = $self->{uri} =~ m|$qr_uri/($qr_id)|;
      die "Unable to extract a sheet id from uri" if !$self->{id};
      DEBUG("Got sheet ID '$self->{id}' via URI '$self->{uri}'.");
    } else {
      my $spreadsheets = $self->sheets()->spreadsheets();
      my ($spreadsheet) = grep {
        $_->{name} eq $self->{name};
      } @{ $spreadsheets->{files} };
      die "Sheet '$self->{name}' not found on google drive" if !$spreadsheet;
      $self->{id} = $spreadsheet->{id};
      DEBUG("Got sheet id '$self->{id}' via spreadsheet list.");
    }
  }

  return $self->{id};
}

sub spreadsheet_uri {
  my $self = shift;
  $self->{uri} ||= $self->attrs('spreadsheetUrl')->{spreadsheetUrl}
    or die "No spreadsheet URI found from get results";
  return $self->{uri};
}

sub spreadsheet_name {
  my $self = shift;
  $self->{name} ||= $self->properties('title')->{title}
    or die "No properties title present in properties";
  return $self->{name};
}
sub spreadsheet_title { spreadsheet_name(@_); }

sub attrs {
  my $self = shift;
  state $check = compile(Str);
  my ($fields) = $check->(@_);
  return $self->api(params => { fields => $fields });
}

sub properties {
  my $self = shift;
  state $check = compile(Str);
  my ($what) = $check->(@_);
  my $fields = _fields('properties', $what);
  return $self->attrs($fields)->{properties};
}

# GET https://sheets.googleapis.com/v4/spreadsheets/spreadsheetId?&fields=sheets.properties
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

sub named_ranges {
  my $self = shift;
  state $check = compile(Str, { optional => 1 });
  my ($range) = $check->(@_);
  my $named_ranges = $self->attrs('namedRanges')->{namedRanges};
  return $named_ranges if !$range;
  ($range) = grep { $_->{name} eq $range; } @$named_ranges;
  return $range;
}

sub copy_spreadsheet {
  my $self = shift;
  return $self->sheets()->copy_spreadsheet(
    spreadsheet_id => $self->spreadsheet_id(), @_,
  );
}

sub delete_spreadsheet {
  my $self = shift;
  return $self->sheets()->delete_spreadsheet($self->spreadsheet_id());
}

sub range_group {
  my $self = shift;
  state $check = compile(slurpy ArrayRef[HasMethods['range']]);
  my ($ranges) = $check->(@_);
  return RangeGroup->new(
    spreadsheet => $self,
    ranges      => $ranges,
  );
}

sub tie {
  my $self = shift;
  my %ranges = @_;
  tie my %tie,
    'Google::RestApi::SheetsApi4::RangeGroup::Tie', $self;
  tied(%tie)->add_ranges(%ranges);
  return \%tie;
}

# this is done simply to allow open_worksheet to return the
# same worksheet instance each time it's called for the
# same remote worksheet. this is to avoid working on multiple
# local copies of the same remote worksheet.
# TODO: if worksheet is renamed, registration should be
# updated too.
sub _register_worksheet {
  my $self = shift;
  state $check = compile(HasMethods['worksheet_name']);
  my ($worksheet) = $check->(@_);
  my $name = $worksheet->worksheet_name();
  return $self->{registered_worksheet}->{$name} if $self->{registered_worksheet}->{$name};
  $self->{registered_worksheet}->{$name} = $worksheet;
  return $worksheet;
}

sub config {
  my $self = shift;
  my $config = $self->{config} or return;
  my $key = shift;
  return defined $key ? $config->{$key} : $config;
}

sub submit_values {
  my $self = shift;

  state $check = compile_named(
    values  => ArrayRef[HasMethods[qw(has_values batch_values values_response)]],
    content => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  my @batch_values = grep { $_->has_values(); } @{ delete $p->{values} };
  my @values = map { $_->batch_values(); } @batch_values;
  return if !@values;

  $p->{content}->{data} = \@values;
  $p->{content}->{valueInputOption} //= 'USER_ENTERED';
  $p->{method} = 'post';
  $p->{uri} = "/values:batchUpdate";

  my $response = $self->api(%$p);
  my $responses = $response->{responses};
  my @responses = map { $_->values_response($responses); } @batch_values;
  die "Returned batch update responses were not consumed" if @$responses;

  return \@responses;
}

sub submit_requests {
  my $self = shift;

  state $check = compile_named(
    requests => ArrayRef[HasMethods[qw(batch_requests requests_response)]], { default => [] }, # might just be self.
    content  => HashRef, { default => {} },
  );
  my $p = $check->(@_);

  my @batch_responses = map {
    $_->batch_requests() ? $_ : ();
  } @{ $p->{requests} }, $self;   # add myself to the list.
  return if !@batch_responses;

  my @batch_requests = map {
    $_->batch_requests();
  } @{ delete $p->{requests} }, $self;
  return if !@batch_requests;

  $p->{content}->{requests} = \@batch_requests;
  $p->{method} = 'post';
  $p->{uri} = ':batchUpdate';

  my @api = $self->api(%$p);
  my $responses = $api[0]->{replies};
  my @responses = map { $_->requests_response($responses); } @batch_responses;
  die "Returned batch request responses were not consumed" if @$responses;

  return wantarray ? @api : $api[0];
}

sub protected_ranges { shift->attrs('sheets.protectedRanges')->{sheets}; }
sub open_worksheet { Worksheet->new(spreadsheet => shift, @_); }
sub sheets_config { shift->sheets()->config(shift); }
sub sheets { shift->{sheets}; }
sub stats { shift->sheets()->stats(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Spreadsheet - Represents a Google Spreadsheet.

=head1 DESCRIPTION

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(sheets => <SheetsApi4>, (id => <string> | name => <string> | title => <string> | uri => <string>), config_id => <string>);

Creates a new instance of a Spreadsheet object. You would not normally
call this directly, you would obtain it from the
Sheets::open_spreadsheet routine.

 sheets: The parent SheetsApi4 object.
 id: The id of the spreadsheet (Google Drive file ID).
 name: The name of the spreadsheet (as shown in Google Drive).
 title: An alias for name.
 uri: The spreadsheet ID extracted from the overall URI.
 config_id: The custom config for this worksheet.

Only one of id/name/title/uri should be specified and this API will derive the others
as necessary.

=item api(%args);

Calls the parent SheetsApi4's 'api' routine with the Sheet's
endpoint, along with any args to be passed such as content,
params, headers, etc.

You would not normally call this directly unless you were
making a Google API call not currently supported by this API
framework.

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

Returns an array ref of the properties of the worksheets
owned by this spreadsheet.

=item delete_all_protected_ranges();

Deletes all the protected ranges from all the worksheets
owned by this spreadsheet.

=item named_ranges(name<string>);

Returns the properties of the named range passed, or if
false is passed, all the named ranges for this spreadsheet.

=item copy_spreadsheet(%args);

Creates a copy of this spreadsheet and passes any args
to the Google Drive File copy routine.

=item delete_spreadsheet();

Deletes this spreadsheet from Google Drive.

=item range_group(range<array>...);

Creates a range group with the contained ranges.

=item tie(ranges<hash>);

Ties the given 'key => range' pairs into a tied range group. The
range group can be used to send batch values (API batchUpdate) and
batch requests (API batchRequests) as a single call once all the
changes have been made to the overall hash.

Turning on the 'fetch_range' property will return the underlying
ranges on fetch so that formatting for the ranges can be set. You
would normally only turn this on for a short time, and turn it off
when the underlying batch requests have been submitted.

 $tied = $ss->tie(id => $range_cell);
 $tied->{id} = 1001;
 tied(%$tied)->submit_values();

 tied(%$tied)->fetch_range(1);
 $tied->{id}->bold()->red()->background_blue();
 tied(%$tied)->fetch_range(0)->submit_requests();

See also Google::RestApi::SheetsApi4::Worksheet::tie.

=item config(key<string>)

Returns the custom configuration item with the given key, or the entire
configuration for this spreadsheet if no key is specified.

=item submit_values(values<arrayref>, content<hashref>);

Submits the batch values (Google API's batchUpdate) for the
specified ranges. Content is passed to the SheetsApi4's 'api'
call for any customized content you may need to pass.

=item submit_requests(requests<arrayref>, content<hashref>);

Submits any outstanding requests (Google API's batchRequests)
for this spreadsheet. content will be passed to the SheetsApi4's
'api' call for any customized content you may need to pass.

=item protected_ranges();

Returns all the protected ranges for this spreadsheet.

=item open_worksheet(%args);

Creates a new Worksheet object, passing the args to that object's
'new' routine (which see).

=item sheets_config();

Returns the parent SheetsApi4 config.

=item sheets();

Returns the SheetsApi4 object.

=item stats()

Shows some statistics on how many get/put/post etc calls were made.
Useful for performance tuning during development.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

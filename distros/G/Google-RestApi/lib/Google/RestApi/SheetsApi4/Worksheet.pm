package Google::RestApi::SheetsApi4::Worksheet;

our $VERSION = '0.9';

use Google::RestApi::Setup;

use List::MoreUtils qw( first_index );

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';
use aliased 'Google::RestApi::SheetsApi4::Range::All';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Iterator';

use parent 'Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet';

sub new {
  my $class = shift;

  my $qr_worksheet_uri = SheetsApi4->Worksheet_Uri;
  state $check = compile_named(
    spreadsheet => HasApi,
    id          => Str, { optional => 1 },
    name        => Str, { optional => 1 },
    uri         => StrMatch[qr|$qr_worksheet_uri|], { optional => 1 },
  );
  my $self = $check->(@_);
  $self = bless $self, $class;

  defined $self->{id} || defined $self->{name} || $self->{uri}
    or LOGDIE "At least one of id, name, or uri must be specified";

  return $self->spreadsheet()->_register_worksheet($self);
}

sub worksheet_id {
  my $self = shift;
  if (!defined $self->{id}) {
    if ($self->{uri}) {
      my $qr_worksheet_uri = SheetsApi4->Worksheet_Uri;
      ($self->{id}) = $self->{uri} =~ m|$qr_worksheet_uri|;
      LOGDIE "Unable to extract a worksheet id from URI '$self->{uri}'" if !defined $self->{id};
    } else {
      my $worksheets = $self->spreadsheet()->worksheet_properties('(title,sheetId)');  # potential recursion if $self->properties()
      my ($worksheet) = grep { $_->{title} eq $self->{name}; } @$worksheets;
      $worksheet or LOGDIE "Worksheet '$self->{name}' not found";
      $self->{id} = $worksheet->{sheetId};
    }
    DEBUG("Got worksheet id '$self->{id}'");
  }
  return $self->{id};
}

sub worksheet_name {
  my $self = shift;
  $self->{name} //= $self->properties('title')->{title};
  return $self->{name};
}

# https://docs.google.com/spreadsheets/d/spreadsheetId/edit#gid=0
sub worksheet_uri {
  my $self = shift;
  if (!$self->{uri}) {
    my $id = $self->worksheet_id();
    $self->{uri} = "/edit#gid=$id";
  }
  return $self->spreadsheet()->spreadsheet_uri() . "/$self->{uri}";
}

sub properties {
  my $self = shift;
  my $what = shift;
  my $id = $self->worksheet_id();
  my $worksheets = $self->spreadsheet()->worksheet_properties("($what,sheetId)");
  my ($worksheet) = grep { $_->{sheetId} eq $id; } @$worksheets;
  $worksheet or LOGDIE "Worksheet '$id' not found";
  return $worksheet;
}

# the following don't return ranges and don't use any batch, they are immediate.
# first arg is a range in any format. allow the range_col call to verify it.
sub col {
  my $self = shift;
  state $check = compile(Defined, ArrayRef[Str], { optional => 1 });   # A or 1
  my ($col, $values) = $check->(@_);
  my $range = $self->range_col($col);
  return $range->values(defined $values ? (values => $values) : ());
}

sub cols {
  my $self = shift;

  state $check = compile(ArrayRef[Defined], ArrayRef[ArrayRef[Str]], { optional => 1 });
  my ($cols, $values) = $check->(@_);

  my $range_group = $self->range_group_cols($cols);
  return $range_group->values() if !$values;

  my @ranges = $range_group->ranges();
  foreach my $i (0..$#ranges) {
    $ranges[$i]->batch_values(
      values => $values->[$i],
    );
  }

  return $range_group->submit_values();
}

sub row {
  my $self = shift;
  state $check = compile(Defined, ArrayRef[Str], { optional => 1 });
  my ($row, $values) = $check->(@_);
  my $range = $self->range_row($row);
  return $range->values(defined $values ? (values => $values) : ());
}

sub rows {
  my $self = shift;

  state $check = compile(ArrayRef[Defined], ArrayRef[ArrayRef[Str]], { optional => 1 });
  my ($rows, $values) = $check->(@_);

  my $range_group = $self->range_group_rows($rows);
  return $range_group->values() if !$values;

  my @ranges = $range_group->ranges();
  foreach my $i (0..$#ranges) {
    $ranges[$i]->batch_values(
      values => $values->[$i],
    );
  }

  return $range_group->submit_values();
}

sub cell {
  my $self = shift;
  state $check = compile(Defined, Str, { optional => 1 });
  my ($cell, $value) = $check->(@_);
  my $range = $self->range_cell($cell);
  return $range->values(defined $value ? (values => $value) : ());
}

sub cells {
  my $self = shift;

  state $check = compile(ArrayRef[Defined], ArrayRef[Str], { optional => 1 });
  my ($cells, $values) = $check->(@_);

  my $range_group = $self->range_group_cells($cells);
  return $range_group->values() if !$values;

  my @ranges = $range_group->ranges();
  foreach my $i (0..$#ranges) {
    $ranges[$i]->batch_values(
      values => $values->[$i],
    );
  }

  return $range_group->submit_values();
}

sub submit_requests {
  my $self = shift;
  return $self->spreadsheet()->submit_requests(ranges => [ $self ], @_);
}

# this is used by range to see if there is a match for a header col or row.
sub resolve_header_range {
  my $self = shift;
  return
    $self->resolve_header_range_col(@_) ||
    $self->resolve_header_range_row(@_);
}

sub resolve_header_range_col {
  my $self = shift;

  state $check = compile(RangeNamed);
  my ($header) = $check->(@_);
  
  my $headers = $self->header_col() or return;
  my $i = first_index { $_ eq $header; } @$headers;
  return [{col => 2, row => $i}, {row => $i}] if ++$i > 0;

  return;
}

sub resolve_header_range_row {
  my $self = shift;

  state $check = compile(RangeNamed);
  my ($header) = $check->(@_);
  
  my $headers = $self->header_row() or return;
  my $i = first_index { $_ eq $header; } @$headers;
  return [{col => $i, row => 2}, {col => $i}] if ++$i > 0;

  return;
}

# call this before calling tie_rows or header_col.
# ('i really want to do this') turns it on, (false) turns it off.
# you must pass 'i really want to do this' to enable it. this is because you
# may have a worksheet with thousands of rows that end up being 'headers'.
# this is less of an issue with header row.
sub enable_header_col {
  my $self = shift;
  my $enable = shift // 1;
  if ($enable =~ qr/i really want to do this/i) {
    $self->{header_col_enabled} = 1;
  } elsif ($enable) {
    LOGDIE("You must enable header column by passing 'I really want to do this'");
  } else {
    delete @{$self}{qw(header_col header_col_enabled)};
  }
  return $enable;
}

# call with true to refresh.
sub header_col {
  my $self = shift;
  my $refresh = shift;

  if (!$self->{header_col_enabled}) {
    DEBUG("Header column is not enabled, call 'enable_header_col' first.");
    delete $self->{header_col};
    return;
  }

  delete $self->{header_col} if $refresh;

  if (!$self->{header_col}) {
    $self->{header_col} = $self->col(1);
    DEBUG("Header col found:\n", Dump($self->{header_col}));
  }

  return $self->{header_col};
}

# call this before calling tie_cols (to use headings) or header_row.
# () or (true) turns it on, (false) turns it off.
sub enable_header_row {
  my $self = shift;
  my $enable = shift // 1;
  if ($enable) {
    $self->{header_row_enabled} = 1;
  } else {
    delete @{$self}{qw(header_row header_row_enabled)};
  }
  return $enable;
}

# call with 1 to refresh.
sub header_row {
  my $self = shift;
  my $refresh = shift;

  if (!$self->{header_row_enabled}) {
    DEBUG("Header row is not enabled, call 'enable_header_row' first.");
    delete $self->{header_row};
    return;
  }

  delete $self->{header_row} if $refresh;

  if (!$self->{header_row}) {
    $self->{header_row} = $self->row(1);
    DEBUG("Header row found:\n", Dump($self->{header_row}));
  }
  return $self->{header_row};
}

sub header_col_enabled { shift->{header_col_enabled}; }
sub header_row_enabled { shift->{header_row_enabled}; }

sub normalize_named {
  my $self = shift;

  state $check = compile(RangeNamed);
  my ($named_range_name) = $check->(@_);

  my ($sheet_id, $range) = $self->spreadsheet()->normalize_named($named_range_name);
  my $this_sheet_id = $self->worksheet_id();
  LOGDIE "Named range '$named_range_name' sheet ID is '$sheet_id', this sheet ID is '$this_sheet_id'"
    if $sheet_id && $sheet_id != $this_sheet_id;

  return $range;
}

sub name_value_pairs {
  my $self = shift;

  state $check = compile(
    Defined, { default => 1 },
    Defined, { default => 2 },
  );
  my ($name_col, $value_col) = $check->(@_);

  my $cols = $self->cols([$name_col, $value_col]);
  my %pairs = map {
    defined $cols->[0]->[$_]
    ?
    ( strip($cols->[0]->[$_]) => strip($cols->[1]->[$_]) )
    :
    ();
  } (($self->header_row_enabled() ? 1 : 0)..$#{ $cols->[0] });

  return \%pairs;
}

sub tie_cols { shift->_tie('range_col', @_); }
sub tie_rows { shift->_tie('range_row', @_); }
sub tie_cells { shift->_tie('range_cell', @_); }
sub tie_ranges { shift->_tie('range_factory', @_); }

sub _tie {
  my $self = shift;

  state $check = compile(
    Str->where( sub { /^range/ && $self->can($_) or die "Must be a 'range' method"; } ),
    slurpy HashRef,
  );
  my ($method, $ranges) = $check->(@_);

  my %ranges = map { $_ => $self->$method( $ranges->{$_} ); } keys %$ranges;
  return $self->tie(%ranges);
}

sub tie {
  my $self = shift;
  my $tie = $self->spreadsheet()->tie(@_);
  tied(%$tie)->default_worksheet($self);
  return $tie;
}

sub range_group_cols {
  my $self = shift;
  state $check = compile(ArrayRef[Defined]);
  my ($cols) = $check->(@_);
  my @cols = map { $self->range_col($_); } @$cols;
  return $self->spreadsheet()->range_group(@cols);
}

sub range_group_rows {
  my $self = shift;
  state $check = compile(ArrayRef[Defined]);
  my ($rows) = $check->(@_);
  my @rows = map { $self->range_row($_); } @$rows;
  return $self->spreadsheet()->range_group(@rows);
}

sub range_group_cells {
  my $self = shift;
  state $check = compile(ArrayRef[Defined]);
  my ($cells) = $check->(@_);
  my @cells = map { $self->range_cell($_); } @$cells;
  return $self->spreadsheet()->range_group(@cells);
}

sub range_group {
  my $self = shift;
  state $check = compile(ArrayRef[Defined]);
  my ($ranges) = $check->(@_);
  my @ranges = map { $self->range_factory($_); } @$ranges;
  return $self->spreadsheet()->range_group(@ranges);
}

# can't use aliased here for some reason.
sub range_factory { Google::RestApi::SheetsApi4::Range::factory(worksheet => shift, range => shift, @_); }

sub range { shift->range_factory(@_); }
# create these spcific subclasses so that invalid ranges will get caught.
sub range_col { Col->new(worksheet => shift, range => shift); }
sub range_row { Row->new(worksheet => shift, range => shift); }
sub range_cell { Cell->new(worksheet => shift, range => shift); }
sub range_all { All->new(worksheet => shift, @_); }
sub api { shift->spreadsheet()->api(@_); }
sub sheets_api { shift->spreadsheet()->sheets_api(@_); }
sub rest_api { shift->spreadsheet()->rest_api(@_); }
sub spreadsheet { shift->{spreadsheet}; }
sub spreadsheet_id { shift->spreadsheet()->spreadsheet_id(); }
sub transaction { shift->spreadsheet()->transaction(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Worksheet - Represents a Worksheet within a Google Spreadsheet.

=head1 DESCRIPTION

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(spreadsheet => <object>, (id => <string> | name => <string> | uri => <string>));

Creates a new instance of a Worksheet object. You would not normally
call this directly, you would obtain it from the 
Spreadsheet->open_worksheet routine.

 spreadsheet: The parent object that represents the collection of worksheets.
 id: The id of the worksheet (0, 1, 2 etc).
 name: The name of the worksheet (as shown on the tab).
 uri: The worksheet ID extracted from the overall URI.

Only one of id/name/uri should be specified and this API will derive the others
as necessary.

=item worksheet_id()

Returns the worksheet id.

=item worksheet_name()

Returns the worksheet name or title.

=item worksheet_uri()

Returns the worksheet URL (URL);

=item properties(what<string>);

Returns the specific properties of this worksheet, such as the title or sheet id.

 what: The fields you are interested in (title, sheetId, etc).

=item col(range<range>, values<arrayref>);

Gets or sets the column values.

 $ws->col('A', [1, 2, 3]);
 $values = $ws->col('A');

Note: the Google API is called immediately, so this is the easiest
but least efficient way of getting/setting spreadsheet values.

=item cols(cols<arrayref<range>>, values<arrayref<arrayref<string>>>);

Gets or sets a group of columns, see note as 'col' above.

 $ws->cols(['A', 2, 'Id'], [[1, 2, 3, 4], [5], [6, 7]]);
 $values = $ws->cols(['A', 2, 'Id']);

=item row(range<range>, values<arrayref<string>>);

Same as 'col' above, but operates on a row.

=item rows(rows<arrayref<range>>, values<arrayref<arrayref<string>>>)

Same as 'cols' above, but operates on rows.

=item cell(col<range>, row<range>|range<range>), value<string>);

Same as above, but operates on a cell. 

=item header_row(refresh<boolean>)

Returns an array of values in the first row that act as simple
headers for the columns. The values are cached in the worksheet
so that multiple calls will only invoke the API once, unless you
pass a true value to the routine to refresh them.

This is used internally to check for indexed column names such as
'Id', 'Name' or 'Address' etc. It may be of limited use externally.

This will only work on simple headers that don't use fancy formatting
spread over multiple merged cells/rows.

=item header_col(refresh<boolean>)

A less practical version of header_row, uses the first column to
label each row. Since this is cached, if the spreadsheet is large,
this can potentially use a lot of memory. Therefore, you must call
enable_header_col first, with a true value, to obtain these column
values.

=item name_value_pairs(name_col<range>, value_col<range>, has_headers<boolean>);

A utility to convert two columns into a simple hash.

 name_col: A range pointing to the keys of the hash.
 value_col: A range pointing to the values of the hash.
 has_headers: A boolean indicating if the first row should be ignored.

A spreadsheet with the values:

 Name    Value
 Fred    1
 Charlie 2
 
...will return the hash:

 Fred    => 1,
 Charlie => 2,

This allows you to store and retrieve a hash with little muss or fuss.

=item tie_ranges(ranges<array<hash|<string>>>...);

Ties the given ranges into a tied range group. Specify
either a 'key => range<range>' or a plain <range<string>>.

 $tied = $ws->tie_ranges({id => 'A2'}, 'B2', 'A5:B6');
 $tied->{id} = [['1001']];
 $tied->{B2} = [['Herb Ellis']];
 $tied->{A5:B6} = [[1, 2], [3, 4]];
 tied(%$tied)->submit_values();

If you need to represent the range as anything but a string, you must
specify the key=>range format ({id => [1, 2]} or {id => {col => 1, row => 1}}).

=item tie_cols(ranges<array<range>>...);

Same as tie_ranges (above), but ties Range::Col objects. Specify
range strings, or column headings to represent the columns.

 $tied = $ws->tie_cols({id => 'A'}, 'Name');
 $tied->{id} = [1001, 1002, 1003];
 $tied->{Name} = ['Herb Ellis', 'Bela Fleck', 'Freddie Mercury'];
 tied(%$tied)->submit_values();

=item tie_rows(ranges<array<range>>...);

Same as tie_cols (above), but ties Range::Row objects.

 $tied = $ws->tie_rows({herb => 2}, {bela => 3});
 $tied->{herb} = ['Herb Ellis'];
 $tied->{bela} = ['Bela Fleck'];
 tied(%$tied)->submit_values();

To use row 'headings' as ranges (assuming 'Herb Ellis' is in column 1),
you must call 'enable_header_col' to enable the row headers first
(see below).

=item tie_cells(ranges<array<range>>...);

Same as above, but ties Range::Cell objects.

 $tied = $ws->tie_cells(qw({id => A2}, B2));
 $tied->{id} = 1001;
 $tied->{B2} = 'Herb Ellis';
 tied(%$tied)->submit_values();

=item tie(ranges<hash>);

Ties the given 'key => range' pairs into a tied range group, and sets
the default worksheet, for any new keys later added, to this worksheet.

 $tied = $ws->tie(id => $range_cell);
 $tied->{id} = 1001;
 $teid->{B2} = 'Herb Ellis'; # autocreated for this worksheet.
 tied(%$tied)->submit_values();

New keys that are added later are assumed to address cells if there is
no ':' (A1), or a general range if a ':' is found (A1:B2). It is better
to explicitly set all the ranges you expect to use on the call to 'tie'
rather than auto-creating the ranges later to avoid unexpected behaviour.

See also Google::RestApi::SheetsApi4::Spreadsheet::tie.

=item submit_requests(%args)

Submits any outstanding requests (API batchRequests) for this worksheet.
%args are any args to be passed to the RestApi's 'api' routine (content,
params etc).

=item range(range<range>);

Returns a Range object representing the passed range string, array, or hash.

=item range_col(range<range>);

Returns a Range::Col object representing the passed range.

=item range_row(range<range>);

Returns a Range::Row object representing the passed range.

=item range_cell(range<range>);

Returns a Range::Cell object representing the passed range.

=item range_all();

Returns a Range::All object that represents the whole worksheet.

=item api(%args);

A passthrough to the parent Spreadsheet object's 'api' routine.

=item sheets_api();

Returns the SheetsApi4 object.

=item spreadsheet();

Returns the parent Spreadsheet object.

=item spreadsheet_id();

Returns the parent Spreadsheet id.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

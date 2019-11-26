package Google::RestApi::SheetsApi4::Worksheet;

use strict;
use warnings;

our $VERSION = '0.4';

use 5.010_000;

use autodie;
use Type::Params qw(compile compile_named multisig);
use Types::Standard qw(Str StrMatch Int Bool HashRef ArrayRef HasMethods Maybe slurpy);
use YAML::Any qw(Dump);

no autovivification;

use Google::RestApi::Utils qw(strip);
use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';
use aliased 'Google::RestApi::SheetsApi4::Range::All';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Iterator';

use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet";

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  my $qr_worksheet_uri = SheetsApi4->Worksheet_Uri;
  state $check = compile_named(
    spreadsheet => HasMethods[qw(api config sheets worksheet_properties)],  # if it's got these basics, it must be a duck.
    id          => Str, { optional => 1 },
    name        => Str, { optional => 1 },
    uri         => StrMatch[qr|$qr_worksheet_uri|], { optional => 1 },
    config_id   => Str, { optional => 1 },
  );
  my $self = $check->(@_);
  $self = bless $self, $class;

  if ($self->{config_id}) {
    my $config = $self->spreadsheet_config($self->{config_id})
      or die "Config '$self->{config_id}' is missing";
    foreach (qw(id name uri)) {
      $self->{$_} = $config->{$_} if defined $config->{$_};
    }
    $self->{config} = $config;
  }
  defined $self->{id} || defined $self->{name} || $self->{uri}
    or die "At least one of id, name, or uri must be specified";

  return $self->spreadsheet()->_register_worksheet($self);
}

sub worksheet_id {
  my $self = shift;
  if (!defined $self->{id}) {
    if ($self->{uri}) {
      my $qr_worksheet_uri = SheetsApi4->Worksheet_Uri;
      ($self->{id}) = $self->{uri} =~ m|$qr_worksheet_uri|;
      die "Unable to extract a worksheet id from URI '$self->{uri}'" if !defined $self->{id};
    } else {
      my $worksheets = $self->spreadsheet()->worksheet_properties('(title,sheetId)');  # potential recursion if $self->properties()
      my ($worksheet) = grep { $_->{title} eq $self->{name}; } @$worksheets;
      $worksheet or die "Worksheet '$self->{name}' not found";
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
  $worksheet or die "Worksheet '$id' not found";
  return $worksheet;
}

# the following don't return ranges and don't use any batch, they are immediate.
sub col {
  my $self = shift;
  state $check = compile(Range->Col, ArrayRef, { optional => 1 });   # A or 1
  my ($col, $values) = $check->(@_);
  my $range = $self->range_col({ col => $col });
  return $range->values(values => $values)
    if defined $values;
  return $range->values();
}

sub cols {
  my $self = shift;

  state $check = compile(ArrayRef[Range->Col], ArrayRef, { optional => 1 });
  my ($cols, $values) = $check->(@_);

  my @cols = map { $self->range_col($_); } @$cols;
  my $range_group = $self->spreadsheet()->range_group(@cols);
  return $range_group->values(params => { majorDimension => 'COLUMNS' }) if !$values;

  my @ranges = $range_group->ranges();
  $ranges[$_]->batch_values(
    values => $values->[$_],
  ) foreach (0..$#ranges);

  return $range_group->submit_values();
}

sub row {
  my $self = shift;
  state $check = compile(Range->Row, ArrayRef, { optional => 1 });
  my ($row, $values) = $check->(@_);
  my $range = $self->range_row({row => $row});
  return $range->values(values => $values)
    if defined $values;
  return $range->values();
}

sub rows {
  my $self = shift;

  state $check = compile(ArrayRef[Range->Row], ArrayRef, { optional => 1 });
  my ($rows, $values) = $check->(@_);

  my @rows = map { $self->range_row($_); } @$rows;
  my $range_group = $self->spreadsheet()->range_group(@rows);
  return $range_group->values() if !$values;

  my @ranges = $range_group->ranges();
  $ranges[$_]->batch_values(
    values => $values->[$_],
  ) foreach (0..$#ranges);

  return $range_group->submit_values();
}

sub cell {
  my $self = shift;

  state $check = multisig(
    [
      Range->Col, Range->Row,
      Str, { optional => 1 },
    ],
    [
      Range->Range,
      Str, { optional => 1 },
    ],
  );
  my @check = $check->(@_);
  my $range;
  if (${^TYPE_PARAMS_MULTISIG} == 0) {
    my $col = shift(@check);
    my $row = shift(@check);
    $range = $self->range_cell([$col, $row]);
  } else {
    my $cell = shift(@check);
    $range = $self->range_cell($cell);
  }
  my $value = shift(@check);

  return $range->values(values => $value) if defined $value;
  return $range->values();
}

# call this before calling tie_rows or header_col. it's an
# "are you sure you want to do this?" check.
sub enable_header_col {
  my $self = shift;
  if (shift) {
    $self->{header_col_enabled} = 1;
  } else {
    delete @{ %$self }{qw(header_col header_col_enabled)};
  }
  return;
}

sub header_col {
  my $self = shift;

  if (!$self->{header_col_enabled}) {
    delete $self->{header_col};
    return [];
  }

  delete $self->{header_col} if shift;
  if (!$self->{header_col}) {
    $self->{header_col} = $self->col(1);
    DEBUG("Header col found:\n", Dump($self->{header_col}));
  }

  return $self->{header_col};
}

sub header_row {
  my $self = shift;
  delete $self->{header_row} if shift;
  if (!$self->{header_row}) {
    $self->{header_row} = $self->row(1);
    DEBUG("Header row found:\n", Dump($self->{header_row}));
  }
  return $self->{header_row};
}

sub name_value_pairs {
  my $self = shift;

  state $check = compile(
    Range->Col, { default => 1 },
    Range->Col, { default => 2 },
    Bool, { optional => 1 }
  );
  my ($name_col, $value_col, $has_headers) = $check->(@_);

  my $cols = $self->cols([$name_col, $value_col]);
  my %pairs = map {
    defined $cols->[0]->[$_]
    ?
    ( strip($cols->[0]->[$_]) => strip($cols->[1]->[$_]) )
    :
    ();
  } (($has_headers ? 1 : 0)..$#{ $cols->[0] });

  return \%pairs;
}

sub tie_ranges { shift->_tie('', @_); }
sub tie_cols { shift->_tie('cols', @_); }
sub tie_rows { shift->_tie('rows', @_); }
sub tie_cells { shift->_tie('cells', @_); }

sub _tie {
  my $self = shift;

  state $check = compile(
    StrMatch[qr/^(cols|rows|cells|)$/],
    slurpy ArrayRef[Range->Range], { optional => 1 },
  );
  my ($which, $ranges) = $check->(@_);

  if (!@$ranges) {
    my $config = $self->config($which) || {};
    $ranges = [ keys %$config ];
  }

  my $method = "range";
  if ($which) {
    $method .= "_$which";
    $method =~ s/s$//;
  }

  my %ranges = map {
    my ($key, $value);
    if (ref($_) eq 'HASH') {
      keys %$_;  # reset each
      ($key, $value) = each %$_;
    } else {
      $key = $value = $_;
    }
    $key => $self->$method($value);
  } @$ranges;

  return $self->tie(%ranges);
}

sub tie {
  my $self = shift;
  my $tie = $self->spreadsheet()->tie(@_);
  tied(%$tie)->default_worksheet($self);
  return $tie;
}

sub submit_requests {
  my $self = shift;
  return $self->spreadsheet()->submit_requests(requests => [ $self ], @_);
}

sub config {
  my $self = shift;
  my $config = $self->{config} or return;
  state $check = compile(Maybe[Str]);
  my ($key) = $check->(@_);
  return defined $key ? $config->{$key} : $config;
}

sub range { Range->new(worksheet => shift, range => shift); }
sub range_col { Col->new(worksheet => shift, range => shift); }
sub range_row { Row->new(worksheet => shift, range => shift); }
sub range_cell { Cell->new(worksheet => shift, range => shift); }
sub range_all { All->new(worksheet => shift); }
sub api { shift->spreadsheet()->api(@_); }
sub sheets { shift->spreadsheet()->sheets(@_); }
sub spreadsheet { shift->{spreadsheet}; }
sub spreadsheet_id { shift->spreadsheet()->spreadsheet_id(); }
sub spreadsheet_config { shift->spreadsheet()->config(shift); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Worksheet - Represents a Worksheet within a Google Spreadsheet.

=head1 DESCRIPTION

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(spreadsheet => <object>, (id => <string> | name => <string> | uri => <string>), config_id => <string>);

Creates a new instance of a Worksheet object. You would not normally
call this directly, you would obtain it from the 
Spreadsheet->open_worksheet routine.

 spreadsheet: The parent object that represents the collection of worksheets.
 id: The id of the worksheet (0, 1, 2 etc).
 name: The name of the worksheet (as shown on the tab).
 uri: The worksheet ID extracted from the overall URI.
 config_id: The custom config for this worksheet.

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

=item config(key<string>)

Returns the custom configuration item with the given key, or the entire
configuration for this worksheet if no key is specified.

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

=item sheets();

Returns the SheetsApi4 object.

=item spreadsheet();

Returns the parent Spreadsheet object.

=item spreadsheet_id();

Returns the parent Spreadsheet id.

=item spreadsheet_config();

Returns the parent Spreadsheet config.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

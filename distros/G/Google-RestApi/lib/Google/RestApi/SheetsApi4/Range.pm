package Google::RestApi::SheetsApi4::Range;

# some private subroutines here are called by RangeGroup,
# so think of RangeGroup as a friend of Range. the routines
# RangeGroup calls are commented thusly:
# "private range routine called here!"

our $VERSION = '0.7';

use Google::RestApi::Setup;

use Carp qw(confess);
use List::Util qw(max);
use List::MoreUtils qw(first_index);
use Scalar::Util qw(blessed looks_like_number);

use aliased 'Google::RestApi::SheetsApi4::Range::Iterator';

use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range";

# should be SCALAR|ARRAYREF|HASHREF but types::standard doesn't currently support AnyOf.
# TODO: Keep an eye on https://rt.cpan.org/Public/Bug/Display.html?id=121841 and alter
# this when anyof is supported. this is currently a pretty big hole, hopefully no one
# will fall into it for a while.
# need a feature of type::parms to do something like:
#  Dim       => StrMatch[qr/^(COLUMN|ROW)$/]->plus_coercions(dim($_)) that would convert
# 'col' to 'COLUMN'. need to explore this and then fix up the areas that use it.
# TODO: switch to ReadOnly
use constant {
  Range     => Defined,
  Col       => Value,
  Row       => Int->where('$_ > 0'),
  Index     => Int->where('$_ > -1'),
  Dim       => StrMatch[qr/^(col|row)/i],
  Dims      => StrMatch[qr/^(col|row)/i],
  DimsAll   => StrMatch[qr/^(col|row|all)/i],
  RangeA1   => '^(?:.+!)*[A-Z]+\d+:[A-Z]+\d+$',
  ColA1     => '^(?:.+!)*([A-Z]+)\d*(?::\1\d*)?$',
  RowA1     => '^(?:.+!)*[A-Z]*(\d+)(?::[A-Z]*\1)?$',
  CellA1    => '^(?:.+!)*[A-Z]+\d+$',
};

sub new {
  my $class = shift;

  state $check = compile_named(
    worksheet => HasMethods[qw(api worksheet_name)],
    range     => Range,
    dim       => DimsAll, { default => 'row' },
  );
  my $self = $check->(@_);
  $self->{dim} = dims($self->{dim});

  return bless $self, $class;
}

sub clear {
  my $self = shift;
  my $range = $self->range();
  DEBUG("Clearing range '$range'");
  my %p = (
    uri    => "/values/$range:clear",
    method => 'post',
  );
  my $response = $self->api(%p);
  $self->clear_cached_values();
  return $response;
}

sub clear_cached_values { delete shift->{cache_range_values}; }

sub refresh_values {
  my $self = shift;
  $self->clear_cached_values();
  return $self->values();
}

# this gets or sets the values of a range immediately, no batch.
# if no values passed, gets them. if values passed, sets them.
sub values {
  my $self = shift;
  my %p = @_;
  $self->_send_values(%p) if defined $p{values};
  return $self->_cache_range_values(%p)->{values};
}

# immediately update the values for a range (no batch).
sub _send_values {
  my $self = shift;

  state $check = compile_named(
    values  => ArrayRef, { optional => 1 }, # ArrayRef->plus_coercions(Str, sub { [ $_ ] } ),
    params  => HashRef, { default => {} },
    content => HashRef, { default => {} },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  
  my $range = $self->range();

  # since we're sending these values, fake a response from the
  # api to store them in our cache.
  # if includeValuesInResponse is sent in the params, then the
  # response will replace the cache again.
  $self->_cache_range_values(
    range          => $range,
    majorDimension => $self->{dim},
    values         => $p->{values},
  );

  $p->{content}->{range} = $range;
  $p->{content}->{values} = delete $p->{values};
  $p->{content}->{majorDimension} = $self->{dim};
  $p->{params}->{valueInputOption} //= 'USER_ENTERED';
  # $p->{params}->{includeValuesInResponse} = 1;
  $p->{uri} = "/values/$range";
  $p->{method} = 'put';

  my $update = $self->api(%$p);

  # this fakes out the batch response with this immediate response.
  # batch response would be in an arrayref, so wrap it thusly.
  return $self->values_response_from_api([ $update ]);
}

# this stores the response to an update request, either batch or immediate:
# ---
# spreadsheetId: 1ky2czjhPArP71a6woeo_dxRr8gBOZZxGAPjOCXJvCwA
# updatedCells: 6
# updatedColumns: 3
# updatedRange: Sheet1!B3:D4
# updatedRows: 2
# if invludeValuesInResponse was requested, the values are stashed
# from the updatedData response key.
# spreadsheet object will call this on a batch update response.
sub values_response_from_api {
  my $self = shift;

  state $check = compile(ArrayRef, { optional => 1 });
  my ($updates) = $check->(@_);
  return if !$updates;

  # shift off the next update from the batch api response. if this is
  # getting called from the spreadsheet object, it means we have an
  # update response to process.
  my $update = shift @$updates;

  # updatedData is included if includeValuesInResponse query param was sent.
  # updatedData:
  #   majorDimension: ROWS
  #   range: Sheet1!A1
  #   values:
  #   - - Fred
  # if the data is included, then replace any cached values with this latest
  # updated set of values.
  $self->_cache_range_values(%{ delete $update->{updatedData} })
    if $update->{updatedData};
  $self->{values_response_from_api} = $update;

  return $self->values();
}

# this returns the values and major dimension for a given range. it will store
# the values returned from an api fetch. it will store the values from a staged
# 'batch_values' call for later update from the api. it will store the values
# from an update if includeValuesInResponse was included.
# cache is in the format:
# majorDimension: ROWS
# values:
# - - Fred
# if a range is included it's a flag that the dim and values are present from
# the returned api call.
sub _cache_range_values {
  my $self = shift;

  my %p = @_;
  # if a range is included, assume this cache is coming from the api as a reply.
  # this is to store the values for this range when includeValuesInResponse is
  # added to the url or content on the original values call. you can replace the
  # original values using the valueRenderOption to replace, say, formulas with their
  # calculated value.
  if ($p{range}) {
    state $check = compile_named(
      majorDimension => Dims,
      range          => StrMatch[qr/.+!/],
      values         => ArrayRef, { optional => 1 }  # will not exist if values aren't set in the ss.
    );
    my $p = $check->(@_);

    my ($worksheet_name) = $p->{range} =~ /(.+)!/;
    $worksheet_name =~ s/'//g;
    LOGDIE "Setting range data to worksheet name '$worksheet_name' that doesn't belong to this range: ", $self->worksheet_name()
      if $worksheet_name ne $self->worksheet_name();
    delete $p->{range};  # we only cache the values and dimensions.
    $self->{cache_range_values} = $p;
  }

  # if the value range was just stored (above) or was previously stored, return it.
  return $self->{cache_range_values} if $self->{cache_range_values};

  # used by iterators to use a 'parent' range to query the values for this 'child'
  # range. this is to reduce network calls when iterating through a range.
  my $shared = $self->{shared};
  if ($shared && $shared->has_values()) {
    my $dim = $shared->{cache_range_values}->{majorDimension};
    my $values = $shared->{cache_range_values}->{values};

    my ($top, $left, $bottom, $right) = $self->offsets($shared);
    my $data;
    if ($dim =~ /^col/i) {
      my @cols = @$values[$left..$right];
      $_ = [ @$_[$top..$bottom] ] foreach (@cols);
      $data = \@cols;
    } else {
      my @rows = @$values[$top..$bottom];
      $_ = [ @$_[$left..$right] ] foreach (@rows);
      $data = \@rows;
    }

    # return a subsection of the cached value for the iterator.
    return {
      majorDimension => $dim,
      values         => $data,
    };
  }

  # no values are found for this range, go get them from the api immediately.
  $p{uri} = sprintf("/values/%s", $self->range());
  $p{params}->{majorDimension} = $self->{dim};
  $self->{cache_range_values} = $self->api(%p);

  $self->{cache_range_values}->{values} //= [];  # in case there's nothing set in the ss.

  return $self->{cache_range_values};
}

# stage batch values get/set for later use by submit_values
sub batch_values {
  my $self = shift;

  state $check = compile_named(
    values => ArrayRef, { optional => 1 },
  );
  my $p = $check->(@_);

  if (defined $p->{values}) {
    # since we're sending these values, fake a response from the
    # api to store them in our cache.
    # if includeValuesInResponse is sent in the params, then the
    # response will replace the cache again.
    $self->_cache_range_values(
        range          => $self->range(),
        majorDimension => $self->{dim},
        values         => $p->{values},
    );
  }

  return if !$self->{cache_range_values};

  return {
    range => $self->range(),
    %{ $self->{cache_range_values} },
  };
}

# tell the api to submit the batch values. the api will call back
# values_response_from_api with the results of the update.
sub submit_values {
  my $self = shift;
  $self->spreadsheet()->submit_values(ranges => [ $self ], @_);
  return $self->values();
}

sub submit_requests {
  my $self = shift;
  my @api = $self->spreadsheet()->submit_requests(ranges => [ $self ], @_);
  return wantarray ? @api : $api[0];
}

sub append {
  my $self = shift;

  state $check = compile_named(
    values  => ArrayRef->plus_coercions(Str, sub { [ $_ ] } ),
    params  => HashRef, { default => {} },
    content => HashRef, { default => {} },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));

  my $range = $self->range();
  $p->{content}->{range} = $range;
  $p->{content}->{values} = delete $p->{values};
  $p->{content}->{majorDimension} = $self->{dim};
  $p->{params}->{valueInputOption} //= 'USER_ENTERED';
  $p->{uri} = "/values/$range:append";
  $p->{method} = 'post';

  return $self->api(%$p);
}

sub normalize_named {
  my $self = shift;
  my $named = $self->named() or return;
  my $range = $named->{range};
  $self->{range} = [
    [ $range->{startColumnIndex} + 1, $range->{startRowIndex} + 1 ],
    [ $range->{endColumnIndex}, $range->{endRowIndex} ],
  ];
  return $self;
}

sub named {
  my $self = shift;
  return if !$self->is_named();
  return $self->spreadsheet()->named_ranges($self->{range});
}

# https://support.google.com/docs/answer/63175?co=GENIE.Platform%3DDesktop&hl=en
sub is_named {
  my $self = shift;

  my $range = $self->{range};

  return if !$range;
  return if ref($range);
  return if length($range) > 250;

  for (
    qr/^\d/,
    qr/^(true|false)/,
    qr/^R\d+C\d+$/,
    qr/^[A-Z]+\d+$/,
    RangeA1, ColA1, RowA1, CellA1,
  ) { return if $range =~ /$_/; }

  return 1;
}

# there are different ways to specify ranges. this came
# about by merging different ideas from different
# spreadsheet implementations.

# single cell:
# A1                      ====> A1
# [A, 1]                  ====> A1
# [[A, 1]]                ====> A1
# [1, 1]                  ====> A1
# [[1, 1]]                ====> A1
# {row => 1, col => A}    ====> A1
# [{row => 1, col => A}]  ====> A1
# {row => 1, col => 1}    ====> A1
# [{row => 1, col => 1}]  ====> A1

# same cell twice gets reduced to single cell:
# [[A, 1], [A, 1]]        ====> A1
# [[1, 1], [1, 1]]        ====> A1
# [{row => 1, col => A}, {row => 1, col => A}]  ====> A1
# [{row => 1, col => 1}, {row => 1, col => 1}]  ====> A1

# column:
# A:A           ====> A:A
# [A]           ====> A:A
# [[A]]         ====> A:A
# [1]           ====> A:A
# [[1]]         ====> A:A
# {col => A}    ====> A:A
# [{col => A}]  ====> A:A
# {col => 1}    ====> A:A
# [{col => 1}]  ====> A:A
# a partial column is still considered a column
# A5:A10        ====> A:A

# row:
# 1:1           ====> 1:1
# [undef, 1]    ====> 1:1
# [[undef, 1]]  ====> 1:1
# 0's are 'valid' in that they are ignored.
# [0, 1]        ====> 1:1
# [[0, 1]]      ====> 1:1
# {row => 1}    ====> 1:1
# [{row => 1}]  ====> 1:1
# a partial row is still considered a row
# D1:1          ====> A:A

# partial rows/columns:
# [[A, 5], [A]]                       ====> A5:A
# [{col => A, row => 5}, {col => A}]  ====> A5:A
# [[5, 1], [undef, 1]]                ====> E1:1
# [[5, 1], [0, 1]]                    ====> E1:1
# [{row => 1, col => 5}, {row => 1}]  ====> E1:1

# ranges:
# A1:B2                                         ====> A1:B2
# [[1,1],[2,2]]                                 ====> A1:B2
# [[A,1],[B,2]]                                 ====> A1:B2
# [{row => 1, col => 1}, {row => 2, col => 2}]  ====> A1:B2
# [{row => 1, col => A}, {row => 2, col => B}]  ====> A1:B2

# mixing is usually ok:
# [A1, [2, 2]]                    ====> A1:B2
# [{row => 1, col => 1}, [2, 2]]  ====> A1:B2
# [{row => 1, col => 1}, B2]      ====> A1:B2

# bad ranges:
# should be able to support this but makes range routine
# too complex, and the simple workaround is to just A1:B2.
# [A1, B2]
sub range {
  my $self = shift;

  return $self->{normalized_range} if $self->{normalized_range};

  $self->normalize_named();

  my $range = $self->{range};
  my ($start_cell, $end_cell);
  if (ref($range) eq 'ARRAY') {
    if (ref($range->[0]) || ref($range->[1])) {
      ($start_cell, $end_cell) = @$range;
    } else {
      $start_cell = $range;
    }
  } elsif (ref($range) eq 'HASH') {
    $start_cell = $range;
  } else {
    ($start_cell, $end_cell) = split(':', $range);
  }
  $start_cell = $self->_cell_to_a1($start_cell);
  $end_cell = $self->_cell_to_a1($end_cell) if $end_cell;

  $range = $start_cell;
  $end_cell = $start_cell if $start_cell =~ /^\d+$/;
  $end_cell = $start_cell if $start_cell =~ /^[A-Z]+$/;

  $end_cell = undef if defined $end_cell &&
    $start_cell eq $end_cell &&
    $start_cell =~ 
      /          # turn A1:A1 to A1
      ^[A-Z]     # starts with a column
      [A-Z\d]*   # has cap letters and digits in the middle bit
      \d$        # ends with a digit
      /x;

  # TODO: sort start range and end range before storing.
  my $name = $self->worksheet_name();
  $range .= ":$end_cell" if defined $end_cell;
  $range = "'$name'!$range";

  DEBUG(sprintf("Range '%s' converted to '$range'", $self->_flatten_range($self->{range})));
  $self->{normalized_range} = $range;

  return $range;
}

# these are just used for debug message just above
# to display the original range in a pretty format.
sub _flatten_range {
  my $self = shift;

  my $range = shift;
  return 'undef' if !$range;
  return $range if !ref($range);

  return _flatten_hash($range) if ref($range) eq 'HASH';
  return _flatten_array($range)
    if ref($range) eq 'ARRAY' && scalar @$range == 1;

  # recursion... here be potential dragons.
  return sprintf('[ %s, %s ]',
    $self->_flatten_range($range->[0]),
    $self->_flatten_range($range->[1]),
  );
}

sub _flatten_hash {
  my $hash = shift;
  my $flat = '{ ';
  $flat .= "$_ => " . ($hash->{$_} || 'undef') . ", "
    foreach (keys %$hash);
  $flat =~ s/, $/ \}/;
  return $flat;
}

sub _flatten_array {
  my $array = shift;
  my $flat = '[ ';
  $flat .= $_ || 'undef' . ", " foreach (@$array);
  $flat =~ s/, $/ \]/;
  return $flat;
}

sub is_colA1 {
  my $col = shift;
  return if !defined $col;
  return if ref($col);
  my $colA1 = ColA1;
  my $cellA1 = CellA1;
  return 1 if !is_cellA1($col) && $col =~ /$colA1/;
  return;
}

sub is_rowA1 {
  my $row = shift;
  return if !defined $row;
  return if ref($row);
  my $rowA1 = RowA1;
  my $cellA1 = CellA1;
  return 1 if !is_cellA1($row) && $row =~ /$rowA1/;
  return;
}

sub is_cellA1 {
  my $cell = shift;
  return if !defined $cell;
  return if ref($cell);
  my $cellA1 = CellA1;
  return 1 if $cell =~ qr/$cellA1/;
  return;
}

sub _col_to_a1 {
  my $self = shift;

  my $col = shift;
  return '' if !$col;

  return $col if is_colA1($col);
  return $col if looks_like_number($col) && $col < 1;  # allow this to fail above.
  return $self->_col_i2a($col) if looks_like_number($col);

  my $config = $self->config('cols');
  if ($config) {
    my $config_col = $config->{$col};
    return $self->_col_i2a($config_col)
      if $config_col && looks_like_number($config_col);
    $col = $config_col if $config_col;
  }

  my $headers = $self->worksheet()->header_row();
  my $i = first_index { $_ eq $col; } @$headers;
  if ($i > -1) {
    $i++;
    $config->{$col} = $i if $config;
    return $self->_col_i2a($i)
  }

  confess "Unable to translate column '$col' into a worksheet col";
}

sub _row_to_a1 {
  my $self = shift;

  my $row = shift;
  return '' if !$row;

  return $row if is_rowA1($row);

  my $config = $self->config('rows');
  if ($config) {
    my $config_row = $config->{$row};
    return $config_row
      if $config_row && looks_like_number($config_row);
    $row = $config_row if $config_row;
  }

  my $headers = $self->worksheet()->header_col();
  my $i = first_index { $_ eq $row; } @$headers;
  if ($i > -1) {
    $i++;
    $config->{$row} = $i if $config;
    return $i;
  }

  confess "Unable to translate row '$row' into a worksheet row";
}

sub _cell_to_a1 {
  my $self = shift;

  state $check = compile(Defined);
  my ($cell) = $check->(@_);

  return $cell if is_cellA1($cell);

  my ($col, $row);
  if (ref($cell) eq 'ARRAY') {
    ($col, $row) = @$cell;
    $col = $self->_col_to_a1($col);
    $row = $self->_row_to_a1($row);
  } elsif (ref($cell) eq 'HASH') {
    $col = $self->_col_to_a1($cell->{col});
    $row = $self->_row_to_a1($cell->{row});
  }

  confess sprintf("Unable to translate cell '%s' into a worksheet cell", $self->_flatten_range($cell))
    if !$col && !$row;
  confess "Unable to translate col '$col' into a worksheet col" if looks_like_number($col);
  confess "Unable to translate row '$row' into a worksheet row" if looks_like_number($row) && $row < 1;

  return "$col$row";
}

sub _col_i2a {
  my $self = shift;

  my $n = shift;

  my $l = int($n / 27);
  my $r = $n - $l * 26;

  return $l > 0 ? (pack 'CC', $l+64, $r+64) : (pack 'C', $r+64);
}

sub range_to_hash {
  my $self = shift;

  my $range = $self->range_to_array();

  return [ map { { col => $_->[0], row => $_->[1] } } @$range ]
    if ref($range->[0]);

  my %hash;
  $hash{col} = $range->[0];
  $hash{row} = $range->[1];

  return \%hash;
}

sub range_to_array {
  my $self = shift;

  my $range = $self->range();
  ($range) = $range =~ /!(.+)/;
  $range or LOGDIE "Unable to convert range to array: ", $self->range();

  my ($start_cell, $end_cell) = split(':', $range);
  $end_cell = undef if defined $end_cell && $start_cell eq $end_cell;
  $start_cell = $self->_cell_to_array($start_cell);
  $end_cell = $self->_cell_to_array($end_cell) if $end_cell;

  return $end_cell ? [$start_cell, $end_cell] : $start_cell;
}

sub range_to_index {
  my $self = shift;

  my $array = $self->range_to_array();
  $array = [$array, $array] if !ref($array->[0]);

  my %range;
  $range{sheetId} = $self->worksheet()->worksheet_id();
  $range{startColumnIndex} = max($array->[0]->[0] - 1, 0);
  $range{startRowIndex} = max($array->[0]->[1] - 1, 0);
  $range{endColumnIndex} = $array->[1]->[0];
  $range{endRowIndex} = $array->[1]->[1];

  return \%range;
}

sub range_to_dimension {
  my $self = shift;

  state $check = compile(Dim);
  my ($dims) = $check->(@_);
  $dims = dims($dims);

  my $array = $self->range_to_array();
  $array = [$array, $array] if !ref($array->[0]);
  my $start = $dims =~ /^col/i ? $array->[0]->[0] : $array->[0]->[1];
  my $end = $dims =~ /^col/i ? $array->[1]->[0] : $array->[1]->[1];

  my %range;
  $range{sheetId} = $self->worksheet()->worksheet_id();
  $range{startIndex} = max($start - 1, 0);
  $range{endIndex} = $end;
  $range{dimension} = $dims;

  return \%range;
}

sub _cell_to_array {
  my $self = shift;

  my $cell = shift;
  my ($col, $row) = $cell =~ /^([A-Z]*)(\d*)$/;
  $col = $self->_col_a2i($col) if $col;

  $col ||= 0;
  $row ||= 0;

  return [$col, $row];
}

# taken from https://metacpan.org/source/DOUGW/Spreadsheet-ParseExcel-0.65/lib/Spreadsheet/ParseExcel/Utility.pm
sub _col_a2i {
  my $self = shift;

  state $check = compile(StrMatch[qr/^[A-Z]+$/]);
  my ($a) = $check->(@_);

  my $result = 0;
  my $incr = 0;
  for (my $i = length($a); $i > 0 ; $i--) {
    my $char = substr($a, $i - 1);
    my $curr += ord(lc($char)) - ord('a') + 1;
    $curr *= $incr if ($incr);
    $result += $curr;
    $incr += 26;
  }

  return $result;
}

sub offset {
  my $self = shift;

  state $check = compile_named(
    col    => Int, { default => 0 },
    row    => Int, { default => 0 },
    top    => Int, { default => 0 },
    left   => Int, { default => 0 },
    bottom => Int, { default => 0 },
    right  => Int, { default => 0 },
  );
  my $p = $check->(@_);

  my $range = $self->range_to_hash();
  if (ref($range) eq 'ARRAY') {
    foreach my $dim (@$range) {
      $dim->{$_} += $p->{$_} foreach (qw(col row));
    }
    $range->[0]->{row} += $p->{top};
    $range->[0]->{col} += $p->{left};
    $range->[1]->{row} += $p->{bottom};
    $range->[1]->{col} += $p->{right};
  } else {
    $range->{$_} += $p->{$_} foreach (qw(col row));
    $range->{row} += $p->{top};
    $range->{col} += $p->{left};
    $range->{row} += $p->{bottom};
    $range->{col} += $p->{right};
  }

  return (ref($self))->new(worksheet => $self->worksheet(), range => $range);
}

sub offsets {
  my $self = shift;
  state $check = compile(HasMethods['range']);
  my ($other) = $check->(@_);
  my $range = $self->range_to_hash();
  $range = [ $range, $range ] if ref($range) eq 'HASH';
  $other = $other->range_to_hash();
  $other = [ $other, $other ] if ref($other) eq 'HASH';
  my $top = $range->[0]->{row} - $other->[0]->{row};
  my $left = $range->[0]->{col} - $other->[0]->{col};
  my $bottom = $range->[1]->{row} - $other->[0]->{row};
  my $right = $range->[1]->{col} - $other->[0]->{col};
  return ( $top, $left, $bottom, $right );
}

sub iterator {
  my $self = shift;
  return Iterator->new(@_, range => $self);
}

sub is_inside {
  my $self = shift;
  state $check = compile(HasMethods['range']);
  my ($other) = $check->(@_);
  my $range = $self->range_to_hash();
  $range = [ $range, $range ] if ref($range) eq 'HASH';
  $other = $other->range_to_hash();
  $other = [ $other, $other ] if ref($other) eq 'HASH';
  return 1 if 
    $range->[0]->{col} >= $other->[0]->{col} &&
    $range->[0]->{row} >= $other->[0]->{row} &&
    $range->[1]->{col} <= $other->[1]->{col} &&
    $range->[1]->{row} <= $other->[1]->{row}
  ;
  return;
}

sub share_values {
  my $self = shift;
  my $shared = shift;
  return if !$self->is_inside($shared);
  $self->{shared} = $shared;
  return $shared;
}

sub api { shift->worksheet()->api(@_); }
sub dimension { shift->{dim}; }
sub has_values { shift->{cache_range_values}; }
sub worksheet { shift->{worksheet}; }
sub worksheet_name { shift->worksheet()->worksheet_name(@_); }
sub worksheet_id { shift->worksheet()->worksheet_id(@_); }
sub spreadsheet { shift->worksheet()->spreadsheet(@_); }
sub spreadsheet_id { shift->spreadsheet()->spreadsheet_id(@_); }
sub config { shift->worksheet()->config(@_); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range - Represents a range in a Worksheet.

=head1 DESCRIPTION

A Range object that represents a range in a remote spreadsheet. These are
normally short-lived objects used to set up and execute a remote action.
Keep in mind that the remote spreadsheet can be potentially updated by
many people, so a compromise must always be reached between holding a copy
of the local cell values and the number of network calls to the Google
API to keep the values current.

A range can be specified in whatever way is most convenient. For cells:

 * A1 notation: A1
 * Hash: { col => (A|1), row => 1 }
 * Array: [ (A|1), 1 ]

For ranges:

 * A1 notation: A1:B2
 * Hash: [ { col => (A|1), row => 1 }, { col => (B|2), row => 2 } ]
 * Array: [ [ (A|1), 1 ], [ (B|2), 2 ] ]

For columns:

 * A1 notation: A or A:A
 * Hash: { col => (A|1) }
 * Array: [ A|1 ]

For rows:

 * A1 notation: 1 or 1:1
 * Hash: { row => 1 }
 * Array: [ <false>, 1 ]

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(worksheet => <Worksheet>, range => <Range>, dim => (col|row));

Creates a new range object for the given worksheet.

 worksheet: The parent Worksheet object for this range.
 range: The range for this object, either A1 notation, hash {col => x, row => x} or array [col, row].
 dim: The major dimension for this range, either 'col' or 'row', defaults to 'row'.

You would not normally call this directly, you'd use Worksheet::range*
methods to create the range object for you.

=item api(%args);

Calls the parent worksheet's 'api' routine with the range added into
the URI or content appropriately.

You would not normally call this directly unless you were
making a Google API call not currently supported by this API
framework.

=item clear();

Clears the values using Google API's 'A1:clear' call.

=item refresh_values();

Immediately refreshes the values from the spreadsheet.

=item values(values => <arrayref>, %args);

Immediately gets or sets the values using Google API's 'get' or 'update'.

 values: The array ref of cells to update.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item batch_values(values => <arrayref>);

Gets or sets the queued batch values that will be sent to Google API
at a later time. Call 'submit_values' to send them later.

 values: The array ref of cells to update.

=item submit_values(%args);

Sends the previously queued batch values to Google API, if any.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item submit_requests(%args);

Sends the previously queued requests (formatting, sheet properties etc)
to Google API, if any.

'args' are passed to the SheetsApi4's 'api' routine so you may add
extra arguments to the 'params' or 'content' as necessary.

=item normalize_named();

If this is a 'named range', get the named range property from the
spreadsheet and set this object's real range that the named range
represents.

=item named();

Returns the 'named range' for this range, if any.

=item is_named();

Returns a true value if this range represents a 'named range'. See:
https://support.google.com/docs/answer/63175?co=GENIE.Platform%3DDesktop&hl=en

=item range();

Returns the A1 notation for this range.

=item range_to_hash();

Returns the hash representation for this range (e.g. {col => 1, row => 1}).

=item range_to_array();

Returns the array representation for this range (e.g. [1, 1]).

=item range_to_index();

Returns the index hash representation for this range, used for formatting
requests etc. You would not normally need to call this yourself.

=item range_to_dimension();

Returns the dimension hash representation for this range, used for
insert requests etc. You would not normally need to call this yourself.

=item offset(col => <int>, row => <int>, top => <int>, left => <int>, bottom => <int>, right => <int>);

Returns a new range object offset from this range.

 col: Optional offset of the new range by this many columns.
 row: Optional offset of the new range by this many rows.
 top: Optional offset of the new range with the new top.
 left: Optional offset of the new range with the new left.
 bottom: Optional offset of the new range with the new bottom.
 right: Optional offset of the new range with the new right.

=item offsets(range<Range>);

Returns the offsets of this range from the given range in an
array (top, left, bottom, right).

=item iterator(%args);

Returns an iterator for this range. Any 'args' are passed to the
'new' routine for the iterator.

=item is_inside(range<Range>);

Returns a true value if the given range fits entirely inside this
range.

=item share_values(range<Range>);

Share the cell values between this range and the passed range.

Normally ranges are short-lived, throw-away objects used to interact
with the Google API. Range objects work independently and don't
share any common storage of cells. No attempt is made to share a
common, local grid that mirrors what's in the remote spreadsheet.
The spreadsheet is a shared resource that can be updated concurrently
by multiple users, so attempting to mirror it locally is a waste of
time unless some kind of listener is provided that can be used to
syncronize the remote updates with the local copy (which Google doesn't).

However, for some cases, like iterators, we can set up ranges to
share values between them for a short time in order to reduce the
number of network calls to the Google API while you iterate over
the cells. When the iterated cell values are updated, the parent
range's value is also updated.

So far, this is the only use-case I can see for sharing the cell
grid between ranges.

=item dimension();

Returns this range's major dimension.

=item has_values();

Returns a true value if this range's values have been set either via
'values' or 'batch_values' routines.

=item worksheet();

Returns the parent Worksheet object.

=item worksheet_name();

Returns the parent Worksheet name.

=item worksheet_id();

Returns the parent Worksheet ID.

=item spreadsheet();

Returns the parent Spreadsheet object.

=item spreadsheet_id();

Returns the parent Spreadsheet ID.

=item config();

Returns the parent Worksheet config hash.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

package Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

use aliased "Google::RestApi::SheetsApi4::Request";

use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet";

sub worksheet_id { LOGDIE "Pure virtual function 'worksheet_id' must be overridden"; }

sub ws_rename { shift->update_worksheet_properties(properties => { title => shift }); }
sub ws_index { shift->update_worksheet_properties(properties => { index => shift }); }
sub ws_hide { shift->update_worksheet_properties(properties => { hidden => bool(shift) }); }
sub ws_hidden { ws_hide(@_); }
sub ws_right_to_left { shift->update_worksheet_properties(properties => { rightToLeft => bool(shift) }); }
sub ws_left_to_right { shift->ws_right_to_left(bool(shift) eq 'true' ? 0 : 1); }

sub _ws_tab_rgba { shift->ws_tab_color({ (shift) => (shift // 1) }); }
sub ws_tab_red { shift->_ws_tab_rgba('red' => shift); }
sub ws_tab_blue { shift->_ws_tab_rgba('blue' => shift); }
sub ws_tab_green { shift->_ws_tab_rgba('green' => shift); }
sub ws_tab_alpha { shift->_ws_tab_rgba('alpha' => shift); }
sub ws_tab_black { shift->ws_tab_color(cl_black()); }
sub ws_tab_white { shift->ws_tab_color(cl_white()); }
sub ws_tab_color { shift->update_worksheet_properties(properties => { tabColor => shift }); }

sub freeze_cols { shift->_freeze('col', @_); }
sub freeze_rows { shift->_freeze('row', @_); }
sub unfreeze_cols { shift->freeze_cols(); }
sub unfreeze_rows { shift->freeze_rows(); }
sub _freeze {
  my $self = shift;

  my $dim = shift;
  state $check = compile(PositiveOrZeroInt, { default => 0 });
  my ($count) = $check->(@_);

  # "frozenColumnCount" or "frozenRowCount".
  my $frozen = "frozen" . ($dim eq 'col' ? "Column" : "Row") . "Count";

  return $self->update_worksheet_properties(
    properties => { gridProperties => { $frozen => $count }, },
    fields     => "gridProperties.$frozen",
  );
}

sub update_worksheet_properties {
  my $self = shift;

  state $check = compile_named(
    properties => HashRef,
    fields     => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  my $properties = $p->{properties};
  my $fields = $p->{fields} || join(',', sort keys %$properties);

  $self->batch_requests(
    updateSheetProperties => {
      properties => {
        sheetId => $self->worksheet_id(),
        %$properties,
      },
      fields     => $fields,
    },
  );

  return $self;
}

sub clear_values { shift->_clear("userEnteredValue"); }
sub clear_formatting { shift->_clear("userEnteredFormat"); }
sub _clear {
  my $self = shift;

  my $fields = shift;
  my $range = shift || { sheetId => $self->worksheet_id() };
  $self->batch_requests(
    updateCells => {
      range  => $range,
      fields => $fields,
    },
  );

  return $self;
}

sub reset { shift->clear_formatting()->clear_values()->unfreeze_cols()->unfreeze_rows(); }

sub delete_worksheet {
  my $self = shift;
  $self->batch_requests(
    deleteSheet => { sheetId => $self->worksheet_id() }
  );
  return $self;
}

sub duplicate_worksheet {
  my $self = shift;

  state $check = compile_named(
    new_name       => Optional[Str],
    insert_index   => Optional[Int],
    new_sheet_id   => Optional[Int],
  );
  my $p = $check->(@_);

  my %request = (sourceSheetId => $self->worksheet_id());
  $request{newSheetName} = $p->{new_name} if defined $p->{new_name};
  $request{insertSheetIndex} = $p->{insert_index} if defined $p->{insert_index};
  $request{newSheetId} = $p->{new_sheet_id} if defined $p->{new_sheet_id};

  $self->batch_requests(duplicateSheet => \%request);

  return $self;
}

sub update_dimension_properties {
  my $self = shift;

  state $check = compile_named(
    dimension  => Str,
    start      => Int,
    end        => Optional[Int],
    properties => HashRef,
    fields     => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  my $dim = uc($p->{dimension}) eq 'COL' ? 'COLUMNS' : 'ROWS';
  my $end = $p->{end} // ($p->{start} + 1);
  my $fields = $p->{fields} || join(',', sort keys %{ $p->{properties} });

  $self->batch_requests(
    updateDimensionProperties => {
      range => {
        sheetId    => $self->worksheet_id(),
        dimension  => $dim,
        startIndex => $p->{start},
        endIndex   => $end,
      },
      properties => $p->{properties},
      fields     => $fields,
    },
  );

  return $self;
}

sub row_height {
  my $self = shift;
  my ($start, $end, $height) = @_;
  $self->update_dimension_properties(
    dimension  => 'row',
    start      => $start,
    end        => $end,
    properties => { pixelSize => $height },
  );
}

sub col_width {
  my $self = shift;
  my ($start, $end, $width) = @_;
  $self->update_dimension_properties(
    dimension  => 'col',
    start      => $start,
    end        => $end,
    properties => { pixelSize => $width },
  );
}

sub hide_rows {
  my $self = shift;
  my ($start, $end) = @_;
  $self->update_dimension_properties(
    dimension  => 'row',
    start      => $start,
    end        => $end,
    properties => { hiddenByUser => bool(1) },
  );
}

sub hide_cols {
  my $self = shift;
  my ($start, $end) = @_;
  $self->update_dimension_properties(
    dimension  => 'col',
    start      => $start,
    end        => $end,
    properties => { hiddenByUser => bool(1) },
  );
}

sub show_rows {
  my $self = shift;
  my ($start, $end) = @_;
  $self->update_dimension_properties(
    dimension  => 'row',
    start      => $start,
    end        => $end,
    properties => { hiddenByUser => bool(0) },
  );
}

sub show_cols {
  my $self = shift;
  my ($start, $end) = @_;
  $self->update_dimension_properties(
    dimension  => 'col',
    start      => $start,
    end        => $end,
    properties => { hiddenByUser => bool(0) },
  );
}

sub append_dimension {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
    length    => Int,
  );
  my $p = $check->(@_);

  my $dim = uc($p->{dimension}) eq 'COL' ? 'COLUMNS' : 'ROWS';

  $self->batch_requests(
    appendDimension => {
      sheetId   => $self->worksheet_id(),
      dimension => $dim,
      length    => $p->{length},
    },
  );

  return $self;
}

sub append_rows { shift->append_dimension(dimension => 'row', length => shift); }
sub append_cols { shift->append_dimension(dimension => 'col', length => shift); }

sub auto_resize_dimensions {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
    start     => Int,
    end       => Optional[Int],
  );
  my $p = $check->(@_);

  my $dim = uc($p->{dimension}) eq 'COL' ? 'COLUMNS' : 'ROWS';
  my $end = $p->{end} // ($p->{start} + 1);

  $self->batch_requests(
    autoResizeDimensions => {
      dimensions => {
        sheetId    => $self->worksheet_id(),
        dimension  => $dim,
        startIndex => $p->{start},
        endIndex   => $end,
      },
    },
  );

  return $self;
}

sub auto_resize_rows {
  my $self = shift;
  my ($start, $end) = @_;
  $self->auto_resize_dimensions(dimension => 'row', start => $start, end => $end);
}

sub auto_resize_cols {
  my $self = shift;
  my ($start, $end) = @_;
  $self->auto_resize_dimensions(dimension => 'col', start => $start, end => $end);
}

sub set_basic_filter {
  my $self = shift;

  state $check = compile_named(
    range   => Optional[HashRef],
    criteria => Optional[HashRef],
    sort_specs => Optional[ArrayRef],
  );
  my $p = $check->(@_);

  my $range = $p->{range} || { sheetId => $self->worksheet_id() };
  my %filter = (range => $range);
  $filter{criteria} = $p->{criteria} if $p->{criteria};
  $filter{sortSpecs} = $p->{sort_specs} if $p->{sort_specs};

  $self->batch_requests(
    setBasicFilter => {
      filter => \%filter,
    },
  );

  return $self;
}

sub clear_basic_filter {
  my $self = shift;

  $self->batch_requests(
    clearBasicFilter => {
      sheetId => $self->worksheet_id(),
    },
  );

  return $self;
}

sub add_conditional_format_rule {
  my $self = shift;

  state $check = compile_named(
    ranges    => ArrayRef,
    rule      => HashRef,
    index     => Int, { default => 0 },
  );
  my $p = $check->(@_);

  $self->batch_requests(
    addConditionalFormatRule => {
      rule => {
        ranges => $p->{ranges},
        %{ $p->{rule} },
      },
      index => $p->{index},
    },
  );

  return $self;
}

sub update_conditional_format_rule {
  my $self = shift;

  state $check = compile_named(
    index     => Int,
    rule      => Optional[HashRef],
    new_index => Optional[Int],
  );
  my $p = $check->(@_);

  my %request = (index => $p->{index});
  $request{rule} = $p->{rule} if $p->{rule};
  $request{newIndex} = $p->{new_index} if defined $p->{new_index};

  $self->batch_requests(updateConditionalFormatRule => \%request);

  return $self;
}

sub delete_conditional_format_rule {
  my $self = shift;

  state $check = compile(Int);
  my ($index) = $check->(@_);

  $self->batch_requests(
    deleteConditionalFormatRule => {
      sheetId => $self->worksheet_id(),
      index   => $index,
    },
  );

  return $self;
}

sub add_banding {
  my $self = shift;

  state $check = compile_named(
    range                 => HashRef,
    row_properties        => Optional[HashRef],
    column_properties     => Optional[HashRef],
  );
  my $p = $check->(@_);

  my %banded_range = (range => $p->{range});
  $banded_range{rowProperties} = $p->{row_properties} if $p->{row_properties};
  $banded_range{columnProperties} = $p->{column_properties} if $p->{column_properties};

  $self->batch_requests(
    addBanding => {
      bandedRange => \%banded_range,
    },
  );

  return $self;
}

sub update_banding {
  my $self = shift;

  state $check = compile_named(
    id                    => Str,
    range                 => Optional[HashRef],
    row_properties        => Optional[HashRef],
    column_properties     => Optional[HashRef],
    fields                => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  my %banded_range = (bandedRangeId => $p->{id});
  $banded_range{range} = $p->{range} if $p->{range};
  $banded_range{rowProperties} = $p->{row_properties} if $p->{row_properties};
  $banded_range{columnProperties} = $p->{column_properties} if $p->{column_properties};

  my @field_list;
  push @field_list, 'range' if $p->{range};
  push @field_list, 'rowProperties' if $p->{row_properties};
  push @field_list, 'columnProperties' if $p->{column_properties};
  my $fields = $p->{fields} || join(',', @field_list);

  $self->batch_requests(
    updateBanding => {
      bandedRange => \%banded_range,
      fields      => $fields,
    },
  );

  return $self;
}

sub delete_banding {
  my $self = shift;

  state $check = compile(Str);
  my ($id) = $check->(@_);

  $self->batch_requests(
    deleteBanding => {
      bandedRangeId => $id,
    },
  );

  return $self;
}

sub add_dimension_group {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
    start     => Int,
    end       => Int,
  );
  my $p = $check->(@_);

  my $dim = uc($p->{dimension}) eq 'COL' ? 'COLUMNS' : 'ROWS';

  $self->batch_requests(
    addDimensionGroup => {
      range => {
        sheetId    => $self->worksheet_id(),
        dimension  => $dim,
        startIndex => $p->{start},
        endIndex   => $p->{end},
      },
    },
  );

  return $self;
}

sub delete_dimension_group {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
    start     => Int,
    end       => Int,
  );
  my $p = $check->(@_);

  my $dim = uc($p->{dimension}) eq 'COL' ? 'COLUMNS' : 'ROWS';

  $self->batch_requests(
    deleteDimensionGroup => {
      range => {
        sheetId    => $self->worksheet_id(),
        dimension  => $dim,
        startIndex => $p->{start},
        endIndex   => $p->{end},
      },
    },
  );

  return $self;
}

sub update_dimension_group {
  my $self = shift;

  state $check = compile_named(
    dimension      => Str,
    start          => Int,
    end            => Int,
    depth          => Int,
    collapsed      => Bool,
  );
  my $p = $check->(@_);

  my $dim = uc($p->{dimension}) eq 'COL' ? 'COLUMNS' : 'ROWS';

  $self->batch_requests(
    updateDimensionGroup => {
      dimensionGroup => {
        range => {
          sheetId    => $self->worksheet_id(),
          dimension  => $dim,
          startIndex => $p->{start},
          endIndex   => $p->{end},
        },
        depth     => $p->{depth},
        collapsed => bool($p->{collapsed}),
      },
      fields => 'collapsed',
    },
  );

  return $self;
}

sub group_rows {
  my $self = shift;
  my ($start, $end) = @_;
  $self->add_dimension_group(dimension => 'row', start => $start, end => $end);
}

sub group_cols {
  my $self = shift;
  my ($start, $end) = @_;
  $self->add_dimension_group(dimension => 'col', start => $start, end => $end);
}

sub ungroup_rows {
  my $self = shift;
  my ($start, $end) = @_;
  $self->delete_dimension_group(dimension => 'row', start => $start, end => $end);
}

sub ungroup_cols {
  my $self = shift;
  my ($start, $end) = @_;
  $self->delete_dimension_group(dimension => 'col', start => $start, end => $end);
}

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet - Build Google API's batchRequests for a Worksheet.

=head1 DESCRIPTION

Deriving from the Request::Spreadsheet object, this adds the ability to create
requests that have to do with worksheet properties.

See the description and synopsis at Google::RestApi::SheetsApi4::Request.
and Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

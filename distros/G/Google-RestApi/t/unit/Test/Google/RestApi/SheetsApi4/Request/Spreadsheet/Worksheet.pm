package Test::Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet';

use parent 'Test::Unit::TestBase';

init_logger;

# Clear any pending requests before each test to ensure test isolation
sub setup : Test(setup) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();
  my $ws = $self->mock_worksheet();
  # Clear any pending requests from previous tests at all levels
  $ss->{requests} = [];
  $ws->{requests} = [];
  return;
}

sub ws_format : Tests() {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $ws = {
    updateSheetProperties => {
      properties => {
        sheetId => $ws0->worksheet_id(),
      },
      fields     => '',
    },
  };
  my $properties = $ws->{updateSheetProperties}->{properties};

  is $ws0->ws_rename('Bela'), $ws0, "Rename should return same worksheet";
  $properties->{title} = 'Bela'; _add_field($ws, 'title');
  my @requests = $ws0->batch_requests();
  is_deeply $requests[0], $ws, "Rename should be staged";

  is $ws0->ws_index(1), $ws0, "Index should return same worksheet";
  $properties->{index} = 1; _add_field($ws, 'index');
  @requests = $ws0->batch_requests();
  is_deeply $requests[0], $ws, "Index should be staged";

  is $ws0->ws_hide(1), $ws0, "Hide should return same worksheet";
  $properties->{hidden} = 'true'; _add_field($ws, 'hidden');
  @requests = $ws0->batch_requests();
  is_deeply $requests[0], $ws, "Hide should be staged";

  is $ws0->ws_right_to_left(1), $ws0, "Right to left should return same worksheet";
  $properties->{rightToLeft} = 'true'; _add_field($ws, 'rightToLeft');
  @requests = $ws0->batch_requests();
  is_deeply $requests[0], $ws, "Right to left should be staged";

  is $ws0->ws_left_to_right(1), $ws0, "Left to right should return same worksheet";
  $properties->{rightToLeft} = 'false';
  @requests = $ws0->batch_requests();
  is_deeply $requests[0], $ws, "Left to right should be staged";

  $ws0->ws_right_to_left();
  $properties->{rightToLeft} = 'true';
  @requests = $ws0->batch_requests();
  is_deeply $requests[0], $ws, "Undefined right to left should be staged";

  $ws0->ws_left_to_right();
  $properties->{rightToLeft} = 'false';
  @requests = $ws0->batch_requests();
  is_deeply $requests[0], $ws, "Undefined left to right should be staged";

  $ws0->submit_requests();

  return;
}

sub _add_field {
  my ($ws, $field) = (@_);
  my %fields = map { $_ => 1; } split(',', $ws->{updateSheetProperties}->{fields}), $field;
  $ws->{updateSheetProperties}->{fields} = join(',', sort keys %fields);
  return;
}

sub ws_duplicate : Tests(2) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();

  is $ws0->duplicate_worksheet(new_name => 'Copy of Sheet'), $ws0, "duplicate_worksheet should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    duplicateSheet => {
      sourceSheetId => $ws0->worksheet_id(),
      newSheetName  => 'Copy of Sheet',
    },
  };
  is_deeply $requests[0], $expected, "duplicate_worksheet should be staged";

  $ws0->submit_requests();

  return;
}

sub ws_update_dimension_properties : Tests(8) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();

  is $ws0->row_height(0, 5, 30), $ws0, "row_height should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    updateDimensionProperties => {
      range => {
        sheetId    => $ws0->worksheet_id(),
        dimension  => 'ROWS',
        startIndex => 0,
        endIndex   => 5,
      },
      properties => { pixelSize => 30 },
      fields     => 'pixelSize',
    },
  };
  is_deeply $requests[0], $expected, "row_height should be staged";

  $ws0->submit_requests();

  is $ws0->col_width(0, 3, 150), $ws0, "col_width should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected->{updateDimensionProperties}->{range}->{dimension} = 'COLUMNS';
  $expected->{updateDimensionProperties}->{range}->{endIndex} = 3;
  $expected->{updateDimensionProperties}->{properties}->{pixelSize} = 150;
  is_deeply $requests[0], $expected, "col_width should be staged";

  $ws0->submit_requests();

  is $ws0->hide_rows(5, 10), $ws0, "hide_rows should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected = {
    updateDimensionProperties => {
      range => {
        sheetId    => $ws0->worksheet_id(),
        dimension  => 'ROWS',
        startIndex => 5,
        endIndex   => 10,
      },
      properties => { hiddenByUser => 'true' },
      fields     => 'hiddenByUser',
    },
  };
  is_deeply $requests[0], $expected, "hide_rows should be staged";

  $ws0->submit_requests();

  is $ws0->show_cols(2, 4), $ws0, "show_cols should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected->{updateDimensionProperties}->{range}->{dimension} = 'COLUMNS';
  $expected->{updateDimensionProperties}->{range}->{startIndex} = 2;
  $expected->{updateDimensionProperties}->{range}->{endIndex} = 4;
  $expected->{updateDimensionProperties}->{properties}->{hiddenByUser} = 'false';
  is_deeply $requests[0], $expected, "show_cols should be staged";

  $ws0->submit_requests();

  return;
}

sub ws_append_dimension : Tests(4) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();

  is $ws0->append_rows(10), $ws0, "append_rows should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    appendDimension => {
      sheetId   => $ws0->worksheet_id(),
      dimension => 'ROWS',
      length    => 10,
    },
  };
  is_deeply $requests[0], $expected, "append_rows should be staged";

  $ws0->submit_requests();

  is $ws0->append_cols(5), $ws0, "append_cols should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected->{appendDimension}->{dimension} = 'COLUMNS';
  $expected->{appendDimension}->{length} = 5;
  is_deeply $requests[0], $expected, "append_cols should be staged";

  $ws0->submit_requests();

  return;
}

sub ws_auto_resize : Tests(4) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();

  is $ws0->auto_resize_rows(0, 10), $ws0, "auto_resize_rows should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    autoResizeDimensions => {
      dimensions => {
        sheetId    => $ws0->worksheet_id(),
        dimension  => 'ROWS',
        startIndex => 0,
        endIndex   => 10,
      },
    },
  };
  is_deeply $requests[0], $expected, "auto_resize_rows should be staged";

  $ws0->submit_requests();

  is $ws0->auto_resize_cols(0, 5), $ws0, "auto_resize_cols should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected->{autoResizeDimensions}->{dimensions}->{dimension} = 'COLUMNS';
  $expected->{autoResizeDimensions}->{dimensions}->{endIndex} = 5;
  is_deeply $requests[0], $expected, "auto_resize_cols should be staged";

  $ws0->submit_requests();

  return;
}

sub ws_basic_filter : Tests(4) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();

  is $ws0->set_basic_filter(), $ws0, "set_basic_filter should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    setBasicFilter => {
      filter => {
        range => { sheetId => $ws0->worksheet_id() },
      },
    },
  };
  is_deeply $requests[0], $expected, "set_basic_filter should be staged";

  $ws0->submit_requests();

  is $ws0->clear_basic_filter(), $ws0, "clear_basic_filter should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected = {
    clearBasicFilter => {
      sheetId => $ws0->worksheet_id(),
    },
  };
  is_deeply $requests[0], $expected, "clear_basic_filter should be staged";

  $ws0->submit_requests();

  return;
}

sub ws_conditional_format : Tests(4) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $ranges = [{ sheetId => $ws0->worksheet_id(), startRowIndex => 0, endRowIndex => 10 }];

  is $ws0->add_conditional_format_rule(
    ranges => $ranges,
    rule   => {
      booleanRule => {
        condition => { type => 'NOT_BLANK' },
        format    => { backgroundColor => { red => 1 } },
      },
    },
  ), $ws0, "add_conditional_format_rule should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    addConditionalFormatRule => {
      rule => {
        ranges => $ranges,
        booleanRule => {
          condition => { type => 'NOT_BLANK' },
          format    => { backgroundColor => { red => 1 } },
        },
      },
      index => 0,
    },
  };
  is_deeply $requests[0], $expected, "add_conditional_format_rule should be staged";

  $ws0->submit_requests();

  # Delete the rule we just added at index 0
  is $ws0->delete_conditional_format_rule(0), $ws0, "delete_conditional_format_rule should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected = {
    deleteConditionalFormatRule => {
      sheetId => $ws0->worksheet_id(),
      index   => 0,
    },
  };
  is_deeply $requests[0], $expected, "delete_conditional_format_rule should be staged";

  $ws0->submit_requests();

  return;
}

sub ws_banding : Tests(4) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $range = { sheetId => $ws0->worksheet_id(), startRowIndex => 0, endRowIndex => 10, startColumnIndex => 0, endColumnIndex => 5 };

  is $ws0->add_banding(
    range          => $range,
    row_properties => {
      headerColor       => { red => 0.2, green => 0.2, blue => 0.2 },
      firstBandColor    => { red => 1, green => 1, blue => 1 },
      secondBandColor   => { red => 0.9, green => 0.9, blue => 0.9 },
    },
  ), $ws0, "add_banding should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    addBanding => {
      bandedRange => {
        range          => $range,
        rowProperties  => {
          headerColor       => { red => 0.2, green => 0.2, blue => 0.2 },
          firstBandColor    => { red => 1, green => 1, blue => 1 },
          secondBandColor   => { red => 0.9, green => 0.9, blue => 0.9 },
        },
      },
    },
  };
  is_deeply $requests[0], $expected, "add_banding should be staged";

  # Submit to create the banding and get its ID from the response
  $ws0->submit_requests();
  my $responses = $ws0->requests_response_from_api();
  my $banding_id = $responses->[0]{addBanding}{bandedRange}{bandedRangeId};

  # Delete the banding we just created
  is $ws0->delete_banding($banding_id), $ws0, "delete_banding should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected = {
    deleteBanding => {
      bandedRangeId => $banding_id,
    },
  };
  is_deeply $requests[0], $expected, "delete_banding should be staged";

  $ws0->submit_requests();

  return;
}

sub ws_dimension_groups : Tests(6) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();

  is $ws0->group_rows(5, 10), $ws0, "group_rows should return same worksheet";
  my @requests = $ws0->batch_requests();
  my $expected = {
    addDimensionGroup => {
      range => {
        sheetId    => $ws0->worksheet_id(),
        dimension  => 'ROWS',
        startIndex => 5,
        endIndex   => 10,
      },
    },
  };
  is_deeply $requests[0], $expected, "group_rows should be staged";

  $ws0->submit_requests();

  is $ws0->group_cols(2, 5), $ws0, "group_cols should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected->{addDimensionGroup}->{range}->{dimension} = 'COLUMNS';
  $expected->{addDimensionGroup}->{range}->{startIndex} = 2;
  $expected->{addDimensionGroup}->{range}->{endIndex} = 5;
  is_deeply $requests[0], $expected, "group_cols should be staged";

  $ws0->submit_requests();

  # ungroup the rows we just grouped
  is $ws0->ungroup_rows(5, 10), $ws0, "ungroup_rows should return same worksheet";
  @requests = $ws0->batch_requests();
  $expected = {
    deleteDimensionGroup => {
      range => {
        sheetId    => $ws0->worksheet_id(),
        dimension  => 'ROWS',
        startIndex => 5,
        endIndex   => 10,
      },
    },
  };
  is_deeply $requests[0], $expected, "ungroup_rows should be staged";

  $ws0->submit_requests();

  return;
}

1;

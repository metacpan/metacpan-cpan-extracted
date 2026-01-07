package Test::Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range' => 'Request::Range';

use parent 'Test::Unit::TestBase';

init_logger;

my $index = {
  sheetId          => 'Sheet1',
  startColumnIndex => 0,
  startRowIndex    => 0,
  endColumnIndex   => 1,
  endRowIndex      => 1,
};

sub range_text_format : Tests(29) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          textFormat => {}
        },
      },
      fields => '',
    },
  };

  my $range = $self->mock_worksheet->range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();

  _range_text_format($cell, $range, 'bold');
  _range_text_format($cell, $range, 'italic');
  _range_text_format($cell, $range, 'strikethrough');
  _range_text_format($cell, $range, 'underline');
  _range_text_format($cell, $range, 'font_family', 'joe');
  _range_text_format($cell, $range, 'font_size', 2);

  _range_text_format_color($cell, $range, 'red');
  _range_text_format_color($cell, $range, 'blue', 0.2);
  _range_text_format_color($cell, $range, 'green', 0);
  _range_text_format_color($cell, $range, 'alpha', .5);

  isa_ok $range->
    bold()->italic()->strikethrough()->underline()->
    red()->blue(0.2)->green(0)->font_family('joe')->font_size(2),
    Range, "Build all for text format";
  my @requests = $range->batch_requests();
  is scalar @requests, 1, "Batch requests should have one entry.";
  is_deeply $requests[0], $cell, "Build all should be same as previous build";

  _range_text_format_color($cell, $range, 'white');
  _range_text_format_color($cell, $range, 'black');

  is_hash $range->submit_requests(), "Submit text format request";
  is scalar $range->batch_requests(), 0, "Batch requests should have been emptied";

  return;
}

sub _range_text_format {
  my ($cell, $range, $format, $value) = @_;

  is $range->$format($value), $range, "'$format' should return the same range";

  my %g_format = (
    font_family => 'fontFamily',
    font_size   => 'fontSize',
  );
  my $g_format = $g_format{ $format } || $format;

  my @requests = $range->batch_requests();
  $cell->{repeatCell}->{cell}->{userEnteredFormat}->{textFormat}->{$g_format} = $value // 'true';
  _add_field($cell, "userEnteredFormat.textFormat.$g_format");
  is_deeply $requests[0], $cell, "'$format' should be staged";

  return;
}

sub _range_text_format_color {
  my ($cell, $range, $color, $value) = @_;

  my @args;
  push(@args, $value) if $color !~ /^(white|black)$/;
  is $range->$color(@args), $range, "Foreground color '$color' should return the same range";

  my @colors = ($color);
  @colors = (qw(red blue green)) if $color =~ /^(white|black)$/;
  if ($color eq 'white') {
    push(@colors, 'alpha');
    $value = 1;
  }
  $value = 0 if $color eq 'black';
  $cell->{repeatCell}->{cell}->{userEnteredFormat}->{textFormat}->{foregroundColor}->{$_} = $value // 1
    foreach(@colors);

  _add_field($cell, "userEnteredFormat.textFormat.foregroundColor");
  my @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Foreground color '$color' should be staged";

  return;
}

sub range_background_color : Tests(13) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          backgroundColor => {},
        },
      },
      fields => 'userEnteredFormat.backgroundColor',
    },
  };

  my $range = $self->mock_worksheet->range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
 
  _range_background_color($cell, $range, 'red', 1);
  _range_background_color($cell, $range, 'blue', 0.2);
  _range_background_color($cell, $range, 'green', 0);
  _range_background_color($cell, $range, 'alpha', .5);

  _range_background_color($cell, $range, 'white', 1, [qw(red blue green alpha)]);
  _range_background_color($cell, $range, 'black', 0, [qw(red blue green)]);

  isa_ok $range->bk_white()->bk_black(), Range, "Background white/black";

  return;
}

sub _range_background_color {
  my ($cell, $range, $color, $value, $which) = @_;

  my $method = "bk_$color";
  my @args;
  unshift(@args, $value) if !$which;  # no args for white/black
  is $range->$method(@args), $range, "Background '$color' should return the same range";

  $which ||= [$color];
  $cell->{repeatCell}->{cell}->{userEnteredFormat}->{backgroundColor}->{$_} = $value
    foreach (@$which);

  my @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background '$color' should be staged";

  return;
}

# we don't test for every possible option here, we test the basic
# functionality for each type of format option.
sub range_misc : Tests(12) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          padding => {
            top => 1, bottom => 2, left => 3, right => 4,
          },
        },
      },
      fields => 'userEnteredFormat.padding',
    },
  };

  my $range = $self->mock_worksheet->range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my $user = $cell->{repeatCell}->{cell}->{userEnteredFormat};

  is $range->padding(top => 1, bottom => 2, left => 3, right => 4), $range, "Padding should return the same range";
  my @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Padding should be staged";

  is $range->clip(), $range, "Clip should return the same range";
  $user->{wrapStrategy} = 'CLIP';
  _add_field($cell, "userEnteredFormat.wrapStrategy");
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Clip should be staged";

  is $range->right_to_left(), $range, "Text direction should return the same range";
  $user->{textDirection} = 'RIGHT_TO_LEFT';
  _add_field($cell, "userEnteredFormat.textDirection");
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Text direction should be staged";

  is $range->hyper_linked(), $range, "Hyper link should return the same range";
  $user->{hyperlinkDisplayType} = 'LINKED';
  _add_field($cell, "userEnteredFormat.hyperlinkDisplayType");
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Hyper link should be staged";

  is $range->rotate(-90), $range, "Text rotation should return the same range";
  $user->{textRotation}->{angle} = '-90';
  _add_field($cell, "userEnteredFormat.textRotation");
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Text rotation should be staged";

  # textRotation is a union that allows either key 'angle' or 'vertical'.
  # adding both in this framework is possible, but will build an illegal
  # request and you will get an error when you send it to google. you
  # will just have to know not to call both on the same range, you have
  # to choose. we just test here that it builds both types properly.
  is $range->vertical(1), $range, "Text vertical should return the same range";
  $user->{textRotation}->{vertical} = 'true';
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Text vertical should be staged";

  return;
}

sub range_borders : Tests(22) {
  my $self = shift;

  my $cell = {
    updateBorders => {
      range => '',
    },
  };

  my $range = $self->mock_worksheet->range("A1");
  my $borders = $cell->{updateBorders};
  $borders->{range} = $range->range_to_index();

  foreach (qw(top bottom left right vertical horizontal)) {
    my $border = $_;
    $border =~ s/^(vertical|horizontal)$/"'inner' . '" . ucfirst($1) . "'"/ee;
    $borders->{$border}->{style} = 'DOTTED';
    _range_borders($cell, $range, $_);
  }

  my %save_outside = map { $_ => delete $borders->{$_}; } qw(top bottom left right);
  my %save_inside = map { $_ => delete $borders->{$_}; } qw(innerVertical innerHorizontal);

  @$borders{ keys %save_outside } = values %save_outside;
  _range_borders($cell, $range, '', 1);
  _range_borders($cell, $range, 'around', 1);

  delete @$borders{ keys %save_outside };
  @$borders{ keys %save_inside } = values %save_inside;
  _range_borders($cell, $range, 'inner', 1);

  @$borders{ keys %save_outside } = values %save_outside;
  _range_borders($cell, $range, [qw(around inner)], 1);

  @$borders{ keys %save_outside } = values %save_outside;
  _range_borders($cell, $range, 'all', 1);

  return;
}

sub _range_borders {
  my ($cell, $range, $border, $submit) = @_;

  $range->submit_requests() if $submit;  # resets the staged range request.

  my $pretty_border = $border;
  $pretty_border = "@$pretty_border" if ref($pretty_border);
  is $range->bd_dotted($border), $range, "Setting border '$pretty_border' should return the same range";

  my @requests = $range->batch_requests();
  $pretty_border ||= 'around';
  is_deeply $requests[0], $cell, "Border should be staged on '$pretty_border'";

  return;
}

sub range_border_style : Tests(14) {
  my $self = shift;

  my $cell = {
    updateBorders => {
      range => '',
      top   => {
        style => '',
      },
    },
  };

  my $range = $self->mock_worksheet->range("A1");
  $cell->{updateBorders}->{range} = $range->range_to_index();

  _range_border_style($cell, $range, $_)
    foreach (qw(dotted dashed solid medium thick double none));

  return;
}

sub _range_border_style {
  my ($cell, $range, $style) = @_;

  my $method = "bd_$style";
  is $range->$method('top'), $range, "Setting border style '$style' should return the same range";

  my $g_style = uc($style);
  $g_style =~ s/^(MEDIUM|THICK)$/SOLID_$1/;
  $cell->{updateBorders}->{top}->{style} = $g_style;
  my @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border '$style' should be staged on top";

  return;
}

sub range_border_colors : Tests(13) {
  my $self = shift;

  my $cell = {
    updateBorders => {
      range => '',
      top   => {
        color => {},
      },
    },
  };

  my $range = $self->mock_worksheet->range("A1");
  $cell->{updateBorders}->{range} = $range->range_to_index();

  _range_border_colors($cell, $range, 'red', 1);
  _range_border_colors($cell, $range, 'blue', 0.2);
  _range_border_colors($cell, $range, 'green', 0);
  _range_border_colors($cell, $range, 'alpha', .5);

  _range_border_colors($cell, $range, 'white', 1, [qw(red blue green alpha)]);
  _range_border_colors($cell, $range, 'black', 0, [qw(red blue green)]);

  isa_ok $range->bd_white('top')->bd_black('top'), Range, "Border white/black";

  return;
}

sub _range_border_colors {
  my ($cell, $range, $color, $value, $which) = @_;

  my $method = "bd_$color";
  my @args = 'top';
  unshift(@args, $value) if !$which;   # white/black don't need a value
  is $range->$method(@args), $range, "Border '$color' should return the same range";

  $which ||= [$color];
  $cell->{updateBorders}->{top}->{color}->{$_} = $value
    foreach (@$which);

  my @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Border '$color' should be staged";

  return;
}

sub range_border_cells : Tests(7) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          borders => {}
        },
      },
      fields => 'userEnteredFormat.borders',
    },
  };

  my $range = $self->mock_worksheet->range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my $borders = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{borders};
  my $fields = $cell->{repeatCell}->{fields};
  my @requests;

  my $err = qr/when bd_repeat_cell is turned on/;
  is $range->bd_repeat_cell(), $range, "Border repeat cell should return the same range";
  throws_ok { $range->bd_red('inner'); } $err, "Turning on border inner when repeat cell is on should die";
  throws_ok { $range->bd_red('vertical'); } $err, "Turning on border vertical when repeat cell is on should die";
  throws_ok { $range->bd_red('horizontal'); } $err, "Turning on border horizontal when repeat cell is on should die";

  isa_ok $range->bd_red('top'), Range, "Border red repeat cell";
  @requests = $range->batch_requests();
  is scalar $range->batch_requests(), 1, "Batch requests should have one entry.";
  $borders->{top}->{color}->{red} = 1;
  is_deeply $requests[0], $cell, "Border red repeat cell should be staged";

  return;
}

sub range_merge : Tests(6) {
  my $self = shift;

  my $cell = {
    mergeCells => {
      range     => '',
      mergeType => '',
    },
  };

  my $range = $self->mock_worksheet->range("A1:B2");
  $cell->{mergeCells}->{range} = $range->range_to_index();

  my @requests;

  $range->red()->merge_cols();
  @requests = $range->batch_requests();
  is scalar @requests, 2, "Batch requests should have two entries";
  $cell->{mergeCells}->{mergeType} = 'MERGE_COLUMNS';
  is_deeply $requests[1], $cell, "Merge columns should be staged";

  $range->merge_rows();
  @requests = $range->batch_requests();
  is scalar @requests, 2, "Batch requests should still have two entries";
  $cell->{mergeCells}->{mergeType} = 'MERGE_ROWS';
  is_deeply $requests[1], $cell, "Merge rows should be staged";

  $range->merge_both();
  @requests = $range->batch_requests();
  is scalar @requests, 2, "Batch requests should continue have two entries";
  $cell->{mergeCells}->{mergeType} = 'MERGE_ALL';
  is_deeply $requests[1], $cell, "Merge both should be staged";

  return;
}

sub _add_field {
  my ($cell, $field) = (@_);
  my %fields = map { $_ => 1; } split(',', $cell->{repeatCell}->{fields}), $field;
  $cell->{repeatCell}->{fields} = join(',', sort keys %fields);
  return;
}

sub range_paste_data : Tests(4) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1");

  # pasteData uses GridCoordinate (single cell), not GridRange
  my $range_index = $range->range_to_index();
  my $coordinate = {
    sheetId     => $range_index->{sheetId},
    rowIndex    => $range_index->{startRowIndex},
    columnIndex => $range_index->{startColumnIndex},
  };

  is $range->paste_data(data => "A\tB\tC\n1\t2\t3"), $range, "paste_data should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    pasteData => {
      coordinate => $coordinate,
      data       => "A\tB\tC\n1\t2\t3",
      type       => 'PASTE_NORMAL',
      delimiter  => "\t",
    },
  };
  is_deeply $requests[0], $expected, "paste_data should be staged";

  $range->submit_requests();

  is $range->paste_data(data => "<table><tr><td>A</td></tr></table>", html => 1), $range, "paste_data html should return same range";
  @requests = $range->batch_requests();
  $expected = {
    pasteData => {
      coordinate => $coordinate,
      data       => "<table><tr><td>A</td></tr></table>",
      type       => 'PASTE_NORMAL',
      html       => 'true',
    },
  };
  is_deeply $requests[0], $expected, "paste_data html should be staged";

  $range->submit_requests();

  return;
}

sub range_text_to_columns : Tests(4) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1:A10");

  is $range->text_to_columns(), $range, "text_to_columns should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    textToColumns => {
      source        => $range->range_to_index(),
      delimiterType => 'AUTODETECT',
    },
  };
  is_deeply $requests[0], $expected, "text_to_columns should be staged";

  $range->submit_requests();

  is $range->text_to_columns(delimiter => ',', delimiter_type => 'CUSTOM'), $range, "text_to_columns custom should return same range";
  @requests = $range->batch_requests();
  $expected->{textToColumns}->{delimiter} = ',';
  $expected->{textToColumns}->{delimiterType} = 'CUSTOM';
  is_deeply $requests[0], $expected, "text_to_columns custom should be staged";

  $range->submit_requests();

  return;
}

sub range_find_replace : Tests(4) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1:Z100");

  is $range->find_replace(find => 'foo', replacement => 'bar'), $range, "find_replace should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    findReplace => {
      range           => $range->range_to_index(),
      find            => 'foo',
      replacement     => 'bar',
      matchCase       => 'false',
      matchEntireCell => 'false',
      searchByRegex   => 'false',
      includeFormulas => 'false',
    },
  };
  is_deeply $requests[0], $expected, "find_replace should be staged";

  $range->submit_requests();

  is $range->find_replace(
    find              => 'test.*',
    replacement       => 'replaced',
    match_case        => 1,
    search_by_regex   => 1,
  ), $range, "find_replace with options should return same range";
  @requests = $range->batch_requests();
  $expected->{findReplace}->{find} = 'test.*';
  $expected->{findReplace}->{replacement} = 'replaced';
  $expected->{findReplace}->{matchCase} = 'true';
  $expected->{findReplace}->{searchByRegex} = 'true';
  is_deeply $requests[0], $expected, "find_replace with options should be staged";

  $range->submit_requests();

  return;
}

sub range_data_validation : Tests(6) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1:A10");

  my $rule = {
    condition => {
      type   => 'NUMBER_GREATER',
      values => [{ userEnteredValue => '0' }],
    },
    strict => 'true',
  };

  is $range->set_data_validation(rule => $rule), $range, "set_data_validation should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    setDataValidation => {
      range => $range->range_to_index(),
      rule  => $rule,
    },
  };
  is_deeply $requests[0], $expected, "set_data_validation should be staged";

  $range->submit_requests();

  is $range->clear_data_validation(), $range, "clear_data_validation should return same range";
  @requests = $range->batch_requests();
  $expected = {
    setDataValidation => {
      range => $range->range_to_index(),
    },
  };
  is_deeply $requests[0], $expected, "clear_data_validation should be staged";

  $range->submit_requests();

  is $range->data_validation_list(values => ['Yes', 'No', 'Maybe']), $range, "data_validation_list should return same range";
  @requests = $range->batch_requests();
  $expected = {
    setDataValidation => {
      range => $range->range_to_index(),
      rule  => {
        condition => {
          type   => 'ONE_OF_LIST',
          values => [
            { userEnteredValue => 'Yes' },
            { userEnteredValue => 'No' },
            { userEnteredValue => 'Maybe' },
          ],
        },
        strict       => 'true',
        showCustomUi => 'false',
      },
    },
  };
  is_deeply $requests[0], $expected, "data_validation_list should be staged";

  $range->submit_requests();

  return;
}

sub range_sort : Tests(4) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1:C10");

  is $range->sort_asc(0), $range, "sort_asc should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    sortRange => {
      range     => $range->range_to_index(),
      sortSpecs => [{ dimensionIndex => 0, sortOrder => 'ASCENDING' }],
    },
  };
  is_deeply $requests[0], $expected, "sort_asc should be staged";

  $range->submit_requests();

  is $range->sort_desc(1), $range, "sort_desc should return same range";
  @requests = $range->batch_requests();
  $expected->{sortRange}->{sortSpecs} = [{ dimensionIndex => 1, sortOrder => 'DESCENDING' }];
  is_deeply $requests[0], $expected, "sort_desc should be staged";

  $range->submit_requests();

  return;
}

sub range_randomize : Tests(2) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1:C10");

  is $range->randomize_range(), $range, "randomize_range should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    randomizeRange => {
      range => $range->range_to_index(),
    },
  };
  is_deeply $requests[0], $expected, "randomize_range should be staged";

  $range->submit_requests();

  return;
}

sub range_trim_whitespace : Tests(2) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1:C10");

  is $range->trim_whitespace(), $range, "trim_whitespace should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    trimWhitespace => {
      range => $range->range_to_index(),
    },
  };
  is_deeply $requests[0], $expected, "trim_whitespace should be staged";

  $range->submit_requests();

  return;
}

sub range_delete_duplicates : Tests(4) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1:C10");

  is $range->delete_duplicates(), $range, "delete_duplicates should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    deleteDuplicates => {
      range => $range->range_to_index(),
    },
  };
  is_deeply $requests[0], $expected, "delete_duplicates should be staged";

  $range->submit_requests();

  is $range->delete_duplicates(comparison_columns => [0, 1]), $range, "delete_duplicates with columns should return same range";
  @requests = $range->batch_requests();
  $expected->{deleteDuplicates}->{comparisonColumns} = [
    { sheetId => $range->worksheet_id(), dimension => 'COLUMNS', startIndex => 0, endIndex => 1 },
    { sheetId => $range->worksheet_id(), dimension => 'COLUMNS', startIndex => 1, endIndex => 2 },
  ];
  is_deeply $requests[0], $expected, "delete_duplicates with columns should be staged";

  $range->submit_requests();

  return;
}

sub range_append_cells : Tests(2) {
  my $self = shift;

  my $range = $self->mock_worksheet->range("A1");
  my $rows = [
    { values => [{ userEnteredValue => { stringValue => 'Test' } }] },
  ];

  is $range->append_cells(rows => $rows), $range, "append_cells should return same range";
  my @requests = $range->batch_requests();
  my $expected = {
    appendCells => {
      sheetId => $range->worksheet_id(),
      rows    => $rows,
      fields  => '*',
    },
  };
  is_deeply $requests[0], $expected, "append_cells should be staged";

  $range->submit_requests();

  return;
}

1;

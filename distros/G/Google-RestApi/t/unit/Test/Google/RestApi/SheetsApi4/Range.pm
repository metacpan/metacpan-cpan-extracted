package Test::Google::RestApi::SheetsApi4::Range;

use YAML::Any qw(Dump);
use Test::Most;

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

sub class { 'Google::RestApi::SheetsApi4::Range' }

my $sheet = 'Customer Addresses';

sub constructor : Tests(4) {
  my $self = shift;
  $self->SUPER::constructor(
    worksheet => $self->worksheet(),
    range     => "A1",
  );
  can_ok $self, 'range';
  return;
}

sub range : Tests(6) {
  my $self = shift;

  my $x = "A1:B2";

  my $range;
  lives_ok sub { $range = $self->new_range($x); }, "New range '$x' should live";
  is $range->range(), "$self->{name}$x", "A1:B2 should be $x";

  $range = $self->new_range([[1,1],[2,2]]);
  is $range->range(), "$self->{name}$x", "[[1,1],[2,2]] should be $x";

  $range = $self->new_range([['A',1],['B',2]]);
  is $range->range(), "$self->{name}$x", "[[A,1],[B,2]] should be $x";

  $range = $self->new_range([{row => 1, col => 1},{row => 2, col => 2}]);
  is $range->range(), "$self->{name}$x", "[{row => 1, col => 1},{row => 2, col => 2}] should be $x";

  $range = $self->new_range([{row => 1, col => 'A'},{row => 2, col =>'B'}]);
  is $range->range(), "$self->{name}$x", "[{row => 1, col => A},{row => 2, col => B}] should be $x";

  return;
}

sub range_col : Tests(26) {
  my $self = shift;

  my $col = $self->class()->can('is_colA1');

  is $col->("A"), 1, "Range A should be a col";
  is $col->("A:A"), 1, "Range A:A should be a col";
  is $col->("A1:A"), 1, "Range A1:A should be a col";
  is $col->("A1:A2"), 1, "Range A1:A2 should be a col";

  is $col->("$sheet!A"), 1, "Range $sheet!A should be a col";
  is $col->("$sheet!A:A"), 1, "Range $sheet!A:A should be a col";
  is $col->("$sheet!A1:A"), 1, "Range $sheet!A1:A should be a col";
  is $col->("$sheet!A1:A2"), 1, "Range $sheet!A1:A2 should be a col";

  is $col->("'$sheet'!A"), 1, "Range '$sheet'!A should be a col";
  is $col->("'$sheet'!A:A"), 1, "Range '$sheet'!A:A should be a col";
  is $col->("'$sheet'!A1:A"), 1, "Range '$sheet'!A1:A should be a col";
  is $col->("'$sheet'!A1:A2"), 1, "Range '$sheet'!A1:A2 should be a col";

  is $col->("AZ"), 1, "Range AZ should be a col";
  is $col->("AZ:AZ"), 1, "Range AZ:AZ should be a col";
  is $col->("AZ1:AZ"), 1, "Range AZ1:AZ should be a col";
  is $col->("AZ1:AZ2"), 1, "Range AZ1:AZ2 should be a col";

  is $col->("AA:AZ"), undef, "Range AA:AZ should not be a col";
  is $col->("AA1:AZ"), undef, "Range AA1:AZ should not be a col";
  is $col->("AA1:AZ2"), undef, "Range AA1:AZ2 should not be a col";

  is $col->("1"), undef, "Range 1 should not be a col";
  is $col->("1:1"), undef, "Range 1:1 should not be a col";
  is $col->("A1:1"), undef, "Range A1:1 should not be a col";
  is $col->("A1"), undef, "Range A1 should not be a col";
  is $col->("A1:B2"), undef, "Range A1:B2 should not be a col";

  is $col->([[1, 1]]), undef, "Range [[1, 1]] should not be a col";
  is $col->({ col => 1, row => 1 }), undef, "Range { col => 1, row => 1 } should not be a col";

  return;
}

sub range_row : Tests(26) {
  my $self = shift;

  my $row = $self->class()->can('is_rowA1');

  is $row->("1"), 1, "Range 1 should be a row";
  is $row->("1:1"), 1, "Range 1:1 should be a row";
  is $row->("1:A1"), 1, "Range 1:A1 should be a row";
  is $row->("A1:B1"), 1, "Range A1:B1 should be a row";

  is $row->("$sheet!1"), 1, "Range $sheet!1 should be a row";
  is $row->("$sheet!1:1"), 1, "Range $sheet!1:1 should be a row";
  is $row->("$sheet!1:A1"), 1, "Range $sheet!1:A1 should be a row";
  is $row->("$sheet!A1:B1"), 1, "Range $sheet!A1:B1 should be a row";

  is $row->("'$sheet'!1"), 1, "Range '$sheet'!1 should be a row";
  is $row->("'$sheet'!1:1"), 1, "Range '$sheet'!1:1 should be a row";
  is $row->("'$sheet'!A1:1"), 1, "Range '$sheet'!A1:1 should be a row";
  is $row->("'$sheet'!A1:B1"), 1, "Range '$sheet'!A1:B1 should be a row";

  is $row->("11"), 1, "Range 11 should be a row";
  is $row->("11:Z11"), 1, "Range 11:Z11 should be a row";
  is $row->("Z11:11"), 1, "Range Z11:11 should be a row";
  is $row->("A11:Z11"), 1, "Range A11:Z11 should be a row";

  is $row->("11:12"), undef, "Range 11:12 should not be a row";
  is $row->("A11:A12"), undef, "Range A11:A12 should not be a row";
  is $row->("A11:AZ12"), undef, "Range A11:AZ12 should not be a row";

  is $row->("A"), undef, "Range A should not be a row";
  is $row->("A:A"), undef, "Range A:A should not be a row";
  is $row->("A1:A"), undef, "Range A1:A should not be a row";
  is $row->("A1"), undef, "Range A1 should not be a row";
  is $row->("A1:B2"), undef, "Range A1:B2 should not be a row";

  is $row->([[1, 1]]), undef, "Range [[1, 1]] should not be a row";
  is $row->({ col => 1, row => 1 }), undef, "Range { col => 1, row => 1 } should not be a row";

  return;
}

sub range_cell : Tests(14) {
  my $self = shift;

  my $cell = $self->class()->can('is_cellA1');

  is $cell->("A1"), 1, "Range A1 should be a cell";
  is $cell->("AZ99"), 1, "Range AZ99 should be a cell";
  is $cell->("$sheet!AZ99"), 1, "Range $sheet!AZ99 should be a cell";
  is $cell->("'$sheet'!AZ99"), 1, "Range '$sheet'!AZ99 should be a cell";

  is $cell->("A1:B2"), undef, "Range A1:B2 should not be a cell";
  is $cell->("A"), undef, "Range A should not be a cell";
  is $cell->("A:A"), undef, "Range A:A should not be a cell";
  is $cell->("A1:A"), undef, "Range A1:A should not be a cell";

  is $cell->("1"), undef, "Range 1 should not be a cell";
  is $cell->("1:1"), undef, "Range 1:1 should not be a cell";
  is $cell->("1:A1"), undef, "Range 1:A1 should not be a cell";
  is $cell->("A1:1"), undef, "Range A1:1 should not be a cell";

  is $cell->([[1, 1]]), undef, "Range [[1, 1]] should not be a cell";
  is $cell->({ col => 1, row => 1 }), undef, "Range { col => 1, row => 1 } should not be a cell";

  return;
}

sub range_config : Tests(10) {
  my $self = shift;

  my $x = 'B';
  my $y = 3;

  my $range = $self->new_range([['id'],['id']]);
  is $range->range(), "$self->{name}$x:$x", "[['id'],['id']] should be $x:$x";

  $range = $self->new_range([['id']]);
  is $range->range(), "$self->{name}$x:$x", "[['id']] should be $x:$x";

  $range = $self->new_range(['id']);
  is $range->range(), "$self->{name}$x:$x", "['id'] should be $x:$x";

  $range = $self->new_range([['id', 5],['id']]);
  is $range->range(), "$self->{name}${x}5:$x", "[['id', 5],['id']] should be ${x}5:$x";

  $range = $self->new_range([[undef, 'george'],[undef, 'george']]);
  is $range->range(), "$self->{name}$y:$y", "[[undef, 'george'],[undef, 'george']] should be $y:$y";
  $range = $self->new_range([[0, 'george'],[0, 'george']]);
  is $range->range(), "$self->{name}$y:$y", "[[0, 'george'],[0, 'george']] should be $y:$y";
  $range = $self->new_range([['', 'george'],['', 'george']]);
  is $range->range(), "$self->{name}$y:$y", "[['', 'george'],['', 'george']] should be $y:$y";

  $range = $self->new_range([['id', 'sam'],['address', 'george']]);
  is $range->range(), "$self->{name}B2:D3", "[['id', 'sam'],['address', 'george']] should be B2:D3";

  $range = $self->new_range([ {col => 'id', row => 'sam'}, {col => 'address', row => 'george'} ]);
  is $range->range(), "$self->{name}B2:D3", "[ {col => 'id', row => 'sam'}, {col => 'address', row => 'george'} ] should be B2:D3";

  $range = $self->new_range(['bad']);
  throws_ok { $range->range() } $self->{err}, "['bad'] should fail";

  return;
}

sub range_named : Tests(3) {
  my $self = shift;
  is $self->new_range("George")->is_named(), 1, "George should be a named range";
  is $self->new_range("A1")->is_named(), undef, "A1 should not be a named range";
  is $self->new_range("A1:B2")->is_named(), undef, "A1:B2 should not be a named range";
  return;
}

my $index = {
  sheetId          => 'mock_worksheet_id',
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

  my $range = $self->new_range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my @requests;
  
  my $text_format = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{textFormat};
  my $fields = $cell->{repeatCell}->{fields};

  is $range->bold(), $range, "Bold should return the same range";
  @requests = $range->batch_requests();
  is scalar $range->batch_requests(), 1, "Batch requests should have one entry.";
  $text_format->{bold} = 'true'; _add_field($cell, "userEnteredFormat.textFormat.bold");
  is_deeply $requests[0], $cell, "Bold should be staged";

  is $range->italic(), $range, "Italic should return the same range";
  @requests = $range->batch_requests();
  is scalar @requests, 1, "Batch requests should still have one entry.";
  $text_format->{italic} = 'true'; _add_field($cell, 'userEnteredFormat.textFormat.italic');
  is_deeply $requests[0], $cell, "Italic should be staged";

  is $range->strikethrough(), $range, "Strikethrough should return the same range";
  $text_format->{strikethrough} = 'true'; _add_field($cell, 'userEnteredFormat.textFormat.strikethrough');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Strikethrough should be staged";

  is $range->underline(), $range, "Underline should return the same range";
  $text_format->{underline} = 'true'; _add_field($cell, 'userEnteredFormat.textFormat.underline');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Underline should be staged";

  $text_format->{foregroundColor} = {};
  my $foreground_color = $text_format->{foregroundColor};
  is $range->red(), $range, "Red should return the same range";
  $foreground_color->{red} = 1; _add_field($cell, 'userEnteredFormat.textFormat.foregroundColor');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Red should be staged";

  is $range->blue(0.2), $range, "Blue should return the same range";
  $foreground_color->{blue} = 0.2;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Blue should be staged";

  is $range->green(0.4), $range, "Green should return the same range";
  $foreground_color->{green} = 0.4;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Green should be staged";

  is $range->font_family('joe'), $range, "Font family should return the same range";
  $text_format->{fontFamily} = 'joe'; _add_field($cell, 'userEnteredFormat.textFormat.fontFamily');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Font family should be staged";

  is $range->font_size(1.1), $range, "Font size should return the same range";
  $text_format->{fontSize} = 1.1; _add_field($cell, 'userEnteredFormat.textFormat.fontSize');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Font size should be staged";

  lives_ok sub { _range_text_format_all($range); }, "Build all for text format should succeed";
  @requests = $range->batch_requests();
  is scalar @requests, 1, "Batch requests should have one entry.";
  is_deeply $requests[0], $cell, "Build all should be same as previous build";

  lives_ok sub { _range_text_format_all($range)->white(); }, "Build all text white should succeed";
  $foreground_color->{red} = $foreground_color->{blue} = $foreground_color->{green} = 1;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Text white should be built correctly";

  lives_ok sub { _range_text_format_all($range)->black(); }, "Build all text black should succeed";
  $foreground_color->{red} = $foreground_color->{blue} = $foreground_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Text black should be built correctly";

  lives_ok sub { $range->submit_requests(); }, "Submit format request should succeed";
  is scalar $range->batch_requests(), 0, "Batch requests should have been emptied";

  return;
}

sub range_background_color : Tests(14) {
  my $self = shift;

  my $cell = {
    repeatCell => {
      range => '',
      cell => {
        userEnteredFormat => {
          backgroundColor => {}
        },
      },
      fields => '',
    },
  };

  my $range = $self->new_range("A1");
  $cell->{repeatCell}->{range} = $range->range_to_index();
  my $background_color = $cell->{repeatCell}->{cell}->{userEnteredFormat}->{backgroundColor};
  my $fields = $cell->{repeatCell}->{fields};
  my @requests;

  is $range->background_red(), $range, "Background red should return the same range";
  $background_color->{red} = 1; _add_field($cell, 'userEnteredFormat.backgroundColor');
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background red should be staged";

  is $range->background_blue(0.2), $range, "Background blue should return the same range";
  $background_color->{blue} = 0.2;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background blue should be staged";

  is $range->background_green(0.4), $range, "Background green should return the same range";
  $background_color->{green} = 0.4;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background green should be staged";

  lives_ok sub { $range->background_white(); }, "Background white should succeed";
  $background_color->{red} = $background_color->{blue} = $background_color->{green} = 1;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background white request should be built correctly";

  lives_ok sub { $range->background_black(); }, "Background black should succeed";
  $background_color->{red} = $background_color->{blue} = $background_color->{green} = 0;
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background black request should be built correctly";

  lives_ok sub { $range->background_white()->background_black(); }, "Background white/black should succeed";
  @requests = $range->batch_requests();
  is_deeply $requests[0], $cell, "Background white/black request should be built correctly";

  lives_ok sub { $range->submit_requests(); }, "Submit format request should succeed";
  is scalar $range->batch_requests(), 0, "Batch requests should have been emptied";

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

  my $range = $self->new_range("A1:B2");
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

sub _range_text_format_all {
  shift->
    bold()->italic()->strikethrough()->underline()->
    red()->blue(0.2)->green(0.4)->font_family('joe')->font_size(1.1);
}

sub _add_field {
  my ($cell, $field) = (@_);
  my @fields = split(',', $cell->{repeatCell}->{fields});
  $cell->{repeatCell}->{fields} = join(',', sort @fields, $field);
  return;
}

1;

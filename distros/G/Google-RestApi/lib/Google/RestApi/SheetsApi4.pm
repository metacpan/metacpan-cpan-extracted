package Google::RestApi::SheetsApi4;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

use Module::Load qw( load );
use Readonly;
use Try::Tiny ();
use YAML::Any ();

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

Readonly our $Sheets_Endpoint    => "https://sheets.googleapis.com/v4/spreadsheets";
Readonly our $Spreadsheet_Id     => $Google::RestApi::DriveApi3::Drive_File_Id;
Readonly our $Spreadsheet_Uri    => "https://docs.google.com/spreadsheets/d";
Readonly our $Worksheet_Id       => "[0-9]+";
Readonly our $Worksheet_Uri      => "[#&]gid=([0-9]+)";
Readonly our $Spreadsheet_Filter => "mimeType = 'application/vnd.google-apps.spreadsheet'";

sub new {
  my $class = shift;

  state $check = compile_named(
    api           => HasApi,                                           # the G::RestApi object that will be used to send http calls.
    drive         => HasMethods[qw(list)], { optional => 1 },  # a drive instnace, could be your own, defaults to G::R::DriveApi3.
    endpoint      => Str, { default => $Sheets_Endpoint },              # this gets tacked on to the api uri to reach the sheets endpoint.
  );
  my $self = $check->(@_);

  return bless $self, $class;
}

# this gets called by lower-level classes like worksheet and range objects. they
# will have passed thier own uri with params and possible body, we tack on the
# sheets endpoint and pass it up the line to G::RestApi to make the actual call.
sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str, { default => '' },
    _extra_ => slurpy Any,              # just pass through any extra params to G::RestApi::api call.
  );
  my $p = named_extra($check->(@_));
  my $uri = $self->{endpoint};          # tack on the uri endpoint and pass the buck.
  $uri .= "/$p->{uri}" if $p->{uri};
  return $self->rest_api()->api(%$p, uri => $uri);
}

sub create_spreadsheet {
  my $self = shift;

  state $check = compile_named(
    title   => Str, { optional => 1 },
    name    => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  # we allow name and title to be synonymous for convenience. it's actuall title in the google api.
  $p->{title} || $p->{name} or LOGDIE "Either 'title' or 'name' should be supplied";
  $p->{title} ||= $p->{name};
  delete $p->{name};

  my $result = $self->api(
    method  => 'post',
    content => { properties => $p },
  );
  for (qw(spreadsheetId spreadsheetUrl properties)) {
    $result->{$_} or LOGDIE "No '$_' returned from creating spreadsheet";
  }

  return $self->open_spreadsheet(
    id  => $result->{spreadsheetId},
    uri => $result->{spreadsheetUrl},
  );
}

sub copy_spreadsheet {
  my $self = shift;
  my $id = $Spreadsheet_Id;
  state $check = compile_named(
    spreadsheet_id => StrMatch[qr/$id/],
    _extra_        => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  my $file_id = delete $p->{spreadsheet_id};
  my $file = $self->drive()->file(id => $file_id);
  my $copy = $file->copy(%$p);
  return $self->open_spreadsheet(id => $copy->file_id());
}

sub delete_spreadsheet {
  my $self = shift;
  my $id = $Spreadsheet_Id;
  state $check = compile(StrMatch[qr/$id/]);
  my ($spreadsheet_id) = $check->(@_);
  return $self->drive()->file(id => $spreadsheet_id)->delete();
}

sub delete_all_spreadsheets_by_filters {
  my $self = shift;

  state $check = compile(ArrayRef->plus_coercions(Str, sub { [$_]; }));
  my ($filter) = $check->(@_);

  my $count = 0;
  foreach my $filter (@$filter) {
    my @spreadsheets = $self->spreadsheets_by_filter($filter);
    $count += scalar @spreadsheets;
    DEBUG(sprintf("Deleting %d spreadsheets for filter '$filter'", scalar @spreadsheets));
    $self->delete_spreadsheet($_->{id}) foreach (@spreadsheets);
  }
  return $count;
}

sub delete_all_spreadsheets {
  my $self = shift;
  my @names = @_;
  @names = map { "name = '$_"; } @names;
  return $self->delete_all_spreadsheets_by_filters(@names);
}

sub spreadsheets_by_filter {
  my $self = shift;

  state $check = compile(Optional[Str]);
  my ($extra_filter) = $check->(@_);

  my $drive = $self->drive();
  my $filter = $Spreadsheet_Filter;
  $filter .= " and ($extra_filter)" if $extra_filter;
  return $drive->list($filter);
}

sub spreadsheets {
  my $self = shift;
  my ($name) = @_;
  $name = "name = '$name'" if $name;
  return $self->spreadsheets_by_filter($name);
}

sub drive {
  my $self = shift;
  $self->{drive} //= DriveApi3->new(api => $self->rest_api());
  return $self->{drive};
}

sub open_spreadsheet { Spreadsheet->new(sheets_api => shift, @_); }
sub transaction { shift->rest_api()->transaction(); }
sub stats { shift->rest_api()->stats(); }
sub reset_stats { shift->rest_api->reset_stats(); }
sub rest_api { shift->{api}; }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4 - API to Google Sheets API V4.

=head1 SYNOPSIS

=over

 use aliased Google::RestApi;
 use aliased Google::RestApi::SheetsApi4;

 $rest_api = RestApi->new(%config);
 $sheets_api = SheetsApi4->new(api => $rest_api);
 $sheet = $sheets_api->create_spreadsheet(title => 'my_name');
 $ws0 = $sheet->open_worksheet(id => 0);
 $sw1 = $sheet->add_worksheet(name => 'Fred');

 # sub Worksheet::cell/col/cols/row/rows immediately get/set
 # values. this is less efficient but the simplest way to
 # interface with the api. you don't deal with any intermediate
 # api objects.
 
 # add some data to the worksheet:
 @values = (
   [ 1001, "Herb Ellis", "100", "10000" ],
   [ 1002, "Bela Fleck", "200", "20000" ],
   [ 1003, "Freddie Mercury", "999", "99999" ],
 );
 $ws0->rows([1, 2, 3], \@values);
 $values = $ws0->rows([1, 2, 3]);

 # use and manipulate 'range' objects to do more complex work.
 # ranges can be specified in many ways, use whatever way is most convenient.
 $range = $ws0->range("A1:B2");
 $range = $ws0->range([[1,1],[2,2]]);
 $range = $ws0->range([{col => 1, row => 1}, {col => 2, row => 2}]);

 $cell = $ws0->range_cell("A1");
 $cell = $ws0->range_cell([1,1]);
 $cell = $ws0->range_cell({col => 1, row => 1});

 $col = $ws0->range_col(1);
 $col = $ws0->range_col("A3:A");
 $col = $ws0->range_col([1]);
 $col = $ws0->range_col([[1, 3], [1]]);
 $col = $ws0->range_col({col => 1});

 $row = $ws0->range_row(1);
 $row = $ws0->range_row("C1:1");
 $row = $ws0->range_row([<false>, 1]);
 $row = $ws0->range_row({row => 1});
 $row = $ws0->range_row([{col => 3, row => 1 }, {row => 1}]);

 # add a header:
 $row = $ws0->range_row(1);
 $row->insert_d()->freeze()->bold()->italic()->center()->middle()->submit_requests();
 # sends the values to the api directly, not using batch (less efficient):
 $row->values(values => [qw(Id Name Tax Salary)]);

 # bold the names:
 $col = $ws0->range_col("B2:B");
 $col->bold()->submit_requests();

 # add some tax info:
 $tax = $ws0->range_cell([ 3, 5 ]);   # or 'C5' or [ 'C', 5 ] or { col => 3, row => 5 }...
 $salary = $ws0->range_cell({ col => "D", row => 5 }); # same as "D5"
 # set up batch update with staged values:
 $tax->batch_values(values => "=SUM(C2:C4)");
 $salary->batch_values(values => "=SUM(D2:D4)");
 # now collect the ranges into a group and send the values via batch:
 $rg = $sheet->range_group($tax, $salary);
 $rg->submit_values();
 # bold and italicize both cells, and put a solid border around each one:
 $rg->bold()->italic()->bd_solid()->submit_requests();

 # tie ranges to a hash:
 $row = $ws0->tie_cells({id => 'A2'}, {name => 'B2'});
 $row->{id} = '1001';
 $row->{name} = 'Herb Ellis';
 tied(%$row)->submit_values();

 # or use a hash slice:
 $ranges = $ws0->tie_ranges();
 @$ranges{ 'A2', 'B2', 'C2', 'D4:E5' } =
   (1001, "Herb Ellis", "123 Some Street", [["Halifax"]]);
 tied(%$ranges)->submit_values();

 # use simple header column/row values as a source for tied keys:
 $cols = $ws0->tie_cols('Id', 'Name');
 $cols->{Id} = [1001, 1002, 1003];
 $cols->{Name} = ['Herb Ellis', 'Bela Fleck', 'Freddie Mercury'];
 tied(%$cols)->submit_values();

 # format tied values by requesting that the tied hash returns the
 # underlying range objects on fetch:
 tied(%$rows)->fetch_range(1);
 $rows->{Id}->bold()->center();
 $rows->{Name}->red();
 # turn off fetch range and submit the formatting:
 tied(%$rows)->fetch_range(0)->submit_requests();

 # iterators can be used to step through ranges:
 # a basic iterator on a column:
 $col = $ws0->range_col(1);
 $i = $col->iterator();
 while(1) {
   $cell = $i->next();
   last if !defined $cell->values();
 }

 # a basic iterator on an arbitrary range, iterating by col or row:
 $range = $ws0->range("A1:C3");
 $i = $range->iterator(dim => 'col');
 $cell = $i->next();  # A1
 $cell = $i->next();  # A2
 $i = $range->iterator(dim => 'row');
 $cell = $i->next();  # A1
 $cell = $i->next();  # B1

 # an iterator on a range group:
 $col = $ws0->range_col(1);
 $row = $ws0->range_row(1);
 $rg = $sheet->range_group($col, $row);
 $i = $rg->iterator();
 $rg2 = $i->next();  # another range group of cells A1, A1
 $rg2 = $i->next();  # another range group of cells A2, B1

 # an iterator on a tied range group:
 $cols = $ws0->tie_cols(qw(Id Name));
 $i = tied(%$cols)->iterator();
 $row = $i->next();
 $row->{Id} = '1001';
 $row->{Name} = 'Herb Ellis';
 tied(%$row)->submit_values();

=back

=head1 DESCRIPTION

SheetsApi4 is an API to Google Sheets. It is very perl-ish in that there is usually "more than one way to do it". It provides default behaviours
that should be fine for most normal needs, but those behaviours can be overridden when necessary.

It is assumed that you are familiar with the Google Sheets API: https://developers.google.com/sheets/api

C<tutorial/sheets/*> also has a step-by-step tutorial of creating and updating a spreadsheet, showing you the API calls and return values for each step.

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

=item * L<Google::RestApi::SheetsApi4::Range::Iterator>

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

Creates a new instance of a SheetsApi object.

%args consists of:

=over

=item C<api> L<<Google::RestApi>>: A reference to a configured L<Google::RestApi> instance.

=back

=item api(%args);

%args consists of:

=over

=item * C<uri> <path_segments_string>: Adds this path segment to the Sheets endpoint and calls the L<Google::RestApi>'s C<api> subroutine.

=item * C<%args>: Passes any extra arguments to the L<Google::RestApi>'s C<api> subroutine (content, params, method etc).

=back

This is essentially a pass-through method between lower-level Worksheet/Range objects and L<Google::RestApi>, where this method adds in the Sheets endpoint.
See <Google::RestApi::SheetsApi4::Worksheet>'s C<api> routine for how this is called. You would not normally call this directly unless you were making a Google API call not currently
supported by this API framework.

Returns the response hash from Google API.

=item create_spreadsheet(%args);

Creates a new spreadsheet.

%args consists of:

=over

=item * C<title|name> <string>: The title (or name) of the new spreadsheet.

=item * C<%args>: Passes through any extra arguments to Google Drive's create file routine.

=back

Args C<title> and C<name> are synonymous, you can use either. Note that Sheets allows multiple spreadsheets with the same name. 

Normally this would be called via the Spreadsheet object, which would fill in the Drive file ID for you.

Returns the object instance of the new spreadsheet object.

=item copy_spreadsheet(%args);

Creates a copy of a spreadsheet.

%args consists of:

=over

=item * C<spreadsheet_id> <string>: The file ID in Google Drive of the spreadsheet you want to make a copy of.

=item * C<%args>: Additional arguments passed through to Google Drive file copy subroutine.

=back

Returns the object instance of the new spreadsheet object.

=item delete_spreadsheet(spreadsheet_id<string>);

Deletes the spreadsheet from Google Drive.

%args consists of:

spreadsheet_id is the file ID in Google Drive of the spreadsheet you want to delete.

Returns the Google API response.

=item delete_all_spreadsheets_by_filters([spreadsheet_name<string>]);

Deletes all spreadsheets with the given names from Google Drive. 

Returns the number of spreadsheets deleted.

=item spreadsheets();

Returns a list of spreadsheets in Google Drive.

=item drive();

Returns an instance of Google Drive that shares the same RestApi as this SheetsApi object. You would not normally need to use this directly.

=item open_spreadsheet(%args);

Opens a new spreadsheet from the given id, uri, or name.

%args consists of any args passed to Spreadsheet->new routine (which see).

=back

=head1 REQUEST CLASSES

The Request classes provide methods for building Google Sheets API batchUpdate requests.
These are typically called on Range, Worksheet, or Spreadsheet objects which inherit from
the appropriate Request class. The requests are staged and then submitted via C<submit_requests()>.

=head2 Google::RestApi::SheetsApi4::Request::Spreadsheet

Spreadsheet-level requests (inherited by Spreadsheet objects):

=over

=item add_worksheet(%args)

Add a new worksheet. Args: C<name> or C<title>, C<grid_properties> (hashref with C<rows>/C<cols>), C<tab_color> (hashref with C<red>/C<blue>/C<green>).

=item update_spreadsheet_properties(properties => \%props, fields => $fields)

Update spreadsheet properties directly.

=item ss_title($title)

Set the spreadsheet title.

=item ss_locale($locale)

Set the spreadsheet locale (e.g., 'en_US').

=item ss_time_zone($tz)

Set the spreadsheet time zone (e.g., 'America/New_York').

=item ss_auto_recalc($mode)

Set auto recalculation mode ('ON_CHANGE', 'MINUTE', 'HOUR').

=item ss_iteration_count($count)

Set maximum iterations for circular references.

=item ss_iteration_threshold($threshold)

Set convergence threshold for iterative calculations.

=item ss_default_format($format)

Set the default cell format for the spreadsheet.

=item add_protected_range(%args)

Add a protected range. Args: C<range> (required hashref), C<description>, C<warning_only>, C<requesting_user>, C<editors>.

=item update_protected_range(%args)

Update a protected range. Args: C<id> (required), C<range>, C<description>, C<warning_only>, C<requesting_user>, C<editors>, C<fields>.

=item delete_protected_range($id)

Delete a protected range by ID.

=back

=head2 Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet

Worksheet-level requests (inherited by Worksheet objects):

=head3 Worksheet Properties

=over

=item ws_rename($name)

Rename the worksheet.

=item ws_index($index)

Set the worksheet tab position (0-indexed).

=item ws_hide($bool) / ws_hidden($bool)

Hide or show the worksheet.

=item ws_right_to_left($bool) / ws_left_to_right($bool)

Set the text direction for the worksheet.

=item ws_tab_color($color_hashref)

Set the tab color. Color is a hashref with C<red>/C<blue>/C<green>/C<alpha> keys (0-1 values).

=item ws_tab_red($value) / ws_tab_blue($value) / ws_tab_green($value) / ws_tab_alpha($value)

Set individual tab color components (0-1 values).

=item ws_tab_black() / ws_tab_white()

Set tab color to black or white.

=item update_worksheet_properties(properties => \%props, fields => $fields)

Update worksheet properties directly.

=back

=head3 Freezing

=over

=item freeze_rows($count) / freeze_cols($count)

Freeze the specified number of rows or columns.

=item unfreeze_rows() / unfreeze_cols()

Unfreeze rows or columns.

=back

=head3 Clearing

=over

=item clear_values()

Clear all cell values in the worksheet.

=item clear_formatting()

Clear all formatting in the worksheet.

=item reset()

Clear values, formatting, and unfreeze rows/columns.

=back

=head3 Worksheet Management

=over

=item delete_worksheet()

Delete the worksheet.

=item duplicate_worksheet(%args)

Duplicate the worksheet. Args: C<new_name>, C<insert_index>, C<new_sheet_id>.

=back

=head3 Dimensions

=over

=item update_dimension_properties(%args)

Update dimension properties. Args: C<dimension> ('row'/'col'), C<start>, C<end>, C<properties>, C<fields>.

=item row_height($start, $end, $height)

Set the height (in pixels) for rows from start to end index.

=item col_width($start, $end, $width)

Set the width (in pixels) for columns from start to end index.

=item hide_rows($start, $end) / hide_cols($start, $end)

Hide rows or columns.

=item show_rows($start, $end) / show_cols($start, $end)

Show hidden rows or columns.

=item append_dimension(dimension => $dim, length => $len)

Append rows or columns.

=item append_rows($length) / append_cols($length)

Convenience methods to append rows or columns.

=item auto_resize_dimensions(dimension => $dim, start => $start, end => $end)

Auto-resize rows or columns to fit content.

=item auto_resize_rows($start, $end) / auto_resize_cols($start, $end)

Convenience methods to auto-resize rows or columns.

=back

=head3 Filters

=over

=item set_basic_filter(%args)

Set a basic filter. Args: C<range> (hashref, defaults to entire sheet), C<criteria> (hashref), C<sort_specs> (arrayref).

=item clear_basic_filter()

Clear the basic filter.

=back

=head3 Conditional Formatting

=over

=item add_conditional_format_rule(%args)

Add a conditional format rule. Args: C<ranges> (required arrayref), C<rule> (required hashref), C<index> (default 0).

=item update_conditional_format_rule(%args)

Update a conditional format rule. Args: C<index> (required), C<rule>, C<new_index>.

=item delete_conditional_format_rule($index)

Delete a conditional format rule by index.

=back

=head3 Banding (Alternating Colors)

=over

=item add_banding(%args)

Add banded (alternating) colors. Args: C<range> (required hashref), C<row_properties>, C<column_properties>.

=item update_banding(%args)

Update banded range. Args: C<id> (required), C<range>, C<row_properties>, C<column_properties>, C<fields>.

=item delete_banding($id)

Delete a banded range by ID.

=back

=head3 Row/Column Grouping

=over

=item add_dimension_group(dimension => $dim, start => $start, end => $end)

Add a row or column group (for expand/collapse).

=item delete_dimension_group(dimension => $dim, start => $start, end => $end)

Delete a dimension group.

=item update_dimension_group(%args)

Update a dimension group. Args: C<dimension>, C<start>, C<end>, C<depth>, C<collapsed>.

=item group_rows($start, $end) / group_cols($start, $end)

Convenience methods to group rows or columns.

=item ungroup_rows($start, $end) / ungroup_cols($start, $end)

Convenience methods to ungroup rows or columns.

=back

=head2 Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range

Range-level requests (inherited by Range objects):

=head3 Text Alignment

=over

=item left() / center() / right()

Set horizontal alignment.

=item top() / middle() / bottom()

Set vertical alignment.

=item horizontal_alignment($alignment)

Set horizontal alignment directly ('LEFT', 'CENTER', 'RIGHT').

=item vertical_alignment($alignment)

Set vertical alignment directly ('TOP', 'MIDDLE', 'BOTTOM').

=back

=head3 Text Formatting

=over

=item font_family($family)

Set the font family (e.g., 'Arial', 'Times New Roman').

=item font_size($size)

Set the font size in points.

=item bold($bool) / italic($bool) / strikethrough($bool) / underline($bool)

Toggle text formatting. Pass 0 or no argument to enable, pass explicit false to disable.

=item heading()

Apply a preset heading style (centered, bold, white on black, 12pt).

=back

=head3 Text Color

=over

=item red($value) / blue($value) / green($value) / alpha($value)

Set text color components (0-1 values).

=item black() / white()

Set text color to black or white.

=item color($color_hashref)

Set text color directly with a hashref.

=back

=head3 Background Color

=over

=item bk_red($value) / bk_blue($value) / bk_green($value) / bk_alpha($value)

Set background color components (0-1 values).

=item bk_black() / bk_white()

Set background to black or white.

=item bk_color($color_hashref)

Set background color directly with a hashref.

=back

=head3 Number Formats

=over

=item text($pattern) / number($pattern) / percent($pattern) / currency($pattern)

Set number format type with optional pattern.

=item date($pattern) / time($pattern) / date_time($pattern) / scientific($pattern)

Set date/time or scientific format with optional pattern.

=item number_format($type, $pattern)

Set number format directly.

=back

=head3 Text Wrapping and Direction

=over

=item overflow() / clip() / wrap()

Set wrap strategy for cell content.

=item wrap_strategy($strategy)

Set wrap strategy directly ('OVERFLOW_CELL', 'CLIP', 'WRAP').

=item padding(%args)

Set cell padding. Args: C<top>, C<bottom>, C<left>, C<right>.

=item left_to_right() / right_to_left()

Set text direction.

=item rotate($angle)

Rotate text by angle (-90 to 90 degrees).

=item vertical($bool)

Stack text vertically.

=item hyper_linked() / hyper_plain()

Set hyperlink display type.

=back

=head3 Borders

=over

=item bd_solid($border) / bd_dotted($border) / bd_dashed($border)

Set border style. C<$border> can be 'top', 'bottom', 'left', 'right', 'around', 'vertical', 'horizontal', 'inner', 'all', or an arrayref of these.

=item bd_medium($border) / bd_thick($border) / bd_double($border) / bd_none($border)

Additional border styles.

=item bd_red($value, $border) / bd_blue($value, $border) / bd_green($value, $border) / bd_alpha($value, $border)

Set border color components.

=item bd_black($border) / bd_white($border)

Set border color to black or white.

=item bd_color($color_hashref, $border)

Set border color directly.

=item borders(properties => \%props, border => $border)

Full border control.

=item bd_repeat_cell($bool)

Toggle whether borders apply to each cell individually (1) or to the range edges (0).

=back

=head3 Merging

=over

=item merge_all() / merge_both()

Merge all cells in the range into one.

=item merge_rows()

Merge cells in each row.

=item merge_cols()

Merge cells in each column.

=item merge_cells(merge_type => $type)

Merge cells with specified type ('all', 'row', 'col').

=item unmerge() / unmerge_cells()

Unmerge cells.

=back

=head3 Insert/Delete Operations

=over

=item insert_dimension(dimension => $dim, inherit => $bool)

Insert rows or columns. C<dimension> is 'row' or 'col'.

=item insert_d($dimension, $inherit)

Shorthand for insert_dimension.

=item insert_range(dimension => $dim)

Insert range, shifting existing cells.

=item insert_r($dimension)

Shorthand for insert_range.

=item delete_dimension(dimension => $dim)

Delete rows or columns.

=item delete_d($dimension)

Shorthand for delete_dimension.

=item delete_range(dimension => $dim)

Delete range, shifting remaining cells.

=item delete_r($dimension)

Shorthand for delete_range.

=item move_dimension(dimension => $dim, destination => $range)

Move rows or columns to a new position.

=item move($dimension, $destination)

Shorthand for move_dimension.

=back

=head3 Copy/Paste

=over

=item copy_paste(destination => $range, type => $type, orientation => $orient)

Copy and paste. C<type>: 'normal', 'values', 'format', 'no_borders', 'formula', 'data_validation', 'conditional_formatting'. C<orientation>: 'normal', 'transpose'.

=item cut_paste(destination => $range, type => $type)

Cut and paste.

=back

=head3 Named Ranges

=over

=item add_named(name => $name) / named_a($name)

Create a named range.

=item delete_named() / named_d()

Delete the named range.

=item update_named(%args) / named_u(%args)

Update a named range. Args: C<name>, C<range>, C<fields>.

=back

=head3 Data Operations

=over

=item auto_fill(source => $range, use_template => $bool)

Auto-fill based on a source range pattern.

=item append_cells(rows => \@rows, fields => $fields)

Append rows of cell data.

=item paste_data(data => $data, delimiter => $delim, type => $type, html => $bool)

Paste delimited or HTML data.

=item text_to_columns(delimiter => $delim, delimiter_type => $type)

Split text in column to multiple columns.

=item find_replace(%args)

Find and replace. Args: C<find> (required), C<replacement>, C<match_case>, C<match_entire_cell>, C<search_by_regex>, C<include_formulas>.

=back

=head3 Data Validation

=over

=item set_data_validation(rule => \%rule)

Set data validation rule.

=item clear_data_validation()

Clear data validation.

=item data_validation_list(values => \@values, strict => $bool, show_custom => $bool, input_message => $msg)

Create a dropdown list validation.

=item data_validation_range(source => $range, strict => $bool, show_custom => $bool, input_message => $msg)

Create validation from a range of values.

=back

=head3 Sorting and Cleanup

=over

=item sort_range(sort_specs => \@specs)

Sort range by specified columns.

=item sort_asc($col) / sort_desc($col)

Sort ascending or descending by column index (default 0).

=item randomize_range()

Randomize the order of rows in the range.

=item trim_whitespace()

Trim leading/trailing whitespace from cells.

=item delete_duplicates(comparison_columns => \@cols)

Delete duplicate rows. Optional column indices for comparison.

=back

=head3 Clearing (Range)

=over

=item clear_values()

Clear values in the range.

=item clear_formatting()

Clear formatting in the range.

=back

=head1 STATUS

This api is currently in beta status. It is incomplete. There may be design flaws that need to be addressed in later releases. Later
releases may break this release. Not all api calls have been implemented.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

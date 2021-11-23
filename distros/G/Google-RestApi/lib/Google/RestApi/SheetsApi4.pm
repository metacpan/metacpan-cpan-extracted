package Google::RestApi::SheetsApi4;

our $VERSION = '0.9';

use Google::RestApi::Setup;

use Module::Load qw( load );
use Try::Tiny ();
use YAML::Any ();

use aliased 'Google::RestApi::DriveApi3';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

# TODO: switch to ReadOnly
use constant {
  Sheets_Endpoint    => "https://sheets.googleapis.com/v4/spreadsheets",
  Spreadsheet_Filter => "mimeType='application/vnd.google-apps.spreadsheet'",
  Spreadsheet_Id     => DriveApi3->Drive_File_Id,
  Spreadsheet_Uri    => "https://docs.google.com/spreadsheets/d",
  Worksheet_Id       => "[0-9]+",
  Worksheet_Uri      => "[#&]gid=([0-9]+)",
};

sub new {
  my $class = shift;

  state $check = compile_named(
    api           => HasApi,
    drive         => HasMethods[qw(filter_files)], { optional => 1 },
    endpoint      => Str, { default => Sheets_Endpoint },
  );
  my $self = $check->(@_);

  return bless $self, $class;
}

sub api {
  my $self = shift;
  state $check = compile_named(
    uri     => Str, { default => '' },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  my $uri = $self->{endpoint};
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
  my $id = Spreadsheet_Id;
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
  my $id = Spreadsheet_Id;
  state $check = compile(StrMatch[qr/$id/]);
  my ($spreadsheet_id) = $check->(@_);
  return $self->drive()->file(id => $spreadsheet_id)->delete();
}

sub delete_all_spreadsheets {
  my $self = shift;

  state $check = compile(ArrayRef->plus_coercions(Str, sub { [$_]; }));
  my ($names) = $check->(@_);

  my $count = 0;
  foreach my $name (@$names) {
    my @spreadsheets = grep { $_->{name} eq $name; } $self->spreadsheets();
    $count += scalar @spreadsheets;
    DEBUG(sprintf("Deleting %d spreadsheets for name '$name'", scalar @spreadsheets));
    $self->delete_spreadsheet($_->{id}) foreach (@spreadsheets);
  }
  return $count;
}

sub spreadsheets {
  my $self = shift;
  my $drive = $self->drive();
  my $spreadsheets = $drive->filter_files(Spreadsheet_Filter);
  my @spreadsheets = map { { id => $_->{id}, name => $_->{name} }; } @{ $spreadsheets->{files} };
  return @spreadsheets;
}

sub drive {
  my $self = shift;
  if (!$self->{drive}) {
    load DriveApi3;
    $self->{drive} = DriveApi3->new(api => $self->rest_api());
  }
  return $self->{drive};
}

sub open_spreadsheet { Spreadsheet->new(sheets_api => shift, @_); }
sub transaction { shift->rest_api()->transaction(); }
sub stats { shift->rest_api()->stats(); }
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
 $sheet = $sheets->create_spreadsheet(title => 'my_name');
 $ws0 = $sheet->open_worksheet(id => 0);

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

SheetsApi4 is an API to Google Sheets. It is very perl-ish in that there
is usually "more than one way to do it". It provides default behaviours
that should be fine for most normal needs, but those behaviours can be
overridden when necessary.

It is assumed that you are familiar with the Google Sheets API:
https://developers.google.com/sheets/api

The synopsis above is a quick reference. For more detailed information, see:

 Google::RestApi
 Google::RestApi::SheetsApi4::Spreadsheet
 Google::RestApi::SheetsApi4::Worksheet
 
 t/tutorial/Sheets also has a step-by-step tutorial of creating and
 updating a spreadsheet, showing you the API calls and return values
 for each step.

=head1 SUBROUTINES

=over

=item new(api => <Google::RestApi>);

Creates a new instance of a SheetsApi object.

 api: A reference to a configured RestApi instance.

=item api(uri => <path_segments_string>, %args);

Sets up a call to the RestApi's 'api' subroutine using the given arguments.
The Sheets endpoint is the URI that's passed to RestApi, along with any
other URI segment passed in the uri arg.

 uri: Adds this path segment to the Sheets endpoint and calls the RestApi's
   'api' subroutine.
 %args: Passes any extra arguments to the RestApi's 'api' subroutine (content,
   params, method etc).

You would not normally call this directly unless you were
making a Google API call not currently supported by this API
framework.

=item create_spreadsheet(title|name => <string>, %args);

Creates a new spreadsheet with the title/name (same thing). Note that Sheets
allows multiple spreadsheets with the same name.

 title|name: The title (or name) of the new spreadsheet.
 %args: Passes any extra arguments to Google Drive's create file routine.

=item copy_spreadsheet(spreadsheet_id => <string>, %args);

Creates a copy of a spreadsheet.

 spreadsheet_id: The file ID in Google Drive of the spreadsheet you want to
   make a copy of.
 %args: Additional arguments passed to Google Drive file copy subroutine.

=item delete_spreadsheet(spreadsheet_id<string>);

Deletes a spreadsheet from Google Drive.

 spreadsheet_id: The file ID in Google Drive of the spreadsheet you want to
   delete.

=item delete_all_spreadsheets(spreadsheet_name<string>);

Deletes all spreadsheets with the given name from Google Drive. Note that
Google Sheets allows more than one spreadsheet to have the same name. Returns
the number of spreadsheets deleted.

 spreadsheet_name: The name of the spreadsheets you want to delete.

=item spreadsheets();

Returns a list of spreadsheets in Google Drive.

=item drive();

Returns an instance of Google Drive that shares the same RestApi as this
SheetsApi object. You would not normally need to use this directly.

=item open_spreadsheet(%args);

Opens a new spreadsheet from the given ID, URI, or name.

 %args: Passes any args to Spreadsheet->new routine.

=item stats()

Shows some statistics on how many get/put/post etc calls were made.
Useful for performance tuning during development.

=back

=head1 STATUS

This api is currently very much in beta status. It is incomplete.
There may be design flaws that need to be addressed in later
releases. Later releases may break this release. Not all api
calls have been implemented. Tests are not comprehensive.

But it gets the job done.

This is a work in progress, released at this stage in order to
assist others, and in the hopes that others will contribute to
its completeness.

Pull requests welcome.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

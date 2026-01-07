package Test::Google::RestApi::SheetsApi4::Request::Spreadsheet;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Request::Spreadsheet';

use parent 'Test::Unit::TestBase';

init_logger;

# Clear any pending requests before each test to ensure test isolation
sub setup : Test(setup) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();
  # Clear any pending requests from previous tests
  $ss->{requests} = [];
  return;
}

sub ss_update_spreadsheet_properties : Tests(8) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $request = {
    updateSpreadsheetProperties => {
      properties => {},
      fields     => '',
    },
  };
  my $properties = $request->{updateSpreadsheetProperties}->{properties};

  is $ss->ss_title('My Spreadsheet'), $ss, "ss_title should return same spreadsheet";
  $properties->{title} = 'My Spreadsheet';
  _add_field($request, 'title');
  my @requests = $ss->batch_requests();
  is_deeply $requests[0], $request, "ss_title should be staged";

  $ss->submit_requests();

  is $ss->ss_locale('en_US'), $ss, "ss_locale should return same spreadsheet";
  $request->{updateSpreadsheetProperties}->{properties} = { locale => 'en_US' };
  $request->{updateSpreadsheetProperties}->{fields} = 'locale';
  @requests = $ss->batch_requests();
  is_deeply $requests[0], $request, "ss_locale should be staged";

  $ss->submit_requests();

  is $ss->ss_time_zone('America/New_York'), $ss, "ss_time_zone should return same spreadsheet";
  $request->{updateSpreadsheetProperties}->{properties} = { timeZone => 'America/New_York' };
  $request->{updateSpreadsheetProperties}->{fields} = 'timeZone';
  @requests = $ss->batch_requests();
  is_deeply $requests[0], $request, "ss_time_zone should be staged";

  $ss->submit_requests();

  is $ss->ss_auto_recalc('ON_CHANGE'), $ss, "ss_auto_recalc should return same spreadsheet";
  $request->{updateSpreadsheetProperties}->{properties} = { autoRecalc => 'ON_CHANGE' };
  $request->{updateSpreadsheetProperties}->{fields} = 'autoRecalc';
  @requests = $ss->batch_requests();
  is_deeply $requests[0], $request, "ss_auto_recalc should be staged";

  $ss->submit_requests();

  return;
}

sub ss_iteration_settings : Tests(4) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();

  is $ss->ss_iteration_count(10), $ss, "ss_iteration_count should return same spreadsheet";
  my @requests = $ss->batch_requests();
  my $expected = {
    updateSpreadsheetProperties => {
      properties => { iterativeCalculationSettings => { maxIterations => 10 } },
      fields     => 'iterativeCalculationSettings.maxIterations',
    },
  };
  is_deeply $requests[0], $expected, "ss_iteration_count should be staged";

  $ss->submit_requests();

  is $ss->ss_iteration_threshold(0.001), $ss, "ss_iteration_threshold should return same spreadsheet";
  @requests = $ss->batch_requests();
  $expected = {
    updateSpreadsheetProperties => {
      properties => { iterativeCalculationSettings => { convergenceThreshold => 0.001 } },
      fields     => 'iterativeCalculationSettings.convergenceThreshold',
    },
  };
  is_deeply $requests[0], $expected, "ss_iteration_threshold should be staged";

  $ss->submit_requests();

  return;
}

sub ss_protected_range : Tests(6) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  my $range = { sheetId => 0, startRowIndex => 0, endRowIndex => 10, startColumnIndex => 0, endColumnIndex => 5 };

  # Test add_protected_range
  is $ss->add_protected_range(range => $range, description => 'Test protection'), $ss, "add_protected_range should return same spreadsheet";
  my @requests = $ss->batch_requests();
  my $expected = {
    addProtectedRange => {
      protectedRange => {
        range       => $range,
        description => 'Test protection',
      },
    },
  };
  is_deeply $requests[0], $expected, "add_protected_range should be staged";

  # Submit and get the protected range ID from the response
  $ss->submit_requests();
  my $responses = $ss->requests_response_from_api();
  my $protected_id = $responses->[0]{addProtectedRange}{protectedRange}{protectedRangeId};

  # Test update_protected_range with real ID
  my $new_range = { sheetId => 0, startRowIndex => 5, endRowIndex => 15, startColumnIndex => 0, endColumnIndex => 3 };
  is $ss->update_protected_range(
    id          => $protected_id,
    range       => $new_range,
    description => 'Updated protection',
  ), $ss, "update_protected_range should return same spreadsheet";

  @requests = $ss->batch_requests();
  $expected = {
    updateProtectedRange => {
      protectedRange => {
        protectedRangeId => $protected_id,
        range            => $new_range,
        description      => 'Updated protection',
      },
      fields => 'range,description',
    },
  };
  is_deeply $requests[0], $expected, "update_protected_range should be staged";

  $ss->submit_requests();

  # Test delete_protected_range with real ID
  is $ss->delete_protected_range($protected_id), $ss, "delete_protected_range should return same spreadsheet";
  @requests = $ss->batch_requests();
  $expected = {
    deleteProtectedRange => {
      protectedRangeId => $protected_id,
    },
  };
  is_deeply $requests[0], $expected, "delete_protected_range should be staged";

  $ss->submit_requests();

  return;
}

sub _add_field {
  my ($request, $field) = (@_);
  my %fields = map { $_ => 1; } split(',', $request->{updateSpreadsheetProperties}->{fields}), $field;
  $request->{updateSpreadsheetProperties}->{fields} = join(',', sort keys %fields);
  return;
}

1;

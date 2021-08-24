package Test::Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet';

sub class { Worksheet; }

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
  ));

  return;
}

sub ws_format : Tests() {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $ws0 = fake_worksheet();
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

  return;
}

sub _add_field {
  my ($ws, $field) = (@_);
  my %fields = map { $_ => 1; } split(',', $ws->{updateSheetProperties}->{fields}), $field;
  $ws->{updateSheetProperties}->{fields} = join(',', sort keys %fields);
  return;
}

1;

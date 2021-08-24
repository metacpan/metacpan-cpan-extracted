package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie';

sub class { Tie; }

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
    get_worksheet_values_cell
    get_worksheet_values_a1_b1_c1
    get_worksheet_values_range
    post_worksheet_values_x_y_z
    post_worksheet_batch_request
    put_worksheet_values_range
  ));
  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  return;
}

sub tie : Tests(16) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  my $worksheet_name = fake_worksheet_name();
  $worksheet->rest_api()->max_attempts(1);

  my $tied;
  is_hash $tied = $worksheet->tie_cells(qw(A1 B1 C1)), "Tie some cells";

  tied(%$tied)->fetch_range(1);
  for (qw(A1 B1 C1)) {
    isa_ok $tied->{$_}, Cell, "Key '$_'";
    is $tied->{$_}->range(), "'$worksheet_name'!$_", "Cell '$_' is range '$_'";
  }
  tied(%$tied)->fetch_range(0);

  is_deeply tied(%$tied)->values(), [undef,undef,undef], "Tied cell values";

  $tied->{A1} = 1000;
  $tied->{B1} = "Joe Blogs";
  $tied->{C1} = "123 Some Street";

  is $worksheet->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $worksheet->cell("B1"), undef, "Cell 'B1' is 'undef'";
  is $worksheet->cell("C1"), undef, "Cell 'C1' is 'undef'";

  is_array my $values = tied(%$tied)->submit_values(), "Updating cells";
  is scalar @$values, 3, "Updated three values";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B1"), "Joe Blogs", "Cell 'B1' is 'Joe Blogs'";
  is $worksheet->cell("C1"), "123 Some Street", "Cell 'C1' is '123 Some Street'";

  return;
}

sub tie_named : Tests(16) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  my $worksheet_name = fake_worksheet_name();
  $worksheet->rest_api()->max_attempts(1);

  my %ties = (
    id      => 'A1',
    name    => 'B1',
    address => 'C1',
  );
  my @ties = map { { $_ => $ties{$_} }; } keys %ties;
  
  my $tied;
  is_hash $tied = $worksheet->tie_cells(@ties), "Tie some cells";

  tied(%$tied)->fetch_range(1);
  while (my ($k, $v) = each %ties) {
    isa_ok $tied->{$k}, Cell, "Key '$k'";
    is $tied->{$k}->range(), "'$worksheet_name'!$v", "Cell '$k' is range '$v'";
  }
  tied(%$tied)->fetch_range(0);

  is_deeply tied(%$tied)->values(), [undef,undef,undef], "Tied cell values";

  $tied->{id} = 1000;
  $tied->{name} = "Joe Blogs";
  $tied->{address} = "123 Some Street";

  is $worksheet->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $worksheet->cell("B1"), undef, "Cell 'B1' is 'undef'";
  is $worksheet->cell("C1"), undef, "Cell 'C1' is 'undef'";

  is_array my $values = tied(%$tied)->submit_values(), "Updating cells";
  is scalar @$values, 3, "Updated three values";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B1"), "Joe Blogs", "Cell 'B1' is 'Joe Blogs'";
  is $worksheet->cell("C1"), "123 Some Street", "Cell 'C1' is '123 Some Street'";

  return;
}

sub tie_cols : Tests(18) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  my $worksheet_name = fake_worksheet_name();
  $worksheet->rest_api()->max_attempts(1);

  my %ties = (
    id      => 'B:B',
    name    => 'C:C',
    address => 'D:D',
  );
  my @ties = map { { $_ => $ties{$_} }; } keys %ties;
  
  my $tied;
  is_hash $tied = $worksheet->tie_cols(@ties), "Tie cols";

  tied(%$tied)->fetch_range(1);
  while (my ($k, $v) = each %ties) {
    isa_ok $tied->{$k}, Col, "Key '$k' should be a col";
    is $tied->{$k}->range(), "'$worksheet_name'!$v", "Col '$k' is range '$v'";
  }
  tied(%$tied)->fetch_range(0);

  $tied->{id} = [ 1000, 1001, 1002 ];
  $tied->{name} = [ "Joe Blogs", "Freddie Mercury", "Iggy Pop" ];
  $tied->{address} = [ "123 Some Street", "345 Some Other Street", "Another Universe" ];

  is_array my $values = tied(%$tied)->submit_values(), "Updating columns";
  is scalar @$values, 3, "Updated three values";

  is $worksheet->cell("B1"), 1000, "Cell 'B1' is '1000'";
  is $worksheet->cell("C1"), "Joe Blogs", "Cell 'C1' is 'Joe Blogs'";
  is $worksheet->cell("D1"), "123 Some Street", "Cell 'D1' is '123 Some Street'";

  is $worksheet->cell("B2"), 1001, "Cell 'B2' is '1001'";
  is $worksheet->cell("C2"), "Freddie Mercury", "Cell 'C2' is 'Freddie Mercury'";
  is $worksheet->cell("D2"), "345 Some Other Street", "Cell 'D2' is '345 Some Other Street'";

  is $worksheet->cell("B3"), 1002, "Cell 'B3' is '1002'";
  is $worksheet->cell("C3"), "Iggy Pop", "Cell 'C3' is 'Iggy Pop'";
  is $worksheet->cell("D3"), "Another Universe", "Cell 'D3' is 'Another Universe'";

  return;
}

sub tie_rows : Tests(18) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  my $worksheet_name = fake_worksheet_name();
  $worksheet->rest_api()->max_attempts(1);

  my %ties = (
    id      => '2:2',
    name    => '3:3',
    address => '4:4',
  );
  my @ties = map { { $_ => $ties{$_} }; } keys %ties;
  
  my $tied;
  is_hash $tied = $worksheet->tie_rows(@ties), "Tie rows";

  tied(%$tied)->fetch_range(1);
  while (my ($k, $v) = each %ties) {
    isa_ok $tied->{$k}, Row, "Key '$k' should be a row";
    is $tied->{$k}->range(), "'$worksheet_name'!$v", "Row '$k' is range '$v'";
  }
  tied(%$tied)->fetch_range(0);

  $tied->{id} = [ 1000, 1001, 1002 ];
  $tied->{name} = [ "Joe Blogs", "Freddie Mercury", "Iggy Pop" ];
  $tied->{address} = [ "123 Some Street", "345 Some Other Street", "Another Universe" ];

  is_array my $values = tied(%$tied)->submit_values(), "Updating rows";
  is scalar @$values, 3, "Updated three values";

  is $worksheet->cell("A2"), 1000, "Cell 'A2' is '1000'";
  is $worksheet->cell("A3"), "Joe Blogs", "Cell 'C1' is 'Joe Blogs'";
  is $worksheet->cell("A4"), "123 Some Street", "Cell 'D1' is '123 Some Street'";

  is $worksheet->cell("B2"), 1001, "Cell 'B2' is '1001'";
  is $worksheet->cell("B3"), "Freddie Mercury", "Cell 'C2' is 'Freddie Mercury'";
  is $worksheet->cell("B4"), "345 Some Other Street", "Cell 'D2' is '345 Some Other Street'";

  is $worksheet->cell("C2"), 1002, "Cell 'C2' is '1002'";
  is $worksheet->cell("C3"), "Iggy Pop", "Cell 'C3' is 'Iggy Pop'";
  is $worksheet->cell("C4"), "Another Universe", "Cell 'D3' is 'Another Universe'";

  
  
  return;
}

sub tie_cell { # : Tests(7) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  $worksheet->rest_api()->max_attempts(1);

  my $tied;
  is_hash $tied = $worksheet->tie(), "Create blank tie";
  my $ranges = $worksheet->tie_cells('A1', { fred => [2, 2] });
  is_hash tied(%$tied)->add_tied($ranges), "Adding tied cells";
  is_array tied(%$tied)->values(), "Tied cell batch values";

  $tied->{A1} = 1000;
  $tied->{fred} = "Joe Blogs";
  $tied->{C3} = "123 Some Street";

  is_array tied(%$tied)->submit_values(), "Updating cells";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_slice : Tests(10) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  $worksheet->rest_api()->max_attempts(1);

  my $tied;
  is_hash $tied = $worksheet->tie(), "Create blank tie";
  @$tied{ 'A1', 'B2', 'C3', 'D4:E5' } = (1000, "Joe Blogs", "123 Some Street", [["Halifax"]]);

  is $worksheet->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $worksheet->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $worksheet->cell("C3"), undef, "Cell 'C3' is 'undef'";
  is_deeply $worksheet->range("D4:E5")->values(), [], "Range 'D4:E5' is 'undef'";

  is_array tied(%$tied)->submit_values(), "Updating cells";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";
  is_deeply $worksheet->range("D4:E5")->values(), [["Halifax"]], "Range 'D4:E5' is 'Halifax'";

  return;
}

sub tie_return_objects : Tests(6) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $worksheet = fake_worksheet();
  $worksheet->rest_api()->max_attempts(1);

  my $cols = $worksheet->tie_cols({id => 'B:B'}, {name => 'C:C'}, {address => 'D:D'});
  isa_ok tied(%$cols)->fetch_range(1), $self->class(), "Turning on cols return objects";
  isa_ok $cols->{id}->red(), Col, "Setting id to red";
  isa_ok $cols->{name}->center(), Col, "Setting name centered";
  isa_ok $cols->{address}->font_size(12), Col, "Setting address font size";
  isa_ok tied(%$cols)->fetch_range(0), $self->class(), "Turning off return objects";
  is_hash tied(%$cols)->submit_requests(), "Submitting requests";

  return;
}

1;

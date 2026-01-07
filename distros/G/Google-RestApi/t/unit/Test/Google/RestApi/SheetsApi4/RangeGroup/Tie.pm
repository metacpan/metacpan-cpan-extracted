package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie';

use parent 'Test::Unit::TestBase';

init_logger;

sub setup : Tests(setup) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $all = $ws0->range("A1:C1000");
  $all->reset()->submit_requests;
  $ws0->spreadsheet->cache_seconds(0);

  return;
}

sub tie : Tests(16) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $ws0_name = mock_worksheet_name();
  $ws0->rest_api()->max_attempts(1);

  is_hash my $tied = $ws0->tie_cells(A1 => 'A1', B1 => 'B1', C1 => 'C1'), "Tie some cells";

  tied(%$tied)->fetch_range(1);
  for (qw(A1 B1 C1)) {
    isa_ok $tied->{$_}, Cell, "Key '$_'";
    is $tied->{$_}->range(), "'$ws0_name'!$_", "Cell '$_' is range '$_'";
  }
  tied(%$tied)->fetch_range(0);

  is_deeply tied(%$tied)->values(), [undef,undef,undef], "Tied cell values";

  $tied->{A1} = 1000;
  $tied->{B1} = "Joe Blogs";
  $tied->{C1} = "123 Some Street";

  is $ws0->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $ws0->cell("B1"), undef, "Cell 'B1' is 'undef'";
  is $ws0->cell("C1"), undef, "Cell 'C1' is 'undef'";

  is_array my $values = tied(%$tied)->submit_values(), "Updating cells";
  is scalar @$values, 3, "Updated three values";

  is $ws0->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $ws0->cell("B1"), "Joe Blogs", "Cell 'B1' is 'Joe Blogs'";
  is $ws0->cell("C1"), "123 Some Street", "Cell 'C1' is '123 Some Street'";

  return;
}

sub tie_cols : Tests(18) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $ws0_name = mock_worksheet_name();
  $ws0->rest_api()->max_attempts(1);
  $ws0->enable_header_row();

  my %ties = (
    id      => 'B',
    name    => [ 3 ],
    address => { col => 4 },
  );
  
  is_hash my $tied = $ws0->tie_cols(%ties), "Tie cols";

  tied(%$tied)->fetch_range(1);
  isa_ok $tied->{$_}, Col, "Key '$_' should be a col" for (keys %$tied);
  is $tied->{id}->range(), "'$ws0_name'!B:B", "Col 'id' is range 'B:B'";
  is $tied->{name}->range(), "'$ws0_name'!C:C", "Col 'name' is range 'C:C'";
  is $tied->{address}->range(), "'$ws0_name'!D:D", "Col 'address' is range 'D:D'";
  tied(%$tied)->fetch_range(0);

  $tied->{id} = [ 1000, 1001, 1002 ];
  $tied->{name} = [ "Joe Blogs", "Freddie Mercury", "Iggy Pop" ];
  $tied->{address} = [ "123 Some Street", "345 Some Other Street", "Another Universe" ];

  is_array my $values = tied(%$tied)->submit_values(), "Updating columns";
  is scalar @$values, 3, "Updated three values";

  is $ws0->cell("B1"), 1000, "Cell 'B1' is '1000'";
  is $ws0->cell("C1"), "Joe Blogs", "Cell 'C1' is 'Joe Blogs'";
  is $ws0->cell("D1"), "123 Some Street", "Cell 'D1' is '123 Some Street'";

  is $ws0->cell("B2"), 1001, "Cell 'B2' is '1001'";
  is $ws0->cell("C2"), "Freddie Mercury", "Cell 'C2' is 'Freddie Mercury'";
  is $ws0->cell("D2"), "345 Some Other Street", "Cell 'D2' is '345 Some Other Street'";

  is $ws0->cell("B3"), 1002, "Cell 'B3' is '1002'";
  is $ws0->cell("C3"), "Iggy Pop", "Cell 'C3' is 'Iggy Pop'";
  is $ws0->cell("D3"), "Another Universe", "Cell 'D3' is 'Another Universe'";

  return;
}

sub tie_rows : Tests(18) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $ws0_name = mock_worksheet_name();
  $ws0->rest_api()->max_attempts(1);

  my %ties = (
    id      => 2,
    name    => [ 0, 3 ],
    address => { row => 4 },
  );
  
  is_hash my $tied = $ws0->tie_rows(%ties), "Tie rows";

  tied(%$tied)->fetch_range(1);
  for (keys %$tied) {
    isa_ok $tied->{$_}, Row, "Key '$_' should be a row";
  }
  is $tied->{id}->range(), "'$ws0_name'!2:2", "Row 'id' is range '2:2'";
  is $tied->{name}->range(), "'$ws0_name'!3:3", "Row 'name' is range '3:3'";
  is $tied->{address}->range(), "'$ws0_name'!4:4", "Row 'address' is range '4:4'";
  tied(%$tied)->fetch_range(0);

  $tied->{id} = [ 1000, 1001, 1002 ];
  $tied->{name} = [ "Joe Blogs", "Freddie Mercury", "Iggy Pop" ];
  $tied->{address} = [ "123 Some Street", "345 Some Other Street", "Another Universe" ];

  is_array my $values = tied(%$tied)->submit_values(), "Updating rows";
  is scalar @$values, 3, "Updated three values";

  is $ws0->cell("A2"), 1000, "Cell 'A2' is '1000'";
  is $ws0->cell("A3"), "Joe Blogs", "Cell 'C1' is 'Joe Blogs'";
  is $ws0->cell("A4"), "123 Some Street", "Cell 'D1' is '123 Some Street'";

  is $ws0->cell("B2"), 1001, "Cell 'B2' is '1001'";
  is $ws0->cell("B3"), "Freddie Mercury", "Cell 'C2' is 'Freddie Mercury'";
  is $ws0->cell("B4"), "345 Some Other Street", "Cell 'D2' is '345 Some Other Street'";

  is $ws0->cell("C2"), 1002, "Cell 'C2' is '1002'";
  is $ws0->cell("C3"), "Iggy Pop", "Cell 'C3' is 'Iggy Pop'";
  is $ws0->cell("C4"), "Another Universe", "Cell 'D3' is 'Another Universe'";

  return;
}

sub tie_cells : Tests(7) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  $ws0->rest_api()->max_attempts(1);

  my $tied;
  is_hash $tied = $ws0->tie(), "Create blank tie";
  my $ranges = $ws0->tie_cells(A1 => 'A1', fred => [2, 2], charlie => { col => 3, row => 3 });
  is_hash tied(%$tied)->add_tied($ranges), "Adding tied cells";
  is_array tied(%$tied)->values(), "Tied cell batch values";

  $tied->{A1} = 1000;
  $tied->{fred} = "Joe Blogs";
  $tied->{charlie} = "123 Some Street";

  is_array tied(%$tied)->submit_values(), "Updating cells";

  is $ws0->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $ws0->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $ws0->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_slice : Tests(10) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  $ws0->rest_api()->max_attempts(1);

  is_hash my $tied = $ws0->tie(), "Create blank tie";
  @$tied{ 'A1', 'B2', 'C3', 'D4:E5' } = (1000, "Joe Blogs", "123 Some Street", [["Halifax"]]);

  is $ws0->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $ws0->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $ws0->cell("C3"), undef, "Cell 'C3' is 'undef'";
  is_deeply $ws0->range("D4:E5")->values(), [], "Range 'D4:E5' is 'undef'";

  is_array tied(%$tied)->submit_values(), "Updating cells";

  is $ws0->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $ws0->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $ws0->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";
  is_deeply $ws0->range("D4:E5")->values(), [["Halifax"]], "Range 'D4:E5' is 'Halifax'";

  return;
}

sub tie_named : Tests(16) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $ws0_name = mock_worksheet_name();
  $ws0->rest_api()->max_attempts(1);

  my %ties = (
    id      => 'A1',
    name    => 'B1',
    address => 'C1',
  );
  
  is_hash my $tied = $ws0->tie_cells(%ties), "Tie some cells";

  tied(%$tied)->fetch_range(1);
  while (my ($k, $v) = each %ties) {
    isa_ok $tied->{$k}, Cell, "Key '$k'";
    is $tied->{$k}->range(), "'$ws0_name'!$v", "Cell '$k' is range '$v'";
  }
  tied(%$tied)->fetch_range(0);

  is_deeply tied(%$tied)->values(), [undef,undef,undef], "Tied cell values";

  $tied->{id} = 1000;
  $tied->{name} = "Joe Blogs";
  $tied->{address} = "123 Some Street";

  is $ws0->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $ws0->cell("B1"), undef, "Cell 'B1' is 'undef'";
  is $ws0->cell("C1"), undef, "Cell 'C1' is 'undef'";

  is_array my $values = tied(%$tied)->submit_values(), "Updating cells";
  is scalar @$values, 3, "Updated three values";

  is $ws0->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $ws0->cell("B1"), "Joe Blogs", "Cell 'B1' is 'Joe Blogs'";
  is $ws0->cell("C1"), "123 Some Street", "Cell 'C1' is '123 Some Street'";

  return;
}

sub tie_return_objects : Tests(6) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  $ws0->rest_api()->max_attempts(1);

  my $cols = $ws0->tie_cols(id => 'B:B', name => 'C:C', address => 'D:D');
  isa_ok tied(%$cols)->fetch_range(1), Tie, "Turning on cols return objects";
  isa_ok $cols->{id}->red(), Col, "Setting id to red";
  isa_ok $cols->{name}->center(), Col, "Setting name centered";
  isa_ok $cols->{address}->font_size(12), Col, "Setting address font size";
  isa_ok tied(%$cols)->fetch_range(0), Tie, "Turning off return objects";
  is_hash tied(%$cols)->submit_requests(), "Submitting requests";

  return;
}

1;

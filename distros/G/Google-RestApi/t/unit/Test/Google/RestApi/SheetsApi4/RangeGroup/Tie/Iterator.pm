package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator';

use parent qw(Test::Unit::TestBase);

init_logger;

sub interate : Tests(14) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  $ws0->enable_header_row();

  my %ties = (
    id      => 'B',
    name    => [ 3 ],
    address => { col => 4 },
  );
  my $cols = $ws0->tie_cols(%ties);

  isa_ok my $iterator = tied(%$cols)->iterator(from => 1), Iterator, "Tie iterator creation";

  is $ws0->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $ws0->cell("C2"), undef, "Cell 'C2' is 'undef'";
  is $ws0->cell("D2"), undef, "Cell 'D2' is 'undef'";

  is_hash my $row = $iterator->iterate(), "First tied iteration";

  $row->{id} = 1000;
  $row->{name} = "Joe Blogs";
  $row->{address} = "123 Some Street";
  is_array tied(%$row)->submit_values(), "Updating a row";

  is $ws0->cell("B2"), 1000, "Cell 'B2' is '1000'";
  is $ws0->cell("C2"), "Joe Blogs", "Cell 'C2' is 'Joe Blogs'";
  is $ws0->cell("D2"), "123 Some Street", "Cell 'D2' is '123 Some Street'";

  is_hash $row = $iterator->iterate(), "Second tied iteration";
  $row->{id} = 1001;
  $row->{name} = "Freddie Mercury";
  $row->{address} = "321 Some Other Street";
  is_array tied(%$row)->submit_values(), "Updating a row";

  is $ws0->cell("B3"), 1001, "Cell 'B3' is '1001'";
  is $ws0->cell("C3"), "Freddie Mercury", "Cell 'C3' is 'Freddie Mercury'";
  is $ws0->cell("D3"), "321 Some Other Street", "Cell 'D3' is '321 Some Other Street'";

  return;
}

1;

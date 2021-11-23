package Test::Google::RestApi::SheetsApi4::Range::Col;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Col';

use parent qw(Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

# init_logger($TRACE);

sub range : Tests(12) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $x = 'A';
  my $y = '1';

  my $range = _new_range("$x:$x");
  is $range->range(), "$sheet!$x:$x", "$x:$x should be $x:$x";

  
  $range = _new_range([$x]);
  is $range->range(), "$sheet!$x:$x", "[$x] should be $x:$x";

  $range = _new_range([$y]);
  is $range->range(), "$sheet!$x:$x", "[$y] should be $x:$x";


  $range = _new_range([[$x]]);
  is $range->range(), "$sheet!$x:$x", "[[$x]] should be $x:$x";

  $range = _new_range([[$y]]);
  is $range->range(), "$sheet!$x:$x", "[[$y]] should be $x:$x";


  $range = _new_range({col => $x});
  is $range->range(), "$sheet!$x:$x", "{col => $x} should be $x:$x";

  $range = _new_range({col => $y});
  is $range->range(), "$sheet!$x:$x", "{col => $y} should be $x:$x";


  $range = _new_range([{col => $x}]);
  is $range->range(), "$sheet!$x:$x", "[{col => $x}] should be $x:$x";

  $range = _new_range([{col => $y}]);
  is $range->range(), "$sheet!$x:$x", "[{col => $y}] should be $x:$x";


  $range = _new_range([[$x, 5], [$x]]);
  is $range->range(), "$sheet!${x}5:$x", "[[$x, 5], [$x]] should be ${x}5:$x";

  $range = _new_range([{col => $x, row => 5}, {col => $x}]);
  is $range->range(), "$sheet!${x}5:$x", "[{col => $x, row => 5}, {col => $x}] should be ${x}5:$x";

  $x = "AA10:AA11";
  $range = _new_range($x);
  is $range->range(), "$sheet!$x", "$x should be a col";

  return;
}

sub _new_range { fake_worksheet()->range_col(shift); }

1;

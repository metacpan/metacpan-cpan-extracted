package Test::Google::RestApi::SheetsApi4::Range::Row;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Row';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

sub range : Tests(14) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $x = '1';

  my $range = _new_range("$x:$x");
  is $range->range(), "$sheet!$x:$x", "$x:$x should be $x:$x";

  $range = _new_range([undef, $x]);
  is $range->range(), "$sheet!$x:$x", "[undef, $x] should be $x:$x";
  $range = _new_range([0, $x]);
  is $range->range(), "$sheet!$x:$x", "[0, $x] should be $x:$x";
  $range = _new_range(['', $x]);
  is $range->range(), "$sheet!$x:$x", "['', $x] should be $x:$x";

  $range = _new_range([[undef, $x]]);
  is $range->range(), "$sheet!$x:$x", "[[undef, $x]] should be $x:$x";
  $range = _new_range([[0, $x]]);
  is $range->range(), "$sheet!$x:$x", "[[0, $x]] should be $x:$x";
  $range = _new_range([['', $x]]);
  is $range->range(), "$sheet!$x:$x", "[['', $x]] should be $x:$x";

  $range = _new_range({row => $x});
  is $range->range(), "$sheet!$x:$x", "{row => $x} should be $x:$x";

  $range = _new_range([{row => $x}]);
  is $range->range(), "$sheet!$x:$x", "[{row => $x}] should be $x:$x";

  $range = _new_range([[5, $x], [undef, $x]]);
  is $range->range(), "$sheet!E$x:$x", "[[5, $x], [undef, $x]] should be E$x:$x";
  $range = _new_range([[5, $x], [0, $x]]);
  is $range->range(), "$sheet!E$x:$x", "[[5, $x], [0, $x]] should be E$x:$x";
  $range = _new_range([[5, $x], ['', $x]]);
  is $range->range(), "$sheet!E$x:$x", "[[5, $x], ['', $x]] should be E$x:$x";

  $range = _new_range([{row => $x, col => 5}, {row => $x}]);
  is $range->range(), "$sheet!E$x:$x", "[{row => $x, col => 5}, {row => $x}] should be E$x:$x";

  $x = "AA10:BB10";
  $range = _new_range($x);
  is $range->range(), "$sheet!$x", "$x should be a row";

  return;
}

sub _new_range { fake_worksheet()->range_row(shift); }

1;

package Test::Google::RestApi::SheetsApi4::Range::Col;

use Test::Unit::Setup;

use parent qw(Test::Google::RestApi::SheetsApi4::Range::Base);

use aliased 'Google::RestApi::SheetsApi4::Range::Col';

my $sheet = "'Sheet1'";

sub class { Col; }

# init_logger($TRACE);

sub range : Tests(12) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $x = 'A';
  my $y = '1';

  my $range = $self->_new_range("$x:$x");
  is $range->range(), "$sheet!$x:$x", "$x:$x should be $x:$x";

  
  $range = $self->_new_range([$x]);
  is $range->range(), "$sheet!$x:$x", "[$x] should be $x:$x";

  $range = $self->_new_range([$y]);
  is $range->range(), "$sheet!$x:$x", "[$y] should be $x:$x";


  $range = $self->_new_range([[$x]]);
  is $range->range(), "$sheet!$x:$x", "[[$x]] should be $x:$x";

  $range = $self->_new_range([[$y]]);
  is $range->range(), "$sheet!$x:$x", "[[$y]] should be $x:$x";


  $range = $self->_new_range({col => $x});
  is $range->range(), "$sheet!$x:$x", "{col => $x} should be $x:$x";

  $range = $self->_new_range({col => $y});
  is $range->range(), "$sheet!$x:$x", "{col => $y} should be $x:$x";


  $range = $self->_new_range([{col => $x}]);
  is $range->range(), "$sheet!$x:$x", "[{col => $x}] should be $x:$x";

  $range = $self->_new_range([{col => $y}]);
  is $range->range(), "$sheet!$x:$x", "[{col => $y}] should be $x:$x";


  $range = $self->_new_range([[$x, 5], [$x]]);
  is $range->range(), "$sheet!${x}5:$x", "[[$x, 5], [$x]] should be ${x}5:$x";

  $range = $self->_new_range([{col => $x, row => 5}, {col => $x}]);
  is $range->range(), "$sheet!${x}5:$x", "[{col => $x, row => 5}, {col => $x}] should be ${x}5:$x";

  $x = "AA10:AA11";
  $range = $self->_new_range($x);
  is $range->range(), "$sheet!$x", "$x should be a col";

  return;
}

sub range_bad : Tests(18) {
  my $self = shift;
  $self->_fake_http_response_by_uri();
  $self->_range_bad('A1:B1');
  $self->_range_bad('AA11:BB11');
  $self->_range_bad(-1);
  return;
}

sub _range_bad {
  my $self = shift;

  my $x = shift;
  my $x_str = $self->_to_str($x);
  my $msg = "Bad col array should fail";
  
  my $range = $self->_new_range([$x]);
  throws_ok { $range->range() } $self->{err}, "[$x_str] $msg";

  $range = $self->_new_range([[$x]]);
  throws_ok { $range->range() } $self->{err}, "[[$x_str]] $msg";

  $range = $self->_new_range([$x, 1]);
  throws_ok { $range->range() } $self->{err}, "[$x_str, 1] $msg";

  $range = $self->_new_range([[$x, 1]]);
  throws_ok { $range->range() } $self->{err}, "[[$x_str, 1]] $msg";

  $range = $self->_new_range({col => $x});
  throws_ok { $range->range() } $self->{err}, "{col => $x_str} $msg";

  $range = $self->_new_range([{col => $x}]);
  throws_ok { $range->range() } $self->{err}, "[{col => $x_str}] $msg";

  return;
}

1;

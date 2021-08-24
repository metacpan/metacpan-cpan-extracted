package Test::Google::RestApi::SheetsApi4::Range::Row;

use Test::Unit::Setup;

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

use aliased 'Google::RestApi::SheetsApi4::Range::Row';

my $sheet = "'Sheet1'";

sub class { Row; }

sub range : Tests(14) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $x = '1';

  my $range = $self->_new_range("$x:$x");
  is $range->range(), "$sheet!$x:$x", "$x:$x should be $x:$x";

  $range = $self->_new_range([undef, $x]);
  is $range->range(), "$sheet!$x:$x", "[undef, $x] should be $x:$x";
  $range = $self->_new_range([0, $x]);
  is $range->range(), "$sheet!$x:$x", "[0, $x] should be $x:$x";
  $range = $self->_new_range(['', $x]);
  is $range->range(), "$sheet!$x:$x", "['', $x] should be $x:$x";

  $range = $self->_new_range([[undef, $x]]);
  is $range->range(), "$sheet!$x:$x", "[[undef, $x]] should be $x:$x";
  $range = $self->_new_range([[0, $x]]);
  is $range->range(), "$sheet!$x:$x", "[[0, $x]] should be $x:$x";
  $range = $self->_new_range([['', $x]]);
  is $range->range(), "$sheet!$x:$x", "[['', $x]] should be $x:$x";

  $range = $self->_new_range({row => $x});
  is $range->range(), "$sheet!$x:$x", "{row => $x} should be $x:$x";

  $range = $self->_new_range([{row => $x}]);
  is $range->range(), "$sheet!$x:$x", "[{row => $x}] should be $x:$x";

  $range = $self->_new_range([[5, $x], [undef, $x]]);
  is $range->range(), "$sheet!E$x:$x", "[[5, $x], [undef, $x]] should be E$x:$x";
  $range = $self->_new_range([[5, $x], [0, $x]]);
  is $range->range(), "$sheet!E$x:$x", "[[5, $x], [0, $x]] should be E$x:$x";
  $range = $self->_new_range([[5, $x], ['', $x]]);
  is $range->range(), "$sheet!E$x:$x", "[[5, $x], ['', $x]] should be E$x:$x";

  $range = $self->_new_range([{row => $x, col => 5}, {row => $x}]);
  is $range->range(), "$sheet!E$x:$x", "[{row => $x, col => 5}, {row => $x}] should be E$x:$x";

  $x = "AA10:BB10";
  $range = $self->_new_range($x);
  is $range->range(), "$sheet!$x", "$x should be a row";

  return;
}

sub range_bad : Tests(30) {
  my $self = shift;
  $self->_fake_http_response_by_uri();
  $self->_range_bad('A');
  $self->_range_bad('A1:A2');
  $self->_range_bad(-1);
  return;
}

sub _range_bad {
  my $self = shift;

  my $x = shift;
  my $x_str = $self->_to_str($x);
  my $msg = "Bad row array should fail";
  
  my $range = $self->_new_range([undef, $x]);
  throws_ok { $range->range() } $self->{err}, "[undef, $x_str] $msg";
  $range = $self->_new_range([0, $x]);
  throws_ok { $range->range() } $self->{err}, "[0, $x_str] $msg";
  $range = $self->_new_range(['', $x]);
  throws_ok { $range->range() } $self->{err}, "['', $x_str] $msg";

  $range = $self->_new_range([[undef, $x]]);
  throws_ok { $range->range() } $self->{err}, "[[undef, $x_str]] $msg";
  $range = $self->_new_range([[0, $x]]);
  throws_ok { $range->range() } $self->{err}, "[[0, $x_str]] $msg";
  $range = $self->_new_range([['', $x]]);
  throws_ok { $range->range() } $self->{err}, "[['', $x_str]] $msg";

  $range = $self->_new_range([1, $x]);
  throws_ok { $range->range() } $self->{err}, "[1,$x_str] $msg";

  $range = $self->_new_range([[1, $x]]);
  throws_ok { $range->range() } $self->{err}, "[[1,$x_str]] $msg";

  $range = $self->_new_range({row => $x});
  throws_ok { $range->range() } $self->{err}, "{row => $x_str} $msg";

  $range = $self->_new_range([{row => $x}]);
  throws_ok { $range->range() } $self->{err}, "[{row => $x_str}] $msg";

  return;
}

1;

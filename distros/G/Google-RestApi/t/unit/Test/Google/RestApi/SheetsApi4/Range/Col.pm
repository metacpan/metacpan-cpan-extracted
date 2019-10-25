package Test::Google::RestApi::SheetsApi4::Range::Col;

use Test::Most;

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

sub class { 'Google::RestApi::SheetsApi4::Range::Col' }

sub range : Tests(12) {
  my $self = shift;

  my $x = 'A';
  my $y = '1';

  my $range = $self->new_range("$x:$x");
  is $range->range(), "$self->{name}$x:$x", "$x:$x should be $x:$x";


  $range = $self->new_range([$x]);
  is $range->range(), "$self->{name}$x:$x", "[$x] should be $x:$x";

  $range = $self->new_range([$y]);
  is $range->range(), "$self->{name}$x:$x", "[$y] should be $x:$x";


  $range = $self->new_range([[$x]]);
  is $range->range(), "$self->{name}$x:$x", "[[$x]] should be $x:$x";

  $range = $self->new_range([[$y]]);
  is $range->range(), "$self->{name}$x:$x", "[[$y]] should be $x:$x";


  $range = $self->new_range({col => $x});
  is $range->range(), "$self->{name}$x:$x", "{col => $x} should be $x:$x";

  $range = $self->new_range({col => $y});
  is $range->range(), "$self->{name}$x:$x", "{col => $y} should be $x:$x";


  $range = $self->new_range([{col => $x}]);
  is $range->range(), "$self->{name}$x:$x", "[{col => $x}] should be $x:$x";

  $range = $self->new_range([{col => $y}]);
  is $range->range(), "$self->{name}$x:$x", "[{col => $y}] should be $x:$x";


  $range = $self->new_range([[$x, 5], [$x]]);
  is $range->range(), "$self->{name}${x}5:$x", "[[$x, 5], [$x]] should be ${x}5:$x";

  $range = $self->new_range([{col => $x, row => 5}, {col => $x}]);
  is $range->range(), "$self->{name}${x}5:$x", "[{col => $x, row => 5}, {col => $x}] should be ${x}5:$x";

  $x = "AA10:AA11";
  $range = $self->new_range($x);
  is $range->range(), "$self->{name}$x", "$x should be a col";

  return;
}

sub range_bad : Tests(18) {
  my $self = shift;
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
  
  my $range = $self->new_range([$x]);
  throws_ok { $range->range() } $self->{err}, "[$x_str] $msg";

  $range = $self->new_range([[$x]]);
  throws_ok { $range->range() } $self->{err}, "[[$x_str]] $msg";

  $range = $self->new_range([$x, 1]);
  throws_ok { $range->range() } $self->{err}, "[$x_str, 1] $msg";

  $range = $self->new_range([[$x, 1]]);
  throws_ok { $range->range() } $self->{err}, "[[$x_str, 1]] $msg";

  $range = $self->new_range({col => $x});
  throws_ok { $range->range() } $self->{err}, "{col => $x_str} $msg";

  $range = $self->new_range([{col => $x}]);
  throws_ok { $range->range() } $self->{err}, "[{col => $x_str}] $msg";

  return;
}

1;

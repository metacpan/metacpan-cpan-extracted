package Test::Google::RestApi::SheetsApi4::Range::Cell;

use Test::Unit::Setup;

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

my $sheet = "'Sheet1'";

sub class { Cell; }

sub range : Tests(13) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $x = 'A1';

  my $range = $self->_new_range($x);
  is $range->range(), "$sheet!$x", "$x should be $x";

  $range = $self->_new_range(['A', 1]);
  is $range->range(), "$sheet!$x", "['A', 1] should be $x";

  $range = $self->_new_range([['A', 1]]);
  is $range->range(), "$sheet!$x", "[['A', 1]] should be $x";

  $range = $self->_new_range([1, 1]);
  is $range->range(), "$sheet!$x", "[1, 1] should be $x";

  $range = $self->_new_range([[1, 1]]);
  is $range->range(), "$sheet!$x", "[[1, 1]] should be $x";

  $range = $self->_new_range({row => 1, col => 'A'});
  is $range->range(), "$sheet!$x", "{row => 1, col => 'A'} should be $x";

  $range = $self->_new_range([ {row => 1, col => 'A'} ]);
  is $range->range(), "$sheet!$x", "[{row => 1, col => 'A'}] should be $x";

  $range = $self->_new_range({row => 1, col => 1});
  is $range->range(), "$sheet!$x", "{row => 1, col => 1} should be $x";

  $range = $self->_new_range([ {row => 1, col => 1} ]);
  is $range->range(), "$sheet!$x", "[{row => 1, col => 1}] should be $x";

  $range = $self->_new_range([['A', 1], ['A', 1]]);
  is $range->range(), "$sheet!$x", "[['A', 1], ['A', 1]] should be $x";

  $range = $self->_new_range([[1, 1], [1, 1]]);
  is $range->range(), "$sheet!$x", "[[1, 1], [1, 1]] should be $x";

  $range = $self->_new_range( {row => 1, col => 'A'}, {row => 1, col => 'A'} );
  is $range->range(), "$sheet!$x", "{row => 1, col => 'A'}, {row => 1, col => 'A'} should be $x";

  $range = $self->_new_range( {row => 1, col => 1}, {row => 1, col => 1} );
  is $range->range(), "$sheet!$x", "{row => 1, col => 1}, {row => 1, col => 1} should be $x";

  return;
}

sub range_bad : Tests(2) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $range = $self->_new_range( [{row => 1, col => 1}, {row => 2, col => 2}] );
  throws_ok { $range->range() } $self->{err}, "A range should not be a cell";

  $range = $self->_new_range("A1:B2");
  throws_ok { $range->range() } $self->{err}, "A range should not be a cell";

  return;
}

1;

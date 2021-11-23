package Test::Google::RestApi::SheetsApi4::Range::Cell;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

sub range : Tests(13) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $x = 'A1';

  my $range = _new_range($x);
  is $range->range(), "$sheet!$x", "$x should be $x";

  $range = _new_range(['A', 1]);
  is $range->range(), "$sheet!$x", "['A', 1] should be $x";

  $range = _new_range([['A', 1]]);
  is $range->range(), "$sheet!$x", "[['A', 1]] should be $x";

  $range = _new_range([1, 1]);
  is $range->range(), "$sheet!$x", "[1, 1] should be $x";

  $range = _new_range([[1, 1]]);
  is $range->range(), "$sheet!$x", "[[1, 1]] should be $x";

  $range = _new_range({row => 1, col => 'A'});
  is $range->range(), "$sheet!$x", "{row => 1, col => 'A'} should be $x";

  $range = _new_range([ {row => 1, col => 'A'} ]);
  is $range->range(), "$sheet!$x", "[{row => 1, col => 'A'}] should be $x";

  $range = _new_range({row => 1, col => 1});
  is $range->range(), "$sheet!$x", "{row => 1, col => 1} should be $x";

  $range = _new_range([ {row => 1, col => 1} ]);
  is $range->range(), "$sheet!$x", "[{row => 1, col => 1}] should be $x";

  $range = _new_range([['A', 1], ['A', 1]]);
  is $range->range(), "$sheet!$x", "[['A', 1], ['A', 1]] should be $x";

  $range = _new_range([[1, 1], [1, 1]]);
  is $range->range(), "$sheet!$x", "[[1, 1], [1, 1]] should be $x";

  $range = _new_range( {row => 1, col => 'A'}, {row => 1, col => 'A'} );
  is $range->range(), "$sheet!$x", "{row => 1, col => 'A'}, {row => 1, col => 'A'} should be $x";

  $range = _new_range( {row => 1, col => 1}, {row => 1, col => 1} );
  is $range->range(), "$sheet!$x", "{row => 1, col => 1}, {row => 1, col => 1} should be $x";

  return;
}

sub _new_range { fake_worksheet()->range_cell(shift); }

1;

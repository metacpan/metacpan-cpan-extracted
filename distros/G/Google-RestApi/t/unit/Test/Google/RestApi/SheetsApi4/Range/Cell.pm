package Test::Google::RestApi::SheetsApi4::Range::Cell;

use Test::Most;

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

sub class { 'Google::RestApi::SheetsApi4::Range::Cell' }

sub range : Tests(13) {
  my $self = shift;

  my $x = 'A1';

  my $range = $self->new_range($x);
  is $range->range(), "$self->{name}$x", "$x should be $x";

  $range = $self->new_range(['A', 1]);
  is $range->range(), "$self->{name}$x", "['A', 1] should be $x";

  $range = $self->new_range([['A', 1]]);
  is $range->range(), "$self->{name}$x", "[['A', 1]] should be $x";

  $range = $self->new_range([1, 1]);
  is $range->range(), "$self->{name}$x", "[1, 1] should be $x";

  $range = $self->new_range([[1, 1]]);
  is $range->range(), "$self->{name}$x", "[[1, 1]] should be $x";

  $range = $self->new_range({row => 1, col => 'A'});
  is $range->range(), "$self->{name}$x", "{row => 1, col => 'A'} should be $x";

  $range = $self->new_range([ {row => 1, col => 'A'} ]);
  is $range->range(), "$self->{name}$x", "[{row => 1, col => 'A'}] should be $x";

  $range = $self->new_range({row => 1, col => 1});
  is $range->range(), "$self->{name}$x", "{row => 1, col => 1} should be $x";

  $range = $self->new_range([ {row => 1, col => 1} ]);
  is $range->range(), "$self->{name}$x", "[{row => 1, col => 1}] should be $x";

  $range = $self->new_range([['A', 1], ['A', 1]]);
  is $range->range(), "$self->{name}$x", "[['A', 1], ['A', 1]] should be $x";

  $range = $self->new_range([[1, 1], [1, 1]]);
  is $range->range(), "$self->{name}$x", "[[1, 1], [1, 1]] should be $x";

  $range = $self->new_range( {row => 1, col => 'A'}, {row => 1, col => 'A'} );
  is $range->range(), "$self->{name}$x", "{row => 1, col => 'A'}, {row => 1, col => 'A'} should be $x";

  $range = $self->new_range( {row => 1, col => 1}, {row => 1, col => 1} );
  is $range->range(), "$self->{name}$x", "{row => 1, col => 1}, {row => 1, col => 1} should be $x";

  return;
}

sub range_bad : Tests(2) {
  my $self = shift;

  my $range = $self->new_range( [{row => 1, col => 1}, {row => 2, col => 2}] );
  throws_ok { $range->range() } $self->{err}, "A range should not be a cell";

  $range = $self->new_range("A1:B2");
  throws_ok { $range->range() } $self->{err}, "A range should not be a cell";

  return;
}

1;

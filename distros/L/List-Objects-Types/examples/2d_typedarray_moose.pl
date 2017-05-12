use v5.14;

# Moose + multidimensional TypedArray example courtesy of TOBYINK:
#  http://www.perlmonks.org/?node_id=1052124

package Cell {
  use Moose;
  use Types::Standard -types;
  
  has name => (is => 'rw', isa => Str);
  
  __PACKAGE__->meta->make_immutable;
}

package Grid {
  use Moose;
  use Types::Standard -types;
  use List::Objects::Types -types;
  
  my $CellType = (InstanceOf['Cell'])->plus_coercions(
      Str, sub { 'Cell'->new(name => $_) },
  );
  
  has cells => (
      is      => 'ro',
      isa     => TypedArray[TypedArray[$CellType]],
      coerce  => 1,
      handles => {
          get_row   => 'get',
          set_row   => 'set',
          all_rows  => 'all',
          add_row   => 'push',
      },
  );
  
  sub get_cell {
      my $self = shift;
      my ($row, $col) = @_;
      
      $self->get_row($row)->get($col);
  }
  
  sub set_cell {
      my $self = shift;
      my ($row, $col, $value) = @_;
      
      $self->get_row($row)->set($col, $value);
  }
  
  sub all_cells {
      my $self = shift;
      map { $_->all } $self->all_rows;
  }
  
  sub get_col {
      my $self = shift;
      my ($col) = @_;
      
      map { $_->get($col) } $self->all_rows;
  }

  sub set_col {
      my $self = shift;
      my ($col, $values) = @_;
      
      my @rows = $self->all_rows;
      for my $i (0 .. $#rows) {
          $rows[$i]->set($col) = $values->[$i];
      }
  }

  sub add_col {
      my $self = shift;
      my ($values) = @_;
      
      my @rows = $self->all_rows;
      for my $i (0 .. $#rows) {
          $rows[$i]->push($values->[$i]);
      }
  }

  sub all_cols {
      my $self = shift;
      
      my $col_count   = $self->get_row(0)->count;
      my $return_type = TypedArray[$CellType];
      
      return
          map { $return_type->coerce($_); }
          map { [ $self->get_col($_) ]; }
          0 .. $col_count-1;
  }
  
  sub to_string {
      my $self = shift;
      join "\n", 
        map(join("\t", map($_->name, $_->all)), $self->all_rows);
  }

  __PACKAGE__->meta->make_immutable;
}

my $grid = Grid->new(
  cells => [
      [ 'foo1', 'bar1' ],
      [ 'foo2', 'bar2' ],
  ]
);

$grid->add_col(['baz1', 'baz2']);
$grid->get_cell(1, 1)->name('QUUX');

say $grid->to_string;

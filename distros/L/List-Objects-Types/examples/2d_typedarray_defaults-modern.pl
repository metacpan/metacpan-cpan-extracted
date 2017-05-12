use feature 'say';
# Original multidimensional TypedArray example courtesy of TOBYINK:
#  http://www.perlmonks.org/?node_id=1052124
# This is much like the Moops impl, but Function::Parameters over Kavorka and
# less class-related sugar.

package Cell {
  use Defaults::Modern;
  use Moo;
  
  has name => (is => 'rw', isa => Str);
}

package Grid {
  use Defaults::Modern;
  use Moo;
  
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
  
  method get_cell (Int $row, Int $col) {
      $self->get_row($row)->get($col);
  }
  
  method set_cell (Int $row, Int $col, Defined $value) {
      $self->get_row($row)->set($col, $value);
  }
  
  method all_cells {
      map { $_->all } $self->all_rows
  }
  
  method get_col (Int $col) {
      map { $_->get($col) } $self->all_rows
  }

  method set_col (Int $col, (ArrayRef | ArrayObj) $values) {
      my @rows = $self->all_rows;
      for my $i (0 .. $#rows) {
          $rows[$i]->set($col) = $values->[$i];
      }
  }

  method add_col ( (ArrayRef | ArrayObj) $values ) {
      my @rows = $self->all_rows;
      for my $i (0 .. $#rows) {
          $rows[$i]->push($values->[$i]);
      }
  }

  method all_cols {
      my $col_count   = $self->get_row(0)->count;
      my $return_type = TypedArray[$CellType];
      
      map { $return_type->coerce($_); }
          map { [ $self->get_col($_) ]; } 0 .. $col_count-1;
  }
  
  method to_string {
      join "\n", 
        map(join("\t", map($_->name, $_->all)), $self->all_rows);
  }

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

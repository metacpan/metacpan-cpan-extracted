package Test::This;

use Data::Object 'Class';
use Data::Object::Space;

extends 'Test::Dist';

has data => (
  is => 'rw',
  isa => 'HashRef',
  bld => 'metadata',
  mod => 1
);

fun compile($name) {
  my $routines = [];

  my $class = "data/object/$name";
  my $space = Data::Object::Space->new($class);
  for my $item ($space->child('func')->children->list) {
    my $stub = $item->parts->last
      =~ s/([a-z])([A-Z])/${1}_${2}/gr
      =~ s/([A-Z])([A-Z])/${1}_${2}/gr;

    push @$routines, lc $stub;
  }

  return $routines;
}

fun metadata() {
  return {
    'Data/Object/Any' => {
      routines => compile('Any')
    },
    'Data/Object/Array' => {
      routines => compile('Array')
    },
    'Data/Object/Code' => {
      routines => compile('Code')
    },
    'Data/Object/Float' => {
      routines => compile('Float')
    },
    'Data/Object/Hash' => {
      routines => compile('Hash')
    },
    'Data/Object/Integer' => {
      routines => compile('Integer')
    },
    'Data/Object/Number' => {
      routines => compile('Number')
    },
    'Data/Object/Regexp' => {
      routines => compile('Regexp')
    },
    'Data/Object/Replace' => {
      routines => compile('Replace')
    },
    'Data/Object/Scalar' => {
      routines => compile('Scalar')
    },
    'Data/Object/Search' => {
      routines => compile('Search')
    },
    'Data/Object/String' => {
      routines => compile('String')
    },
    'Data/Object/Undef' => {
      routines => compile('Undef')
    }
  }
}

1;

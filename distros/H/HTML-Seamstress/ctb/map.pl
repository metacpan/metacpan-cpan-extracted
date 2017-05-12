use Data::Dumper;

$x = ['ul',
      map ['li', $_],
      qw(Peaches Apples Pears Mangos)
     ] ;


warn Dumper $x;

$y = ['ul',
      map ['li', $_],
      qw(Peaches Apples Pears Mangos)
     ] ;

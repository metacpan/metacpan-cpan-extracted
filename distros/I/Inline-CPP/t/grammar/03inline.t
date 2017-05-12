use strict;
use warnings;
use Test::More;

# Testing proper handling of functions defined inline within a class.

use Inline 'CPP';

my $obj = new_ok( 'Color' );


$obj->set_color(15);

is(
    $obj->get_color, 15,
    "Member function defined inline within class."
);

done_testing();

__END__
__CPP__
void prn() {
    printf("prn() called!\n");
}

class Color {
 public:
  Color()
  {
    printf("new Color object created...\n");
  }

  ~Color()
  {
    printf("Color object being destroyed...\n");
  }

  int get_color()
  {
    printf("Color::get_color called. Returning %i\n", color);
    return color;
  }

  void set_color(int a)
  {
    printf("Color::set_color(%i)\n", a);
    color = a;
  }

 private:
  int color;
};

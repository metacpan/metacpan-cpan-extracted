use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
  package OLP_X; # overloads pass through

  use MRO::Magic 
    passthru   => [ 'ISA' ],
    overload   => {
      '@{}'    => 'foo',
      fallback => 1,
    },
    metamethod => sub {
      my ($self, $method, $args) = @_;
      return [ $method, $args ];
    };

  {
    package OLP;
    use mro 'OLP_X';
  }
}

my $olp = bless {} => 'OLP';

{
  my $control = $olp->new(1,2,3);
  is_deeply(
    $control,
    [ new => [ 1, 2, 3 ] ],
    "our control call worked",
  );
}

{
  my $method = 'new';
  my $control = $olp->$method(1,2,3);
  is_deeply(
    $control,
    [ new => [ 1, 2, 3 ] ],
    "our control call worked (var method name)",
  );
}

# my $str = "$olp";
# is($str, '(""', "we stringified to the stringification method name");
# use Data::Dumper;
# warn Dumper([ @{ $olp } ]);

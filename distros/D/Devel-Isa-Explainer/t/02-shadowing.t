use strict;
use warnings;

use Test::More;
use Term::ANSIColor qw( colorstrip );

# ABSTRACT: Detect shadowing

use Devel::Isa::Explainer qw( explain_isa );

{

  package KENTNL::OnePercentClass;

  sub i_get_shadowed { }

  sub i_dont_get_shadowed { }

  sub three_layer_shadow {

    # hurp durp drumpf
  }
}

{

  package KENTNL::MiddleClass;

  our @ISA = qw( KENTNL::OnePercentClass );

  sub i_get_shadowed { }

  sub i_dont_shadow { }

  sub three_layer_shadow { }
}

{

  package KENTNL::LowerClass;

  our @ISA = qw( KENTNL::MiddleClass );

  sub three_layer_shadow {
    ## I am the 99%
  }
}

my $result = explain_isa('KENTNL::LowerClass');
note $result;

like( colorstrip($result), qr/KENTNL::LowerClass/,      "Base class represented" );
like( colorstrip($result), qr/KENTNL::MiddleClass/,     "Middle class represented" );
like( colorstrip($result), qr/KENTNL::OnePercentClass/, "Upper class represented" );

## Using internals because its easier than parsing.

my $mro = Devel::Isa::Explainer::_extract_mro('KENTNL::LowerClass');
note explain $mro;

is( $mro->[0]->{class}, 'KENTNL::LowerClass',      "base class is first displayed" );
is( $mro->[1]->{class}, 'KENTNL::MiddleClass',     "middle class is second displayed" );
is( $mro->[2]->{class}, 'KENTNL::OnePercentClass', "upper class is last displayed" );

is( scalar keys %{ $mro->[0]->{subs} }, 1, "base class has one subh" );
is( scalar keys %{ $mro->[1]->{subs} }, 3, "middle class has 3 subs" );
is( scalar keys %{ $mro->[2]->{subs} }, 3, "base class has 3 subs" );

is_deeply(
  $mro->[0]->{subs}->{three_layer_shadow},
  { shadowing => 1, shadowed => 0 },
  "three layer shadow top layer shadowing but not shadowed"
);
is_deeply(
  $mro->[1]->{subs}->{three_layer_shadow},
  { shadowing => 1, shadowed => 1 },
  "three layer shadow middle layer shadowing and shadowed"
);
is_deeply(
  $mro->[2]->{subs}->{three_layer_shadow},
  { shadowing => 0, shadowed => 1 },
  "three layer shadow bottom layer shadowed but not shadowing"
);

done_testing;


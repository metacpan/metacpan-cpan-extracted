#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

class Point {
   field $x :param;
   field $y :param = 0;

   method pos { return ( $x, $y ); }
}

{
   my $point = Point->new( x => 10 );
   is( [ $point->pos ], [ 10, 0 ],
      'Point with default y' );
}

# Object::Pad vs. core perl have slightly different quoting behaviours in
# exception messages.
my $QUOT = qr/["]?/;

# Required params checking
{
   my $LINE = __LINE__+1;
   ok( !defined eval { Point->new(); 1 },
      'constructor complains about missing required params' );
   like( $@, qr/^Required parameter 'x' is missing for ${QUOT}Point${QUOT} constructor at \S+ line $LINE\./,
      'exception message from missing parameter' );
}

# Strict params checking
{
   class Colour {
      field $red   :param = 0;
      field $green :param = 0;
      field $blue  :param = 0;
   }

   my $LINE = __LINE__+1;
   ok( !defined eval { Colour->new( yellow => 1 ); 1 },
      'constructor complains about unrecognised param name' );
   like( $@, qr/^Unrecogni[sz]ed parameters for ${QUOT}Colour${QUOT} constructor: '?yellow'? at \S+ line $LINE\./,
      'exception message from unrecognised parameter' );
}

# Param assignment modes
{
   class AllTheOps {
      field $exists  :param   = "default";
      field $defined :param //= "default";
      field $true    :param ||= "default";

      method values { return ( $exists, $defined, $true ); }
   }

   is( [ AllTheOps->new(exists => "value", defined => "value", true => "value")->values ],
      [ "value", "value", "value" ],
      'AllTheOps for true values' );

   is( [ AllTheOps->new(exists => 0, defined => 0, true => 0)->values ],
      [ 0, 0, "default" ],
      'AllTheOps for false values' );

   is( [ AllTheOps->new(exists => undef, defined => undef, true => undef)->values ],
      [ undef, "default", "default" ],
      'AllTheOps for undef values' );

   is( [ AllTheOps->new()->values ],
      [ "default", "default", "default" ],
      'AllTheOps for missing values' );
}

# field initialiser expressions permit a __CLASS__
{
   class ClassInInitialiser {
      field $classname :reader = __CLASS__;
   }

   is( ClassInInitialiser->new->classname, "ClassInInitialiser",
      '__CLASS__ in field initialisers' );

   class SubclassNamedHere :isa( ClassInInitialiser ) {
   }

   is( SubclassNamedHere->new->classname, "SubclassNamedHere",
      '__CLASS__ sees subclass name correctly' );
}

done_testing;

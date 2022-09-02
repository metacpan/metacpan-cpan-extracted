#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Future::AsyncAwait;

my $HEIGHT = 1.234;

{
   use Object::Pad 0.57;

   class TestChip
      :isa(Device::Chip);

   use Device::Chip::Sensor -declare;

   declare_sensor height =>
      units     => "metres",
      precision => 2,
      sanity_bounds => [ 0, 3 ];

   async method read_height () { return $HEIGHT; }

   declare_sensor width =>
      method    => "measure_width",
      units     => "metres",
      precision => 3;

   async method measure_width () { return 4.56; };

   declare_sensor size =>
      units     => "metres",
      precision => 2;

   async method read_size () { return 30, 50; };

   declare_sensor_counter hits =>;
}

my $chip = TestChip->new;

my @sensors = $chip->list_sensors;
is( scalar @sensors, 4, '$chip->list_sensors yields 3 sensors' );

{
   my $sensor = $sensors[0];
   is( $sensor->type,      "gauge",  '$sensor->type' );
   is( $sensor->name,      "height", '$sensor->height' );
   is( $sensor->units,     "metres", '$sensor->units' );
   is( $sensor->precision, 2,        '$sensor->precision' );

   is( $sensor->chip, $chip, '$sensor->chip' );

   is( await $sensor->read, 1.234, '$sensor->read yields reading' );

   is( $sensor->format( await $sensor->read ), "1.23", '$sensor->format returns string' );

   is( $sensor->format( undef ), undef, '$sensor->format undef yields undef' );
}

{
   my $sensor = $sensors[1];

   is( await $sensor->read, 4.56, 'sensor with method declaration calls alternate method' );
}

{
   my $sensor = $sensors[2];

   is_deeply( [ await $sensor->read ], [ 30 ], 'sensor is read as a single scalar' );
}

{
   my $sensor = $sensors[3];

   is( $sensor->type, "counter", '$sensor->type counter' );
}

# insane value
{
   my $sensor = $sensors[0];

   $HEIGHT = -1;
   like( exception { $sensor->read->get }, qr/^Reading -1.00 is out of range/,
      '$sensor->read fails when below lbounds' );

   $HEIGHT = 17;
   like( exception { $sensor->read->get }, qr/^Reading 17.00 is out of range/,
      '$sensor->read fails when above ubounds' );
}

done_testing;

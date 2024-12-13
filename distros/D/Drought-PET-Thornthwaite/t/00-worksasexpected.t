use strict;
use warnings;
use 5.010;
use Test::More;
use Drought::PET::Thornthwaite qw(pet_thornthwaite tei_thornthwaite);

my $pet;
ok( ! defined(eval { $pet = pet_thornthwaite("NaN",7,20.5,12,12) } ),  'Test pet_thornthwaite with a NaN YDAY (default missing)' );
ok( ! defined(eval { $pet = pet_thornthwaite(12,"NaN",37.8,12,12) } ), 'Test pet_thornthwaite with a NaN NDAYS (default missing)' );
ok( ! defined(eval { $pet = pet_thornthwaite(15,7,"NaN",12,12) } ),    'Test pet_thornthwaite with a NaN LAT (default missing)' );
ok( ! defined(eval { $pet = pet_thornthwaite(0,7,20.5,12,12) } ),      'Test pet_thornthwaite with an invalid YDAY (default missing)' );
ok( ! defined(eval { $pet = pet_thornthwaite(12,0,37.8,12,12) } ),     'Test pet_thornthwaite with an invalid NDAYS (default missing)' );
ok( ! defined(eval { $pet = pet_thornthwaite(15,7,100,12,12) } ),      'Test pet_thornthwaite with an invalid LAT (default missing)' );
ok( ! defined(pet_thornthwaite(12,10,30.8,"NaN",0) <=> 0),             'Test pet_thornthwaite with a missing TEMP arg (default)' );
is( pet_thornthwaite(225,30,75.0,12,-9999,-9999), -9999,               'Test pet_thornthwaite with a missing TEI arg (non-default)' );
is( pet_thornthwaite(300,7,20.5,-5,5), 0,                              'Test pet_thornthwaite with a below-zero temperature' );
is( int(pet_thornthwaite(220,30,20.5,16,52.57)), 74,                   'Test pet_thornthwaite with a positive temperature (regular)' );
is( pet_thornthwaite(220,30,20.5,27,52.57), 141.43,                    'Test pet_thornthwaite with a positive temperature (hot)' );

ok( ! defined(tei_thornthwaite("NaN",2,3,4,5,6,7,8,9,10,11,12) <=> 0), 'Test tei_thornthwaite with a NaN value (default)' );
ok( ! defined(tei_thornthwaite(1,2,3,"NaN",5,6,7,8,9,10,11,12) <=> 0), 'Test tei_thornthwaite with a NaN value (default)' );
is( tei_thornthwaite(1,2,3,-9999,5,6,7,8,9,10,11,12,-9999), -9999,     'Test tei_thornthwaite with a missing value (non-default)' );
is( tei_thornthwaite(1,2,3,"NaN",5,6,7,8,9,10,11,12,-9999), -9999,     'Test tei_thornthwaite with a NaN value (non-default)' );
is( tei_thornthwaite(1,2,"sldkjf",4,5,6,7,8,9,10,11,12,-9999), -9999,  'Test tei_thornthwaite with an invalid value (non-default)' );

done_testing();

exit 0;


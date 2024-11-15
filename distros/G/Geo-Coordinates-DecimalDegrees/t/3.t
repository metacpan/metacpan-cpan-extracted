use strict;
use Test::More tests => 57;
use Geo::Coordinates::DecimalDegrees;

# Check that all the tests in 2.t give the same results with the
# aliased versions

ok( dms2decimal( 0,  0,  0) == dms2dec( 0,  0,  0));
ok( dms2decimal( 1,  0,  0) == dms2dec( 1,  0,  0));
ok( dms2decimal(-1,  0,  0) == dms2dec(-1,  0,  0));
ok( dms2decimal( 1, 15,  0) == dms2dec( 1, 15,  0));
ok( dms2decimal( 1, 30,  0) == dms2dec( 1, 30,  0));
ok( dms2decimal( 1, 45,  0) == dms2dec( 1, 45,  0));
ok( dms2decimal(-1, 15,  0) == dms2dec(-1, 15,  0));
ok( dms2decimal(-1, 30,  0) == dms2dec(-1, 30,  0));
ok( dms2decimal(-1, 45,  0) == dms2dec(-1, 45,  0));
ok( dms2decimal( 0,  0, 15) == dms2dec( 0,  0, 15));
ok( dms2decimal( 0,  0, 30) == dms2dec( 0,  0, 30));
ok( dms2decimal( 0,  0, 45) == dms2dec( 0,  0, 45));
ok( dms2decimal( 0, 15, 15) == dms2dec( 0, 15, 15));
ok( dms2decimal( 0, 30, 30) == dms2dec( 0, 30, 30));
ok( dms2decimal( 0, 45, 45) == dms2dec( 0, 45, 45));
ok( dms2decimal( 1, 15, 15) == dms2dec( 1, 15, 15));
ok( dms2decimal( 1, 30, 30) == dms2dec( 1, 30, 30));
ok( dms2decimal( 1, 45, 45) == dms2dec( 1, 45, 45));

ok( dm2decimal( 0,  0) == dm2dec( 0,  0));
ok( dm2decimal( 1,  0) == dm2dec( 1,  0));
ok( dm2decimal(-1,  0) == dm2dec(-1,  0));
ok( dm2decimal( 1, 15) == dm2dec( 1, 15));
ok( dm2decimal( 1, 30) == dm2dec( 1, 30));
ok( dm2decimal( 1, 45) == dm2dec( 1, 45));

is_deeply( [decimal2dms(  0 )],              [dec2dms(  0 )]);
is_deeply( [decimal2dms(  1 )],              [dec2dms(  1 )]);
is_deeply( [decimal2dms( -1 )],              [dec2dms( -1 )]);
is_deeply( [decimal2dms( -0.25 )],           [dec2dms( -0.25 )]);
is_deeply( [decimal2dms( -0.5 )],            [dec2dms( -0.5 )]);
is_deeply( [decimal2dms( -0.75 )],           [dec2dms( -0.75 )]);
is_deeply( [decimal2dms(  1.25 )],           [dec2dms(  1.25 )]);
is_deeply( [decimal2dms(  1.5 )],            [dec2dms(  1.5 )]);
is_deeply( [decimal2dms(  1.75 )],           [dec2dms(  1.75 )]);
is_deeply( [decimal2dms( -1.25 )],           [dec2dms( -1.25 )]);
is_deeply( [decimal2dms( -1.5 )],            [dec2dms( -1.5 )]);
is_deeply( [decimal2dms( -1.75 )],           [dec2dms( -1.75 )]);
is_deeply( [decimal2dms(  0.00 + 15/3600 )], [dec2dms(  0.00 + 15/3600 )]);
is_deeply( [decimal2dms(  0.00 + 30/3600 )], [dec2dms(  0.00 + 30/3600 )]);
is_deeply( [decimal2dms(  0.0125 )],         [dec2dms(  0.0125 )]);
is_deeply( [decimal2dms(  0.25 + 15/3600 )], [dec2dms(  0.25 + 15/3600 )]);
is_deeply( [decimal2dms(  0.50 + 30/3600 )], [dec2dms(  0.50 + 30/3600 )]);
is_deeply( [decimal2dms(  0.7625 )],         [dec2dms(  0.7625 )]);
is_deeply( [decimal2dms(  1.25 + 15/3600 )], [dec2dms(  1.25 + 15/3600 )]);
is_deeply( [decimal2dms(  1.50 + 30/3600 )], [dec2dms(  1.50 + 30/3600 )]);
is_deeply( [decimal2dms(  1.7625, )],        [dec2dms(  1.7625, )]);

is_deeply( [decimal2dm(  0 )],    [dec2dm(  0 )]);
is_deeply( [decimal2dm(  1 )],    [dec2dm(  1 )]);
is_deeply( [decimal2dm( -1 )],    [dec2dm( -1 )]);
is_deeply( [decimal2dm( -0.25 )], [dec2dm( -0.25 )]);
is_deeply( [decimal2dm( -0.5 )],  [dec2dm( -0.5 )]);
is_deeply( [decimal2dm( -0.75 )], [dec2dm( -0.75 )]);
is_deeply( [decimal2dm(  1.25 )], [dec2dm(  1.25 )]);
is_deeply( [decimal2dm(  1.5 )],  [dec2dm(  1.5 )]);
is_deeply( [decimal2dm(  1.75 )], [dec2dm(  1.75 )]);
is_deeply( [decimal2dm( -1.25 )], [dec2dm( -1.25 )]);
is_deeply( [decimal2dm( -1.5 )],  [dec2dm( -1.5 )]);
is_deeply( [decimal2dm( -1.75 )], [dec2dm( -1.75 )]);

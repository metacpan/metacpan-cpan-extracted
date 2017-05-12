# $Id$

use strict;
use Test::Number::Delta tests => 57;
use Geo::Coordinates::DecimalDegrees;

delta_ok( dms2decimal( 0,  0,  0),   0);
delta_ok( dms2decimal( 1,  0,  0),   1);
delta_ok( dms2decimal(-1,  0,  0), -1);
delta_ok( dms2decimal( 1, 15,  0),  1.25);
delta_ok( dms2decimal( 1, 30,  0),  1.5);
delta_ok( dms2decimal( 1, 45,  0),  1.75);
delta_ok( dms2decimal(-1, 15,  0), -1.25);
delta_ok( dms2decimal(-1, 30,  0), -1.5);
delta_ok( dms2decimal(-1, 45,  0), -1.75);
delta_ok( dms2decimal( 0,  0, 15),  0.004167);
delta_ok( dms2decimal( 0,  0, 30),  0.008333);
delta_ok( dms2decimal( 0,  0, 45),  0.0125);
delta_ok( dms2decimal( 0, 15, 15),  0.254167);
delta_ok( dms2decimal( 0, 30, 30),  0.508333);
delta_ok( dms2decimal( 0, 45, 45),  0.7625);
delta_ok( dms2decimal( 1, 15, 15),  1.254167);
delta_ok( dms2decimal( 1, 30, 30),  1.508333);
delta_ok( dms2decimal( 1, 45, 45),  1.7625);

delta_ok( dm2decimal( 0,  0),  0);
delta_ok( dm2decimal( 1,  0),  1);
delta_ok( dm2decimal(-1,  0), -1);
delta_ok( dm2decimal( 1, 15),  1.25);
delta_ok( dm2decimal( 1, 30),  1.5);
delta_ok( dm2decimal( 1, 45),  1.75);

delta_ok( [decimal2dms(  0 )],              [ 0,  0,  0,  0]);
delta_ok( [decimal2dms(  1 )],              [ 1,  0,  0,  1]);
delta_ok( [decimal2dms( -1 )],              [-1,  0,  0, -1]);
delta_ok( [decimal2dms( -0.25 )],           [ 0, 15,  0, -1]);
delta_ok( [decimal2dms( -0.5 )],            [ 0, 30,  0, -1]);
delta_ok( [decimal2dms( -0.75 )],           [ 0, 45,  0, -1]);
delta_ok( [decimal2dms(  1.25 )],           [ 1, 15,  0,  1]);
delta_ok( [decimal2dms(  1.5 )],            [ 1, 30,  0,  1]);
delta_ok( [decimal2dms(  1.75 )],           [ 1, 45,  0,  1]);
delta_ok( [decimal2dms( -1.25 )],           [-1, 15,  0, -1]);
delta_ok( [decimal2dms( -1.5 )],            [-1, 30,  0, -1]);
delta_ok( [decimal2dms( -1.75 )],           [-1, 45,  0, -1]);
delta_ok( [decimal2dms(  0.00 + 15/3600 )], [ 0,  0, 15,  1]);
delta_ok( [decimal2dms(  0.00 + 30/3600 )], [ 0,  0, 30,  1]);
delta_ok( [decimal2dms(  0.0125 )],         [ 0,  0, 45,  1]);
delta_ok( [decimal2dms(  0.25 + 15/3600 )], [ 0, 15, 15,  1]);
delta_ok( [decimal2dms(  0.50 + 30/3600 )], [ 0, 30, 30,  1]);
delta_ok( [decimal2dms(  0.7625 )],         [ 0, 45, 45,  1]);
delta_ok( [decimal2dms(  1.25 + 15/3600 )], [ 1, 15, 15,  1]);
delta_ok( [decimal2dms(  1.50 + 30/3600 )], [ 1, 30, 30,  1]);
delta_ok( [decimal2dms(  1.7625, )],        [ 1, 45, 45,  1]);

delta_ok( [decimal2dm(  0 )],    [ 0,  0,  0]);
delta_ok( [decimal2dm(  1 )],    [ 1,  0,  1]);
delta_ok( [decimal2dm( -1 )],    [-1,  0, -1]);
delta_ok( [decimal2dm( -0.25 )], [ 0, 15, -1]);
delta_ok( [decimal2dm( -0.5 )],  [ 0, 30, -1]);
delta_ok( [decimal2dm( -0.75 )], [ 0, 45, -1]);
delta_ok( [decimal2dm(  1.25 )], [ 1, 15,  1]);
delta_ok( [decimal2dm(  1.5 )],  [ 1, 30,  1]);
delta_ok( [decimal2dm(  1.75 )], [ 1, 45,  1]);
delta_ok( [decimal2dm( -1.25 )], [-1, 15, -1]);
delta_ok( [decimal2dm( -1.5 )],  [-1, 30, -1]);
delta_ok( [decimal2dm( -1.75 )], [-1, 45, -1]);

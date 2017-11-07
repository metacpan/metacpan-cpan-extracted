# Toby Thurston -- 30 Oct 2017 

# test a known location converts correctly

use Geo::Coordinates::OSGB qw/ll_to_grid grid_to_ll set_default_shape/;
use Geo::Coordinates::OSGB::Grid qw/parse_grid format_grid format_grid_GPS/;

use Test::More tests => 29;

# First a round trip using WGS84
# from the sw corner of OS Explorer sheet 161 (Cobham, Surrey)
is(sprintf("%d %d", ll_to_grid(51+20/60, -25/60)), "510399 160549", "SW corner of B:161, near Chobham");
is(sprintf("%g %g", grid_to_ll(510399.049,160549.817)), sprintf("%g %g", 51+20/60, -25/60), 'Chobham, back again');

# Now some look ups using OSGB36 through out, because the LL printed on OS maps is not based on WGS84
# This routine not documented in the main module, but it's use is hopefully obvious.
set_default_shape('OSGB36');

is(format_grid_GPS(ll_to_grid(57+55/60, -305/60)),         'NH 17379 96054',         'Hills above Loch Achall, Sheet A:20'); 
is(format_grid_GPS(ll_to_grid(51.5,0)),                    'TQ 38805 79845',         'Greenwich');                           
is(format_grid_GPS(ll_to_grid(0,51.5)),                    'TQ 38805 79845',         'Reversed arguments');                  
is(ll_to_grid(51.5,0),                                     '538805.837 179845.817',  'scalar context');                      
is(format_grid_GPS(ll_to_grid({ lon => 0, lat => 51.5})),  'TQ 38805 79845',         'keyword arguments');                   
is(format_grid_GPS(ll_to_grid(59,-3)),                     'HY 42554 12927',         'Kirkwall');                            
is(format_grid_GPS(ll_to_grid(51+40/60,1)),                'TM 07436 00745',         'Foulness Sands');                      
is(format_grid_GPS(ll_to_grid(51,1)),                      'TR 10468 26633',         'St Mary\'s Bay');                      

is(ll_to_grid(49,       -2    ), "400000.000 -100000.000", 'True origin');
is(ll_to_grid(52,       -2    ), "400000.000 233553.731",  'On central meridian');
is(ll_to_grid(56+55/60, -5.25 ), "202190.386 785279.519",  "Meall a Phubuill");

# and now a boggy path just north of Glendessary in Lochaber
# OS Sheet 40 topright corner.  A graticule intersection at
# 57N 5o20W is marked.  GR measured from the map.
is(sprintf("%g %g",          grid_to_ll(197575, 794790)),              "57 -5.3333",              "Glendessary");
is(sprintf("%g %g",          grid_to_ll(269995, 68361)),               "50.5 -3.83333",           "Scorriton");
is(sprintf("%g %g",          grid_to_ll(400000, 122350)),              "51 -2",                   "Cranbourne Chase");
is(sprintf("%11.8f %10.7f",  grid_to_ll(323223, 1004000)),             "58.91680150 -3.3333320",  "Hoy");
is(sprintf("%11.8f %10.7f",  grid_to_ll(217380, 896060)),              "57.91671633 -5.0833302",  "Glen Achcall");
is(sprintf("%g %g",          grid_to_ll({e => 217380, n => 896060})),  "57.9167 -5.08333",        "Keyword arguments for Glen Achcall");

# switch back to WGS84
set_default_shape('WGS84');

is(ll_to_grid(51.3, 0),     "539524.836 157551.913",  "Somewhere in London");
is(ll_to_grid(51.3, -10),   "-157250 186110",         "Far west");
is(ll_to_grid(61.3, 0),     "507242 1270342",         "Far north");
is(ll_to_grid(56.75, -7),   "94469.613 773209.471",   "In sea north-west of Coll");
is(ll_to_grid(51.5, -2.1),  "393154.813 177900.607",  'Example from docs');

# Finally some more round trips 
sub test_me {
    return format_grid(ll_to_grid(grid_to_ll(parse_grid($_[0]))), {form => 'GPS'});
}

is(test_me('NM9750194802'), 'NM 97501 94802' ,"NM975948");
is(test_me('NH0730306004'), 'NH 07303 06004' ,"NH073060");
is(test_me('SX7000568206'), 'SX 70005 68206' ,"SX700682");
is(test_me('TQ1030760608'), 'TQ 10307 60608' ,"TQ103606");
is(test_me('HY5540930010'), 'HY 55409 30010' ,"HY554300");

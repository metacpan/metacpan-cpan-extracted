# Toby Thurston -- 14 Jan 2016 

# test grid ref parsing 

use Test::More tests=>58;

use Geo::Coordinates::OSGB::Grid qw(
    parse_grid
);

is( sprintf("%d %d", parse_grid('TA')),              '500000 400000',   '100km square');                    
is( sprintf("%d %d", parse_grid('TA15')),            '510000 450000',   '10km square');                    
is( sprintf("%d %d", parse_grid('TA1256')),          '512000 456000',   '1km square');                     
is( sprintf("%d %d", parse_grid('TA123567')),        '512300 456700',   '100m square');                    
is( sprintf("%d %d", parse_grid('TA12345678')),      '512340 456780',   '10m square');                     
is( sprintf("%d %d", parse_grid('TA1234567890')),    '512345 467890',   '1m square');                      
is( sprintf("%d %d", parse_grid('TA 1 5')),          '510000 450000',   '10km square');                    
is( sprintf("%d %d", parse_grid('TA 12 56')),        '512000 456000',   '1km square');                     
is( sprintf("%d %d", parse_grid('TA 123 567')),      '512300 456700',   '100m square');                    
is( sprintf("%d %d", parse_grid('TA 1234 5678')),    '512340 456780',   '10m square');                     
is( sprintf("%d %d", parse_grid('TA 12345 67890')),  '512345 467890',   '1m square');                      
is( sprintf("%d %d", parse_grid('TA', '123 567')),   '512300 456700',   '2 arg 100m square');              
is( sprintf("%d %d", parse_grid('TA', '123567')),    '512300 456700',   '2 arg 100m square');              
is( sprintf("%d %d", parse_grid('TA', 123,567)),     '512300 456700',   '3 arg 100m square');              
is( sprintf("%d %d", parse_grid('TA', 123,7, {figs=>5})),     '500123 400007',   '3 arg 100m square');              
is( sprintf("%d %d", parse_grid('TA', '123', '007')),     '512300 400700',   '3 arg 100m square');              
is( sprintf("%d %d", parse_grid('SV9055710820')),    '90557 10820',     'St Marys lifeboat station');      
is( sprintf("%d %d", parse_grid('HU','4795841283')),    '447958 1141283',  'Lerwick lifeboat station');       
is( sprintf("%d %d", parse_grid('WE950950')),        '-5000 -5000',     'At sea, off the Scillies');       
is( sprintf("%d %d", parse_grid('176/224711')),      '522400 171100',   "Caesar's Camp");                  
is( sprintf("%d %d", parse_grid('A:164/352194')),    '435200 219400',   "Charlbury Station");              
is( sprintf("%d %d", parse_grid('B:OL43E/914701')),  '391400 570100',   "Chesters Bridge");                
is( sprintf("%d %d", parse_grid(164,513,62)),        '451300 206200',   'Carfax');                         

is( parse_grid('TA'),                '500000 400000',   'scalar context: 100km square');                    
is( parse_grid('TA',0,0),            '500000 400000',   'scalar context: 100km square');                    
is( parse_grid('TA15'),              '510000 450000',   'scalar context: 10km square');                    
is( parse_grid('TA1256'),            '512000 456000',   'scalar context: 1km square');                     
is( parse_grid('TA123567'),          '512300 456700',   'scalar context: 100m square');                    
is( parse_grid('TA12345678'),        '512340 456780',   'scalar context: 10m square');                     
is( parse_grid('TA1234567890'),      '512345 467890',   'scalar context: 1m square');                      
is( parse_grid('TA 1 5'),            '510000 450000',   'scalar context: 10km square');                    
is( parse_grid('TA 12 56'),          '512000 456000',   'scalar context: 1km square');                     
is( parse_grid('TA 123 567'),        '512300 456700',   'scalar context: 100m square');                    
is( parse_grid('TA 1234 5678'),      '512340 456780',   'scalar context: 10m square');                     
is( parse_grid('TA 12345 67890'),    '512345 467890',   'scalar context: 1m square');                      
is( parse_grid('TA', '123 567'),     '512300 456700',   'scalar context: 2 arg 100m square');              
is( parse_grid('TA', '123567'),      '512300 456700',   'scalar context: 2 arg 100m square');              
is( parse_grid('TA', 123,567),       '512300 456700',   'scalar context: 3 arg 100m square');              
is( parse_grid('SV9055710820'),      '90557 10820',     'scalar context: St Marys lifeboat station');      
is( parse_grid('HU4795841283'),      '447958 1141283',  'scalar context: Lerwick lifeboat station');       
is( parse_grid('WE950950'),          '-5000 -5000',     'scalar context: At sea, off the Scillies');       
is( parse_grid('176/224711'),        '522400 171100',   "scalar context: Caesar's Camp");                  
is( parse_grid('A:164/352194'),      '435200 219400',   "scalar context: Charlbury Station");              
is( parse_grid('B:OL43E/914701'),    '391400 570100',   "scalar context: map Chesters Bridge");            
is( parse_grid('B:OL43E 914 701'),   '391400 570100',   "scalar context: map Chesters Bridge");            
is( parse_grid('B:OL43E','914701'),  '391400 570100',   "scalar context: map 2-arg Chesters Bridge");      
is( parse_grid('B:OL43E',914,701),   '391400 570100',   "scalar context: map 3-arg Chesters Bridge");      
is( parse_grid(164,513,62),          '451300 206200',   'scalar context: Carfax');                         

is( parse_grid('B:119/OL3/480103'),      '448000 110300',   "scalar context: map with dual name");      
is( parse_grid('B:309S.a 26432 34013'),   '226432 534013',   "scalar context: inset on B:309");      
is( parse_grid('B:368/OL47W', 723, 112),   '272300 711200',   "scalar context: 3-arg, dual name");

ok( (($e,$n) = parse_grid('TQ 234 098')) && $e == 523_400 && $n == 109_800 , "Help example 1 $e $n");
ok( (($e,$n) = parse_grid('TQ234098')  ) && $e == 523_400 && $n == 109_800 , "Help example 2 $e $n");
ok( (($e,$n) = parse_grid('TQ',234,98) ) && $e == 523_400 && $n == 109_800 , "Help example 3 $e $n");
##
ok( (($e,$n) = parse_grid('TQ 23451 09893')) && $e == 523_451 && $n == 109_893 , "Help example 4 $e $n");
ok( (($e,$n) = parse_grid('TQ2345109893')  ) && $e == 523_451 && $n == 109_893 , "Help example 5 $e $n");
ok( (($e,$n) = parse_grid('TQ',23451,9893, {figs => 5}) ) && $e == 523_451 && $n == 109_893 , "Help example 6 $e $n");
##
# You can also get grid refs from individual maps.
# Sheet between 1..204; gre & grn must be 3 or 5 digits long

ok( (($e,$n) = parse_grid(176,123,994)     ) && $e == 512_300 && $n == 199_400 , "Help example 7 $e $n");


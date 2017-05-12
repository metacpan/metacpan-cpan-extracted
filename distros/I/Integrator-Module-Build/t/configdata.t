#!perl 

use Test::More tests => 10;
use Integrator::Test::ConfigData;

measure  ('reading voltage', 'LINE1', 110, 'volts', 0.01, 'SCOPE_001234');
measure  ('flight plan', 'altitude',  330234, 'feet', 10, 'altimeter_1234562342342342343');

component('initial latch state',    'BLADE_CPU', '1234',    'LATCH_POSITION', 'CLOSED');
component('initial latch state',    'BLADE_CPU', '4321',    'LATCH_POSITION', 'CLOSED');
component('power sup. config' ,     'P_SUP',     'LEFT',    'MAX_VOLTAGE',    '48');
component('alternate p.sup config', 'P_SUP',     'UNKNOWN', 'MAX_VOLTAGE',    '72');

#not very good practice, but still somewhat valid and usable
measure  ('', 'altitude',  330234, 'feet', 10, 'altimeter_1234562342342342343');
measure  ('', 'altitude',  330234, 'feet');
component('', '', '',    'LATCH_POSITION', 'CLOSED');

config_data('serial number file', './t/toto.txt');

#!/usr/bin/perl

use Test::More tests => 13;


ok (1==1, "This is a good test, integrator_measurement:FAN_TACH1;2330;RPM;0.1;OSCILLOSCOPE_01234");
ok (1==1, "This is a good test, integrator_measurement:FAN_TACH2;2434;RPM;0.1;OSCILLOSCOPE_01234");
ok (1==1, "This is a good test, integrator_measurement:FAN_TACH3;2334;RPM;0.1;OSCILLOSCOPE_01234");
ok (1==1, "This is a good test, integrator_measurement:FAN_TACH4;2334;RPM;0.1;OSCILLOSCOPE_01234");
ok (1==1, "This is a good test, integrator_measurement:FAN_TACH5;2433;RPM;0.1;OSCILLOSCOPE_01234");
ok (1==1, "This is a good test, integrator_measurement:FAN_TACH6;2340;RPM;0.1;OSCILLOSCOPE_01234");
ok (1==1, "This is a good test, integrator_measurement:FAN_TACH7;2430;RPM;0.1;OSCILLOSCOPE_01234");
ok (1==1, "This is a good test, integrator_measurement:FAN_TACH8;2333;RPM;0.1;OSCILLOSCOPE_01234");


ok (1==1, "Just a label  integrator_measurement:LABEL_ok");
ok (1==1, "Just a measurement integrator_measurement:;225");
ok (1==1, "Just a unit   integrator_measurement:;;volt");
ok (1==1, "Just a tol    integrator_measurement:;;;0.23");
ok (1==1, "Just an equip integrator_measurement:;;;;MultiMeter-Fluke_123ax43_002");

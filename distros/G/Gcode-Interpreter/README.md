Gcode-Interpreter
=================

This is a Perl module that can interpret Gcode, as used by 3D printers,
CNC mills and machines etc. It aims to be able to simulate the machine
and be able to report on the state of the machine during the simulated
execution.

At present, the only machine implemented is the series of Ultimaker 3D
printers. For those machines, we can similate the printer, report its
head and extruder position and determine the time taken to run the
print.

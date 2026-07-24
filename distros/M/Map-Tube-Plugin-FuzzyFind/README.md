A Map::Tube plugin to find lines and stations by partially specified or mistyped names.

This is an add-on for Map::Tube to find stations and lines by name, possibly
partly or inexactly specified. The module is a Moo role which gets plugged into the
Map::Tube::* family automatically once it is installed.

To build this module, use the classical steps:

* perl Makefile.PL
* make
* make test
* make install

(If you are using Strawberry Perl under Windows, you may want to replace "make"
with "gmake".)

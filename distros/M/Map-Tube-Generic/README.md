A generic Map::Tube implementation taking the name of a specific network at runtime.

This module allows to find the shortest route between any two given
stations in some metro network. The name of the network is specified at runtime.
Most interesting methods are provided by the role Map::Tube.

To build this module, use the classical steps:

* perl Makefile.PL
* make
* make test
* make install

(If you are using Strawberry Perl under Windows, you may want to replace "make"
with "gmake".)

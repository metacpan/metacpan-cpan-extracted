---
title: 'Lab::Measurement - measurement control with Perl'
tags:
  - measurement
  - instrument control
  - Perl
  - VISA
  - GPIB
  - IEEE488
  - SCPI
authors:
 - name: Simon Reinhardt
   affiliation: 1
 - name: Christian Butschkow
   orcid: 0000-0002-2298-3736
   affiliation: 1
 - name: Stefan Geissler
   affiliation: 1
 - name: Florian Olbrich
   orcid: 0000-0001-8597-9534
   affiliation: 1
 - name: Charles Lane
   orcid: 0000-0003-4329-5796
   affiliation: 2
 - name: Daniel Schröer
   affiliation: 3
 - name: Andreas K. Hüttel
   orcid: 0000-0001-5794-5919
   affiliation: 1
affiliations:
 - name: Institute for Experimental and Applied Physics, University of Regensburg, 93040 Regensburg, Germany
   index: 1
 - name: Department of Physics, Drexel University, 3141 Chestnut Street, Philadelphia, PA 19104, USA
   index: 2
 - name: Center for NanoScience and Department für Physik, Ludwig-Maximilians-Universität, Geschwister-Scholl-Platz 1, 80539 München, Germany
   index: 3
date: 1 May 2017
bibliography: paper.bib
---

# Summary

`Lab::Measurement` is a distribution of Perl modules for controlling electronic 
test and measurement setups, supporting both Linux and Microsoft Windows. 
Control (e.g., voltage source, rf generator, step motor, magnet power supply...) 
and readout (e.g., multimeter, spectrum analyzer, thermometry, ...) devices can 
be connected by as various means as GPIB [@gpib], USB, serial cable, or 
ethernet. 

Internally a layer structure of Perl modules is implemented. Communication 
hardware driver backends such as Linux-GPIB [@linuxgpib] or National 
Instruments' NI-VISA library [@visa] as well as direct operating system calls 
are typically accessed on a "bus layer". On top of this, a hardware-neutral 
"connection layer" mediates to the "instrument layer". Instruments typically 
receive and process command strings as e.g. defined by the SCPI [@scpi] 
standard.

Instrument-specific driver classes encapsulate the command syntax, providing 
common interfaces for setting device parameters. An additional high-level 
layer, `Lab::XPRESS`, allows easy creation of nested measurement loops. Several 
input variables can be varied, and arbitrary data collection code can be 
executed at each grid point. Live plotting capability is provided; metadata 
and device parameters are automatically protocolled.

See [@dirnaichnerprl2016], [@nphysgranger2012], [@gaassprl2011] as examples for 
publications based on `Lab::Measurement`. `Lab::Measurement` is free software 
published under the same license as Perl 5 itself; its releases are uploaded on 
CPAN. More information can be found on the project homepage, 
https://www.labmeasurement.de/

# Acknowledgements

The authors gratefully acknowlegde funding by the DFG via the Emmy Noether grant
Hu1808/1-1, the collaborative research centre SFB 689, and the graduate research 
school GRK 1570.

# References

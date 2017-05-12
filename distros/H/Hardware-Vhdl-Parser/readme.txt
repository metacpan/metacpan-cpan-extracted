##################################################################
# Copyright (C) 2000 Greg London   All Rights Reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
##################################################################

Hardware::Vhdl::Parse.pm is currently in "beta" status

The Hardware::Vhdl::Parse.pm file contains a VHDL grammar.
This grammar is used by Parse::RecDescent to parse any
VHDL design file. You will need the latest version of 
Parse::RecDescent to use this grammar.

parser.pl is a script which uses this module to do the actual parsing.  
A test VHDL file is included called test1.vhd

to parse this file, type:

parser.pl test1.vhd

The parser.pl script doesn't do anything except parse the file.
There is another module called hierarchy.pm which spits out
the name of all instantiated components. There is a script,
called hierarchy.pl, that uses this module. To run this script,
type:

hierarchy.pl test1.vhd

this should print out:
INSTANCENAME DUT 



PLEASE NOTE: the script takes some time to simply load the grammar.
the it takes about a minute (yes, 60 seconds) to run the 
hierarchy.pl test1.vhd command shown above when run on an Ultra 60.
your performance may vary.

parsing speed will probably be somewhere along the lines of
10 to 20 lines per minute. (I haven't done any full-fledged
benchmarking on this module)

status of grammar: Beta

once the grammar is in a released state, 
then I'll concentrate on tools that use the grammar. 

possible tool applications include: 
1) automatic build scripts, 
2) automatic synthesis scripts, 
3) hierarchical browswers,
4) lint type checking with a hardware slant,
   "hey buddy, you've got combinatorial logic driving a module output port"
   "you've got combinatorial paths that cross multiple hierarchy boundaries."
   "did you ever hear of clocking all your output ports"
5) a script that can go through a netlist,
	find all the signals,
	perform regular-expression renaming on the signals,
	and save the results as a new netlist.


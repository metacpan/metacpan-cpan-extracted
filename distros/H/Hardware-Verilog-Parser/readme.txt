##################################################################
# Copyright (C) 2000 Greg London   All Rights Reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
##################################################################

Hardware::Verilog::Parse.pm is currently in "beta" status

The Hardware::Verilog::Parser.pm file contains a Verilog grammar.
This grammar is used by Parse::RecDescent to parse any
Verilog design file.  The parser was developed with version
1.77 of Parse::RecDescent.

parser.pl is a script which uses this module to do the actual parsing.  
a test Verilog file is included called test1.v

to parse the file, type:

parser.pl test1.v

(or "parser.pl test1.v test2.v test3.v")

This should print out a report on test1.v that looks something like this:

module testmodule 


contained the following input ports:
	clock
	myin
	reset_n


contained the following inout ports:


contained the following output ports:
	myout
	outwire


contained the following wires:
	 type wire 	clock
	 type wire 	myin
	 type wire 	mywire
	 type wire 	outwire
	 type wire 	reset_n


contained the following regs:
	myout
	temp_reg1 [ 23 : 0 ] 
	temp_reg2 [ 35 : 0 ] 


contained the following instances:
	c is instance of clkblk 
	c1 is instance of clkbufrd 
	u2 is instance of core 
	u3 is instance of and08 
	u4 is instance of or02 

contained the following function declarations :


contained the following parameters :


line count is 677
timit result is 58 wallclock secs (58.05 usr +  0.06 sys = 58.11 CPU)
using 58.05 seconds parse time
parse_rate is      11.66 lines/sec  (          677 /      58.05 )  src/test2.v 

=========================================================


parser.pl will generate a similar report for all
modules it encounters in the files it is given.

a sample parser.pl file could look like this:

#! /bin/perl -sw
use Hardware::Verilog::Parser;
$parse = new Hardware::Verilog::Parser;
$parse->SearchPath(
	'./',
	'./include/'
	);
$parse->Filename(@ARGV);


This will parse all the files passed as command line parameters.
Note, it also sets a "search path" which gives the parser a list
of paths to search for the given filenames.
If no search path is specified, files are assumed to be at ./ 
If search path is specified, and you want to start searching at ./
then you need to explicitly specify this.

=========================================================

The parser is now precompiled, and runs much faster than
the previous versions. Without precompilation, it took
about 60 seconds to run, with precompilation, it takes
roughly 6 seconds. An order of magnitude improvement.

you'll notice the report above lists performance numbers,
and they aren't exactly impressive.
currently, benchmarks average about 20 lines of Verilog
code parsed per second. So, yes, its still slow. 
Damian has promised me the next version (2.0) of 
Parse::RecDescent will have about a 5x speed improvement. 
Unfortunately, it may be a couple months before its 
released.

given its slow speed, the parser would be useful for 
applications that can be run overnight, such as checking
coding rules on all the verilog currently checked into RCS.

I would eventually like to be able to detect signals
that can be categorized as asyncronous, syncronous, 
clocks, registered output, gated outputs, and use that
information to automatically generate synthesis scripts,
and flag problem areas, such as combinatorial paths
that cross multiple hierarchy boundaries, and the like.

=========================================================



Directory structure / installation information:

once you untarred the file, you can install
the files by creating a directory structure
similar to this:

~home/Hardware/Verilog

inside that directory, copy the following files:

Hierarchy.pm
Parser.pm
StdLogic.pm

The remaining files go into ~home.
This would be where you run your perl scripts from.

You will need to run the perl script:
generate_precompiled_parser.pl
to generate the file PrecompiledParser.pm
this also goes into ~home
(or whatever directory you are running your perl
scripts from)



If you have any corrections or questions,
please send them to me at
greg42@bellatlantic.net

thanks,
Greg London

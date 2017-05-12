#! /bin/perl -sw

####################################################
# Copyright (C) 2000 Greg London
# All Rights Reserved.
####################################################

use Hardware::Vhdl::Parser;
$parser = new Hardware::Vhdl::Parser;

$parser->Filename(@ARGV);




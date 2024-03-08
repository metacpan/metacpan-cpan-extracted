#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Devel::MAT::Context;
require Devel::MAT::Dumpfile;
require Devel::MAT::Graph;
require Devel::MAT::SV;
require Devel::MAT::Tool;

require Devel::MAT;

require Devel::MAT::InternalTools;

require Devel::MAT::Tool::Callers;
require Devel::MAT::Tool::Count;
require Devel::MAT::Tool::Find;
require Devel::MAT::Tool::Identify;
require Devel::MAT::Tool::Inrefs;
require Devel::MAT::Tool::ListDanglingPtrs;
require Devel::MAT::Tool::Outrefs;
require Devel::MAT::Tool::Reachability;
require Devel::MAT::Tool::Show;
require Devel::MAT::Tool::Sizes;
require Devel::MAT::Tool::Stack;
require Devel::MAT::Tool::Strtab;
require Devel::MAT::Tool::Summary;
require Devel::MAT::Tool::Symbols;

pass( 'Modules loaded' );
done_testing;

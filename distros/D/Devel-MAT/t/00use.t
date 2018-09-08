#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Devel::MAT::Context' );
use_ok( 'Devel::MAT::Dumpfile' );
use_ok( 'Devel::MAT::Graph' );
use_ok( 'Devel::MAT::SV' );
use_ok( 'Devel::MAT::Tool' );

use_ok( 'Devel::MAT' );

use_ok( 'Devel::MAT::InternalTools' );

use_ok( 'Devel::MAT::Tool::Callstack' );
use_ok( 'Devel::MAT::Tool::Count' );
use_ok( 'Devel::MAT::Tool::Find' );
use_ok( 'Devel::MAT::Tool::Identify' );
use_ok( 'Devel::MAT::Tool::Inrefs' );
use_ok( 'Devel::MAT::Tool::Outrefs' );
use_ok( 'Devel::MAT::Tool::Reachability' );
use_ok( 'Devel::MAT::Tool::Show' );
use_ok( 'Devel::MAT::Tool::Sizes' );
use_ok( 'Devel::MAT::Tool::Summary' );
use_ok( 'Devel::MAT::Tool::Symbols' );

done_testing;

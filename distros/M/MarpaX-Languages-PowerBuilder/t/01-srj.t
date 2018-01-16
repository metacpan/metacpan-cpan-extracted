#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 't/lib';
use TestFunctions;
use utf8;

plan tests => 35;

my $package = 'MarpaX::Languages::PowerBuilder::SRJ';
use_ok( $package )       || print "Bail out!\n";

my $parser = $package->new;
is( ref($parser), $package, 'testing new');
	
my $DATA = <<'DATA';
HA$PBExportHeader$p_pgm_geni.srj
$PBExportComments$Generated Application Executable Project
EXE:pgm9.exe,pgm.pbr,0,1,1
CMP:0,0,0,2,0,0,0
COM:Company S-$$HEX1$$e000$$ENDHEX$$-r-l
DES:Pgm - Bank regulatory reporting
CPY:Copyright 1994-2014 Company
PRD:Pgm
PVS:9.6.1 interne 10
PVN:9,6,1,0
FVS:9060100
FVN:9,6,1,0
MAN:1,asInvoker,0
PBD:pgm.pbl,pgm.pbr,1
PBD:company.pbl,pgm.pbr,1
OBJ:C:\Developpement\Powerbuilder\Pgm\trunk\Sources\p8_iml.pbl,uo_class_iml_host,u
OBJ:C:\Developpement\Powerbuilder\Pgm\trunk\Sources\company.pbl,makefullpath,f
OBJ:C:\Developpement\Powerbuilder\Pgm\trunk\Sources\pgm.pbl,optimizedatabase,f
DATA
my $parsed = $parser->parse( $DATA );
is( ref($parser), $package, 'testing parsed package');
is( $parsed->{error}, '', 'testing parse(FH) without error');

my $got = $parsed->value;
my $expected = {
	  exe => [ 'pgm9.exe', 'pgm.pbr', '0', '1', '1' ],
	  cmp => [ '0', '0', '0', '2', '0', '0', '0' ],
	  com => [ 'Company S-à-r-l' ],
	  des => [ 'Pgm - Bank regulatory reporting' ],
	  cpy => [ 'Copyright 1994-2014 Company' ],
	  prd => [ 'Pgm' ],
	  pvs => [ '9.6.1 interne 10' ],
	  pvn => [ '9', '6', '1', '0' ],
	  fvs => [ '9060100' ],
	  fvn => [ '9', '6', '1', '0' ],
	  man => [ '1', 'asInvoker', '0' ],
	  pbd => [
		[ 'pgm.pbl', 'pgm.pbr', '1' ],
		[ 'company.pbl', 'pgm.pbr', '1' ],
	  ],
	  obj => [ 
		[ 'C:\\Developpement\\Powerbuilder\\Pgm\\trunk\\Sources\\p8_iml.pbl', 'uo_class_iml_host', 'u' ],
		[ 'C:\\Developpement\\Powerbuilder\\Pgm\\trunk\\Sources\\company.pbl', 'makefullpath', 'f' ],
		[ 'C:\\Developpement\\Powerbuilder\\Pgm\\trunk\\Sources\\pgm.pbl', 'optimizedatabase', 'f' ],
	  ],
	};

_is_deep_diff( $got, $expected, 'testing parse(FH) value');

#additional tests
my @tests = ( 
		[ 'executable_name'             , 'pgm9.exe' ],
		[ 'application_pbr'             , 'pgm.pbr'  ],
		[ 'prompt_for_overwrite'        , 0             ],
		[ 'rebuild_type'                , 'full'        ],
		[ 'rebuild_type_int'            , 1             ],
		[ 'windows_classic_style'       , 0             ],
		[ 'new_visual_style_controls'   , 1             ],

		[ 'build_type'			        , ''            ],
		[ 'build_type_int'		        , 0             ],
		[ 'with_error_context'          , 0             ],
		[ 'with_trace_information'      , 0             ],
		[ 'optimisation'                , 'speed'       ],
		[ 'optimisation_int'            , 0             ],
		[ 'enable_debug_symbol'         , 0             ],

		[ 'manifest_type'               , 'embedded'    ],
		[ 'manifest_type_int'           , 1             ],
		[ 'execution_level'             , 'asInvoker'   ],
		[ 'access_protected_sys_ui'     , 'false'       ],
		[ 'access_protected_sys_ui_int' , 0             ], 
		
		[ 'product_name'                , 'Pgm'      ],
		[ 'company_name'                , 'Company S-à-r-l' ],
		[ 'description'                 , 'Pgm - Bank regulatory reporting' ],
		[ 'copyright'                   , 'Copyright 1994-2014 Company'    ],
		[ 'product_version_string'      , '9.6.1 interne 10'                   ],
		[ 'product_version_number'      , '9.6.1.0'     ],
		[ 'product_version_numbers'     , '9,6,1,0'     ],
		[ 'file_version_string'         , '9060100'     ],
		[ 'file_version_number'         , '9.6.1.0'     ],
		[ 'file_version_numbers'        , '9,6,1,0'     ],
		
		[ 'manifestinfo_string'         , '1;asInvoker;false' ],
		
		#todo: test 'pbd' and 'obj' methods
	);

for my $test( @tests ){
	
	my $method = $test->[0];
	$expected  = $test->[1];

	$got       = join ',', $parsed->$method();
	
	$method    =~ tr/_-/  /;
	
	is( $got, $expected, "retrieve info '$method'" );
}

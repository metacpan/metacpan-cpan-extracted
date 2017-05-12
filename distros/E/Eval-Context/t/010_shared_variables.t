# test

package Eval::Context ;

use strict ;
use warnings ;

use Data::TreeDumper ;
use Test::More ;
use Data::Dumper ;


#----------------------------------------------------------

package some_object ;

use strict ;
use warnings ;

sub new {bless { VALUE => $_[1] }, $_[0];}
sub GetValue {$_[0]->{VALUE} ;}
sub AddOne{$_[0]->{VALUE} += 1 ;}
sub GetDump {Data::Dumper->Dump([$_[0]]) ;}

#----------------------------------------------------------

package main ;

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context 'constants' ; 

use constant SETUP => 0 ;
use constant CODE => 1 ;
use constant EXPECTED_RESULT => 2 ;

{
local $Plan = {'SHARED' => 16} ;

# check PERSISTENT or SHARED is valid

my $scalar_caller_side = 42 ;
my $scalar_caller_side_reference = $scalar_caller_side ;

my $string_caller_side = 'a string' ;
my $string_caller_side_reference = $string_caller_side ;

my %hash_caller_side = (A => 1, B => 2) ;
my %hash_caller_side_reference = %hash_caller_side ;

my @array_caller_side = ('A', 'B') ;
my @array_caller_side_reference = @array_caller_side ;

my $object = new some_object(5) ;
my $object_dump = $object->GetDump() ;
my $object_original_value = $object->GetValue() ;

my $context = new Eval::Context() ;

for my $test 
	(
	#            SETUP                                                               CODE                      EXPECTED RESULT
	[ [ '$scalar' , \$string_caller_side, $Eval::Context::SHARED], "\$\$scalar ;\n"       , '$output, $string_caller_side' ],
	[ [ '$scalar' , undef,                $Eval::Context::SHARED], "\$\$scalar .= '*' ;\n", '$output, $string_caller_side_reference . "*"' ],
	[ [ '$scalar' , undef,                $Eval::Context::SHARED], ''                   , '$string_caller_side, $string_caller_side_reference . "*"' ],
	[ [ '$scalar' , undef,                $Eval::Context::SHARED], "\$\$scalar;\n"        , '$output, $string_caller_side' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$hash'   , \%hash_caller_side,  $Eval::Context::SHARED] , "\$hash->{B} ;\n"          , '$output , $hash_caller_side{B}'  ],
	[ [ '$hash'   , undef,               $Eval::Context::SHARED], "\$hash->{B}++ ;\n my \$r = \$hash->{B} + 1;\n\$r ;\n"
							, '$output , $hash_caller_side{B} + 1'  ],
	[ [ '$hash'   , undef,               $Eval::Context::SHARED], '', '$hash_caller_side{B} , $hash_caller_side_reference{B} + 1'  ],
	[ [ '$hash'   , undef,              $Eval::Context::SHARED] , "\$hash->{B} ;\n", '$output, $hash_caller_side{B}'  ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$array'   , \@array_caller_side, $Eval::Context::SHARED] ,  "\$array->[1] ;\n"         , '$output , $array_caller_side[1]' ],
	[ [ '$array'   , undef,              $Eval::Context::SHARED] ,  "\$array->[1] .= 'X' ;\n my \$r = \$array->[1] . '*';\n\$r ;\n"
							, '$output , $array_caller_side[1] . "*"' ],
	[ [ '$array'   , undef,              $Eval::Context::SHARED] ,  '', '$array_caller_side[1], $array_caller_side_reference[1] . "X"' ],
	[ [ '$array'   , undef,              $Eval::Context::SHARED] ,  "\$array->[1] ;\n", '$output, $array_caller_side[1]' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$object' , $object, $Eval::Context::SHARED]            , "\$object->GetValue() ;\n" , '$output , $object->GetValue()'   ],
	[ [ '$object' , undef, $Eval::Context::SHARED]              , "\$object->AddOne() ;\n\$object->GetValue() ;\n",
								'$output , $object->GetValue()'   ],
	[ [ '$object' , undef, $Eval::Context::SHARED]              , '' , ' $object->GetValue(), $object_original_value + 1'   ],
	[ [ '$object' , undef, $Eval::Context::SHARED]              , "\$object->GetDump() ;\n" , '$output, $object->GetDump()'   ],
	#~ #---------------------------------------------------------------------------------------------------------------------------------------
	)
	{
	my $output = $context->eval
			(
			INSTALL_VARIABLES => [$test->[SETUP]],
			CODE => $test->[CODE],
			) ;

	eval qq~ is($test->[EXPECTED_RESULT], 'eval side only') or diag "latest code:\n\$context->{LATEST_CODE}\n" ~ ;
	die $@ if $@ ;
	}
}

{
local $Plan = {'SHARED variable must exist' => 1} ;

my $context = new Eval::Context() ;

throws_ok
	{
	my $output = $context->eval(CODE => 'boom!', INSTALL_VARIABLES => [[ '$variable' , undef, $Eval::Context::SHARED]]) ;
	} qr/Nothing previously shared to '\$variable' /, 'SHARED variable must exist' ;
}


{
local $Plan = {'divers tests' => 2} ;

# add test so code to be evaluated is dumped on error

my $scalar = 42 ;
my $context = new Eval::Context() ;

throws_ok
	{
	my $output = $context->eval(CODE => 'boom!', INSTALL_VARIABLES => [[ '$variable' , $scalar, $Eval::Context::SHARED]]) ;
	} qr/Need a reference to share from for '\$variable'/, 'can only share references' ;
	
throws_ok
	{
	my $output = $context->eval(CODE => 'boom!', INSTALL_VARIABLES => [[ '$variable' , \$scalar, 111]]) ;
	} qr/Variable '\$variable' type must be SHARED or PERSISTENT/, 'SHARED or PERSISTENT' ;
}

{
local $Plan = {'SHARE vs PERSISTENT' => 1} ;

my $object = new some_object(5) ;
my $context = new Eval::Context() ;

$context->eval
	(
	CODE => '',
	INSTALL_VARIABLES => [[ '$object' , $object, $Eval::Context::PERSISTENT] ],
	) ;

throws_ok
	{
	$context->eval
		(
		CODE => '',
		INSTALL_VARIABLES => [[ '$object' , $object, $Eval::Context::SHARED] ],
		) ;
	} qr/'\$object' can't be SHARED, already PERSISTENT/, 'can not have persistent and shared' ;
}

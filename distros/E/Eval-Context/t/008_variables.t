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

use Eval::Context ; 

use constant SETUP => 0 ;
use constant CODE => 1 ;
use constant EXPECTED_RESULT => 2 ;


{
local $Plan = {'divers tests' => 1} ;

# add test so code to be evaluated is dumped on error

my $context = new Eval::Context() ;

throws_ok
	{
	my $output = $context->eval(CODE => 'boom!', INSTALL_VARIABLES => []) ;
	} qr/#end of context/, 'context displayed and error caught' ;
}

{
local $Plan = {'eval side only' => 29} ;

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

my $context = new Eval::Context() ;

# test the variables are made available on the eval side
# tests to verify nothing is changed from the eval side

for my $test 
	(
	#            SETUP                              CODE                         EXPECTED RESULT
	[ [ '$variable', 42]              ,  '$variable ;'                         , '$output , 42' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$scalar' , $string_caller_side ]  ,  '$scalar ;'                         , '$output , $string_caller_side'   ],
	[ [ '$scalar' , $string_caller_side ]  ,  "\$scalar .= '*' ;\n"      , '$output , $string_caller_side . "*"'  ],
	[ [ '$scalar' , $string_caller_side ]  ,  "\$scalar .= '*' ;\n"      , '$string_caller_side , $string_caller_side_reference'  ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$scalar' , $scalar_caller_side ]  ,  '$scalar'                         , '$output , $scalar_caller_side'   ],
	[ [ '$scalar' , $scalar_caller_side ]  ,  "\$scalar += 2 ;\n"        , '$output , $scalar_caller_side + 2'   ],
	[ [ '$scalar' , $scalar_caller_side ]  ,  "\$scalar += 2 ;\n"        , '$scalar_caller_side , $scalar_caller_side_reference'   ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$hash'   , \%hash_caller_side ]   ,  "\$hash->{B} ;\n"          , '$output , $hash_caller_side{B}'  ],
	[ [ '$hash'   , \%hash_caller_side ]   ,  "my \$r = \$hash->{B} + 1;\n\$r ;\n"
							, '$output , $hash_caller_side{B} + 1'  ],
	[ [ '$hash'   , \%hash_caller_side ]   ,  "my \$r = \$hash->{B} + 1;\n \$r ;\n"
							, '$hash_caller_side{B} , $hash_caller_side_reference{B}'  ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '%hash'   , \%hash_caller_side ]   ,  "\$hash{B} ;\n"            , '$output , $hash_caller_side{B}'  ],
	[ [ '%hash'   , \%hash_caller_side ]   ,  "my \$r = \$hash{B} + 1;\n\$r ;\n"
							, '$output , $hash_caller_side{B} + 1'  ],
	[ [ '%hash'   , \%hash_caller_side ]   ,  "my \$r = \$hash{B} + 1;\n \$r ;\n"
							, '$hash_caller_side{B} , $hash_caller_side_reference{B}'  ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$array'   , \@array_caller_side ] ,  "\$array->[1] ;\n"         , '$output , $array_caller_side[1]' ],
	[ [ '$array'   , \@array_caller_side ] ,  "my \$r = \$array->[1] . '*';\n\$r ;\n"
							, '$output , $array_caller_side[1] . "*"' ],
	[ [ '$array'   , \@array_caller_side ] ,  "my \$r = \$array->[1] . '*';\n\$r ;\n"
							, '$array_caller_side[1] , $array_caller_side_reference[1]' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '@array'   , \@array_caller_side ] ,  "\$array[1] ;\n"           , '$output , $array_caller_side[1]' ],
	[ [ '@array'   , \@array_caller_side ] ,  "my \$r = \$array[1] . '*';\n\$r ;\n "           
							, '$output , $array_caller_side[1] . "*"' ],
	[ [ '@array'   , \@array_caller_side ] ,  "my \$r = \$array[1] . '*';\n\$r ;\n "           
							, '$array_caller_side[1] , $array_caller_side_reference[1]' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$object' , $object ]              ,  "\$object->GetValue() ;\n" , '$output , $object->GetValue()'   ],
	[ [ '$object' , $object ]              ,  "\$object->AddOne() ;\n" , '$output , $object->GetValue() + 1'   ],
	[ [ '$object' , $object ]              ,  "\$object->AddOne() ;\n" , '$object->GetDump() , $object_dump'   ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	)                                      
	{                                      
	my $output = $context->eval(CODE => $test->[CODE], INSTALL_VARIABLES => [$test->[SETUP]]) ;
	eval qq~ is($test->[EXPECTED_RESULT], 'eval side only') or diag "latest code:\n\$context->{LATEST_CODE}\n" ~ ;
	die $@ if $@ ;
	}


throws_ok
	{
	my $output = $context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['my $variable = 42 ;'] ]) ;
	} qr/Invalid variable definition/, 'no verbatim code' ;

throws_ok
	{
	my $output = $context->eval(CODE => '', INSTALL_VARIABLES => [ ['*variable', 42] ]) ;
	} qr/Invalid variable type for '\*variable'/, 'unsupported type' ;

lives_ok
	{
	$context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['$variable', 42] ]) ;
	}  'void context' ;
	
lives_ok
	{
	my $output = $context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['$variable', 42] ]) ;
	is($output, 42, 'right value in scalar context') ;
	}  'scalar context' ;
	
lives_ok
	{
	my @output = $context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['$variable', 42] ]) ;
	is_deeply(\@output, [42], 'right value in array  context') ;
	}  'array context' ;
}

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
local $Plan = {'PERSISTENT' => 37} ;

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

for my $test 
	(
	#            SETUP                                                               CODE                      EXPECTED RESULT
	[ [ '$scalar' , $string_caller_side, $Eval::Context::PERSISTENT ]  ,  "\$scalar ;\n"                , '$output, $string_caller_side'   ],
	[ [ '$scalar' , $Eval::Context::USE, $Eval::Context::PERSISTENT ]  ,  "\$scalar .= '*' ;\n"      , '$output, $string_caller_side . "*"'  ],
	[ [ '$scalar' , $Eval::Context::USE, $Eval::Context::PERSISTENT ]  ,  "\$scalar .= '*' ;\n"      , '$output, $string_caller_side . "**"'  ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$variable' , $scalar_caller_side,    $Eval::Context::PERSISTENT]  =>  '$variable += 1 ;'         => '$output => 43' ],
	[ [ '$variable' , $scalar_caller_side, $Eval::Context::PERSISTENT]  =>  '$variable += 1 ;'         => '$output => 43' ],
	[ [ '$variable' , $Eval::Context::USE, $Eval::Context::PERSISTENT]  =>  '$variable += 1 ;'         => '$output => 44' ],
	[ [ '$variable' , $scalar_caller_side, $Eval::Context::PERSISTENT]  =>  '$variable += 1 ;'         => '$output => 43' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$hash'   , \%hash_caller_side,  $Eval::Context::PERSISTENT]   ,  "\$hash->{B} ;\n"          , '$output , $hash_caller_side{B}'  ],
	[ [ '$hash'   , $Eval::Context::USE, $Eval::Context::PERSISTENT]   ,  "\$hash->{B}++ ;\n my \$r = \$hash->{B} + 1;\n\$r ;\n"
							, '$output , $hash_caller_side{B} + 2'  ],
	[ [ '$hash'   , $Eval::Context::USE, $Eval::Context::PERSISTENT]   ,  "my \$r = \$hash->{B} + 1;\n\$r ;\n"
							, '$output , $hash_caller_side{B} + 2'  ],
	[ [ '$hash'   , $Eval::Context::USE, $Eval::Context::PERSISTENT]   ,  "\$hash->{B}++ ;\n"
							, '$hash_caller_side{B} , $hash_caller_side_reference{B}'  ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '%hash'   , \%hash_caller_side,  $Eval::Context::PERSISTENT]   ,  "\$hash{B} ;\n"            , '$output , $hash_caller_side{B}'  ],
	[ [ '%hash'   , $Eval::Context::USE, $Eval::Context::PERSISTENT]   ,  "\$hash{B}++;\n my \$r = \$hash{B} + 1;\n\$r ;\n"
							, '$output , $hash_caller_side{B} + 2'  ],
	[ [ '%hash'   , $Eval::Context::USE, $Eval::Context::PERSISTENT]   ,  "my \$r = \$hash{B} + 1;\n\$r ;\n"
							, '$output , $hash_caller_side{B} + 2'  ],
	[ [ '%hash'   , $Eval::Context::USE, $Eval::Context::PERSISTENT]   ,  "\$hash{B} ++\n"
							, '$hash_caller_side{B} , $hash_caller_side_reference{B}'  ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$array'   , \@array_caller_side, $Eval::Context::PERSISTENT] ,  "\$array->[1] ;\n"         , '$output , $array_caller_side[1]' ],
	[ [ '$array'   , $Eval::Context::USE, $Eval::Context::PERSISTENT] ,  "\$array->[1] .= 'X' ;\n my \$r = \$array->[1] . '*';\n\$r ;\n"
							, '$output , $array_caller_side[1] . "X*"' ],
	[ [ '$array'   , $Eval::Context::USE, $Eval::Context::PERSISTENT] ,  "my \$r = \$array->[1] . '*';\n\$r ;\n"
							, '$output , $array_caller_side[1] . "X*"' ],
	[ [ '$array'   , $Eval::Context::USE, $Eval::Context::PERSISTENT] ,  "\$array->[1]++ ;\n"
							, '$array_caller_side[1] , $array_caller_side_reference[1]' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '@array'   , \@array_caller_side, $Eval::Context::PERSISTENT] ,  "\$array[1] ;\n"           , '$output , $array_caller_side[1]' ],
	[ [ '@array'   , $Eval::Context::USE, $Eval::Context::PERSISTENT] ,  "\$array[1] .= 'X' ;\nmy \$r = \$array[1] . '*';\n\$r ;\n "           
							, '$output , $array_caller_side[1] . "X*"' ],
	[ [ '@array'   , $Eval::Context::USE, $Eval::Context::PERSISTENT] ,  "my \$r = \$array[1] . '*';\n\$r ;\n "           
							, '$output , $array_caller_side[1] . "X*"' ],
	[ [ '@array'   , $Eval::Context::USE, $Eval::Context::PERSISTENT] ,  "\$array[1] .= 'X' ;\n "           
							, '$array_caller_side[1] , $array_caller_side_reference[1]' ],
	#---------------------------------------------------------------------------------------------------------------------------------------
	[ [ '$object' , $object,             $Eval::Context::PERSISTENT]            ,  "\$object->GetValue() ;\n" , '$output , $object->GetValue()'   ],
	[ [ '$object' , $Eval::Context::USE, $Eval::Context::PERSISTENT]              ,  "\$object->AddOne() ;\n" , '$output , $object->GetValue() + 1'   ],
	[ [ '$object' , $Eval::Context::USE, $Eval::Context::PERSISTENT]              ,  "\$object->AddOne() ;\n" , '$output , $object->GetValue() + 2'   ],
	[ [ '$object' , $Eval::Context::USE, $Eval::Context::PERSISTENT]              ,  "\$object->AddOne() ;\n" , '$object->GetDump() , $object_dump'   ],
	#---------------------------------------------------------------------------------------------------------------------------------------
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
	
my @persistent_variable_names = $context->GetPersistentVariableNames() ;
is_deeply(\@persistent_variable_names , [qw($object $array $variable %hash $hash $scalar @array)], 'persistent variable names') or diag DumpTree(\@persistent_variable_names ) ;

throws_ok
	{
	my $hash_after_eval = $context->GetPersistantVariables('%unknown') ;
	} qr /PERSISTENT variable '%unknown' doesn't exist/, 'accessing non persistent variable' ;
	

lives_ok
	{
	my $output = $context->eval
			(
			INSTALL_VARIABLES => [[ '$object' , 42, $Eval::Context::PERSISTENT]],
			CODE => '$object;',
			) ;
			
	is($output, 42) ;
	} 'persistent override' ;

{
my $hash_after_eval = $context->GetPersistantVariables('$hash') ;
is_deeply($hash_after_eval, {A => 1, B => 4}, 'get $hash') ;

my %hash = $context->GetPersistantVariables('%hash') ;
is_deeply(\%hash, {A => 1, B => 4}, 'get %hash') or diag DumpTree \%hash ;

# whatever the user set so might a reference
my $variable = $context->GetPersistantVariables('$variable') ;
is($variable, 43, 'get $variable') ;
}

# get more than one variable
{
# be careful with argument list flattening
my ($hash_ref, %hash) = $context->GetPersistantVariables('$hash', '%hash') ;
is_deeply($hash_ref, {A => 1, B => 4}, 'get $hash (multiple arguments)') ;
is_deeply(\%hash, {A => 1, B => 4}, 'get %hash (multiple arguments)') ;
}
	
# die if context is wrong
throws_ok
	{
	$context->GetPersistantVariables('$hash') ;
	} qr /called in void context/, 'called in void context' ;
}

{
local $Plan = {'REMOVE_PERSISTENT' => 7} ;

my $scalar_caller_side = 42 ;
my $string_caller_side = 'a string' ;
my %hash_caller_side = (A => 1, B => 2) ;
my @array_caller_side = ('A', 'B') ;
my $object = new some_object(5) ;

my $context = new Eval::Context() ;

my $output = $context->eval
		(
		INSTALL_VARIABLES => [[ '$variable' , $scalar_caller_side , $Eval::Context::PERSISTENT]],
		CODE => '$variable += 1 ;',
		) ;
		
is($output => 43, 'eval side only') or diag "latest code:\n$context->{LATEST_CODE}\n" ;

$output = $context->eval
		(
		INSTALL_VARIABLES => [[ '$variable' , $Eval::Context::USE, $Eval::Context::PERSISTENT]],
		CODE => '$variable += 1 ;',
		) ;
		
is($output => 44, 'eval side only') or diag "latest code:\n$context->{LATEST_CODE}\n" ;

$output = $context->eval
		(
		INSTALL_VARIABLES => [[ '$variable' , $Eval::Context::USE, $Eval::Context::PERSISTENT]],
		CODE => '$variable += 1 ;',
		REMOVE_PERSISTENT => [qr/not matching/],
		) ;
		
is($output => 45, 'eval side only') or diag "latest code:\n$context->{LATEST_CODE}\n" ;


$output = $context->eval
		(
		REMOVE_PERSISTENT => [qr/variable/],
		INSTALL_VARIABLES => [[ '$variable' , undef, $Eval::Context::PERSISTENT]],
		CODE => '$variable += 1 ;',
		) ;
		
is($output => 1, 'eval side only') or diag "latest code:\n$context->{LATEST_CODE}\n" ;


my @persistent_variable_names = $context->GetPersistentVariableNames() ;
is_deeply(\@persistent_variable_names , ['$variable'], 'persistent variable names') or diag DumpTree(\@persistent_variable_names ) ;

$output = $context->eval
		(
		CODE => '',
		REMOVE_PERSISTENT => [qr/variable/],
		) ;
		
@persistent_variable_names = $context->GetPersistentVariableNames() ;
is_deeply(\@persistent_variable_names , [], 'persistent variable names') or diag DumpTree(\@persistent_variable_names ) ;

throws_ok
	{
	$context->eval
		(
		CODE => '',
		REMOVE_PERSISTENT => 1,
		) ;
	} qr/Anonymous: 'REMOVE_PERSISTENT' must be an array reference containing regexes/, 'invalid REMOVE_PERSISTENT definition' ;
}

{
local $Plan = {'SHARE vs PERSISTENT' => 1} ;

my $object = new some_object(5) ;
my $context = new Eval::Context() ;

$context->eval
	(
	CODE => '',
	INSTALL_VARIABLES => [[ '$object' , $object, $Eval::Context::SHARED] ],
	) ;

throws_ok
	{
	$context->eval
		(
		CODE => '',
		INSTALL_VARIABLES => [[ '$object' , $object, $Eval::Context::PERSISTENT] ],
		) ;
	} qr/'\$object' can't be PERSISTENT, already SHARED/, 'can not have persistent and shared' ;
}


{
local $Plan = {'undef PERSISTENT variable' => 3} ;

my $context = new Eval::Context() ;

my $output = $context->eval
		(
		CODE => '$object ;',
		INSTALL_VARIABLES => [[ '$object' , undef, $Eval::Context::PERSISTENT] ],
		) ;

is($output, undef, 'underfined persistent declaration') ;

$output = $context->eval
		(
		CODE => '$object ;',
		INSTALL_VARIABLES => [[ '$object' , $Eval::Context::USE, $Eval::Context::PERSISTENT] ],
		) ;

is($output, undef, 'underfined persistent') ;

$output = $context->eval
		(
		CODE => '$object ;',
		INSTALL_VARIABLES => [[ '$object' , 42, $Eval::Context::PERSISTENT] ],
		) ;

is($output, 42, 'underfined persistent') ;
}


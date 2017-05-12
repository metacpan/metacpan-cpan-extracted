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
#~ use Test::NoWarnings qw(had_no_warnings);
use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context 'constants' ; 

{
local $Plan = {'SAFE and variables from caller side' => 3} ;

my $context = new Eval::Context() ;

my $normal = $context->eval
		(
		INSTALL_VARIABLES => [ ['$normal', 'normal'] ],
		SAFE =>{},
		CODE => '$normal',
		) ;

is($normal, 'normal', 'normal variable available in safe') or diag DumpTree $context ;

#---------------------------------------------

$context->eval
		(
		INSTALL_VARIABLES => [ ['$persistent', 'garbage', $Eval::Context::PERSISTENT ] ],
		SAFE =>{},
		CODE => '$persistent = q{persistent} ;',
		) ;

my $persistent = $context->eval
		(
		INSTALL_VARIABLES => [ ['$persistent', $Eval::Context::USE, $Eval::Context::PERSISTENT ] ],
		SAFE =>{},
		CODE => '$persistent ;',
		) ;

is($persistent, 'persistent', 'persistent variable available in safe') or diag DumpTree $context ;

#---------------------------------------------

my $shared = 'eval_side_value' ;
$context->eval
		(
		INSTALL_VARIABLES => [ ['$shared', \$shared, $Eval::Context::SHARED ] ],
		SAFE =>{},
		CODE => '$$shared = q{shared} ;',
		) ;

is($shared, 'shared', 'shared variable available in safe') or diag DumpTree $context ;

}

{
local $Plan = {'SAFE and eval side persistent variables ' => 1} ;

my $context = new Eval::Context
		(
		EVAL_SIDE_PERSISTENT_VARIABLES =>
			{
			CATEGORY => 'TEST',
			SAVE => 
				{
				NAME => 'SavePersistent',
				VALIDATOR => sub 
					{
					my ($self, $name, $value, $package) = @_ ;
					},
				},
				
			GET => 
				{
				NAME => 'GetPersistent',
				VALIDATOR => sub {}
				},
			},
		) ;

$context->eval
		(
		SAFE =>{},
		CODE => <<'EOC' ,
my $variable = 24 ;
SavePersistent('$variable', $variable) ;
EOC
		) ;

my $output = $context->eval
			(
			SAFE =>{},
			CODE => <<'EOC' ,
my $variable = GetPersistent('$variable') ;
EOC
			) ;
			
is($output, 24, 'eval side persistent variable available in safe') or diag DumpTree $context ;
}

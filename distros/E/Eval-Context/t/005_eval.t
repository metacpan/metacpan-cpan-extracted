# test

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context ; 


{
local $Plan = {'eval empty options' => 6} ;

#~ NAME
#~ PRE_CODE
#~ POST_CODE
#~ PACKAGE
#~ DISPLAY_SOURCE_IN_CONTEXT
#~ FILE LINE

my $context = new Eval::Context() ;

lives_ok
	{
	$context->eval(CODE => '') ;
	} 'empty code' ;
	
lives_ok
	{
	$context->eval(CODE => '', PACKAGE => 'A') ;
	} 'empty code, package' ;
	
lives_ok
	{
	$context->eval(CODE => '', PACKAGE => undef) ;
	} 'anonymous package from bad package' ;

throws_ok
	{
	$context->eval(CODE => 'die', PACKAGE => undef) ;
	} qr/Anonymous/,  'anonymous package from bad package' ;
	
lives_ok
	{
	$context->eval(CODE => '', PACKAGE => 'A', PRE_CODE  => "use strict;\nuse warnings;\n") ;
	}'empty code, pre code' ;

lives_ok
	{
	$context->eval(CODE => '', PACKAGE => 'A', POST_CODE => "print qq{post code\\n};\n",) ;
	} 'empty code, post code' ;

}

{
local $Plan = {'package' => 3} ;

{
my $context = new Eval::Context(PACKAGE => 'HIP') ;
my $package = $context->eval(CODE => '__PACKAGE__ ;', PACKAGE => 'HOP') ;

is($package, 'HOP', 'package override') ;
} 


{
my $context = new Eval::Context() ;
my $package = $context->eval(CODE => '__PACKAGE__ ;') ;

like ($package, qr/Eval::Context::Run_\d+/, 'default package name') ;
} 

{
my $context = new Eval::Context() ;
my $package = $context->eval(CODE => '__PACKAGE__ ;',  PACKAGE => '') ;

like ($package, qr/Eval::Context::Run_\d+/, 'empty package name') ;
} 

}

{
local $Plan = {'eval evaluation context' => 16} ;
	
my $context = new Eval::Context() ;

throws_ok
	{
	$context->eval(CODE => 'die "void context" unless defined wantarray;', PACKAGE => 'A', PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n") ;
	} qr/void context/, 'void context' ;

lives_ok
	{
	my $value = $context->eval(CODE => '7', PACKAGE => 'A', PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n") ;
	is($value, 7, 'eval returned last value') ;
	} 'returned scalar' ;

lives_ok
	{
	my $value = $context->eval(CODE => "my \@l = (7,8) ;", PACKAGE => 'A', PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n") ;
	is($value, 2, 'eval returned last value') ;
	} 'returned list, scalar context' ;
	
#~ # see 005_eval_no_NoWarnings for the test below
#~ lives_ok
	#~ {
	#~ my $value = $context->eval(CODE => "(7,8) ;", PACKAGE => 'A', PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n") ;
	#~ is($value, 8, 'eval returned last value') ;
	#~ } 'returned list, scalar context' ;
	
lives_ok
	{
	my $value = $context->eval(CODE => "my \@l = (7,8) ;", PACKAGE => 'A') ;
	is($value, 2, 'eval returned last value') ;
	} 'returned list, scalar context' ;
	
lives_ok
	{
	my @values = $context->eval(CODE => '(7,8) ;', PACKAGE => 'A', PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n") ;
	is_deeply(\@values, [7,8], 'eval returned list') ;
	} 'returned list, list context' ;



# use PERL_EVAL_CONTEXT
lives_ok
	{
	my $value = $context->eval
			(
			CODE => "wantarray ;",
			PACKAGE => 'A',
			PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n",
			PERL_EVAL_CONTEXT => undef # force void context
			) ;
	is($value, undef, 'void context') ;
	} 'force void context' ;

lives_ok
	{
	my $value = $context->eval
			(
			CODE => "wantarray ;",
			PACKAGE => 'A',
			PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n",
			PERL_EVAL_CONTEXT => 1 # force list context
			) ;
	is($value, 1, 'list context') ;
	} 'force list context' ;
	
lives_ok
	{
	my @values = $context->eval
			(
			CODE => "wantarray ;",
			PACKAGE => 'A',
			PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\\n} ;\n",
			PERL_EVAL_CONTEXT => '' # force scalar context
			) ;
			
	is(scalar(@values), 1, 'scalar context') ;
	is($values[0], '', 'scalar context') ;
	} 'force scalar context' ;
}

{
local $Plan = {'eval' => 5} ;

#~ NAME, PRE_CODE, POST_CODE

my $context = new Eval::Context
		(
		NAME      => "THE_NAME",
		PRE_CODE  => "use strict;\nuse warnings;\nprint qq{pre code\n} ;",
		POST_CODE => "die qq{POST_CODE}",
		) ;

throws_ok
	{
	$context->eval(CODE => '$x = 3 ;') ;
	}qr/Global symbol "\$x" requires explicit package name/, 'not strict code' ;

throws_ok
	{
	$context->eval(CODE => '') ;
	}qr/POST_CODE at 'THE_NAME_called_at_t_005_eval.t:\d+'/, 'POST_CODE and NAME' ;


#~ PACKAGE
lives_ok
	{
	$context->eval(CODE => "sub GetVariable\n{return 117 ;}\n", PACKAGE => 'TEST_PACKAGE', POST_CODE => '', REMOVE_PACKAGE_AFTER_EVAL => 0) ;
	} "post code die overridden" ;
	
is(TEST_PACKAGE::GetVariable(), 117, 'PACKAGE OK') ;	
	
#~ DISPLAY_SOURCE_IN_CONTEXT, FILE, LINE
use Test::Output;

sub writer 
{
$context->eval
	(
	DISPLAY_SOURCE_IN_CONTEXT => 1,
	FILE => 'TEST_FILE',
	LINE => 'TEST_LINE',
	PACKAGE => 'TEST_PACKAGE',
	PRE_CODE => '# test pre code',
	CODE => '# test code',
	POST_CODE => '# test post code'
	) ;
}

stdout_is(\&writer,<<EOT,'Test STDOUT');
Eval::Context called at 'TEST_FILE:TEST_LINE' to evaluate:
#line 0 'THE_NAME_called_at_TEST_FILE:TEST_LINE'
package TEST_PACKAGE ;
# PRE_CODE
# test pre code
#line 0 'THE_NAME_called_at_TEST_FILE:TEST_LINE'
# CODE
# test code
# POST_CODE
# test post code
#end of context 'THE_NAME_called_at_TEST_FILE:TEST_LINE'
EOT

# test all overrides (put stuff in new and check it is still there)
}

{
local $Plan = {'eval from file' => 3} ;

my $context = new Eval::Context() ;

use Directory::Scratch::Structured qw(create_structured_tree piggyback_directory_scratch) ; 
my %tree_structure = ( file_0 => ['print "hi\n"; 7 ;']) ;

my $temporary_directory = create_structured_tree(%tree_structure) ;
my $base = $temporary_directory->base() ;

lives_ok
	{
	is($context->eval(CODE_FROM_FILE => "$base/file_0"), 7, 'value from file') ;
	} 'code from file' ;
	
eval 
	{
	$context->eval(CODE_FROM_FILE => '') ;	
	};
ok($!{ENOENT}, 'unexisting file' );
}


{
local $Plan = {'die' => 5} ;

my $context = new Eval::Context() ;

throws_ok
	{
	$context->eval(CODE_FROM_FILE => '', CODE => '') ;
	} qr/Option 'CODE' and 'CODE_FROM_FILE' can't coexist/, 'CODE and CODE_FROM_FILE' ;

throws_ok
	{
	$context->eval(CODE_FROM_FILE => undef) ;
	} qr/Invalid Option 'CODE'/, 'CODE_FROM_FILE undef' ;

throws_ok
	{
	$context->eval(CODE => undef) ;
	} qr/Invalid Option 'CODE'/, 'CODE undef' ;
	
throws_ok
	{
	my $value = $context->eval
			(
			CODE => "die 'force list context' ;",
			PERL_EVAL_CONTEXT => 1 # force list context
			) ;
	} qr/force list context/, 'die in force list context' ;
	
throws_ok
	{
	my @values = $context->eval
			(
			CODE => "die 'force scalar context' ;",
			PERL_EVAL_CONTEXT => '' # force scalar context
			) ;
	} qr/force scalar context/, 'die in force scalar context' ;
	
}


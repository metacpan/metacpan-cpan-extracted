# perl_critic test

use strict ;
use warnings ;
use Term::ANSIColor qw(:constants);

#~ use Test::More skip_all => 'perl_critic' ;


use Test::Perl::Critic 
	-severity => 1,
	# %p for rule name
#	-format =>  "[%s] %m  at " .  BOLD . BLUE . "'%f:%l:%c'" . RESET . " rule " .  BOLD . RED . "%p %e\n" . RESET
#				. "\t%r",
	-format =>  "%m [%s] at " . BLACK . ON_WHITE . "'%f:%l:%c'" . RESET . "%e\n"
				. "\t%r\n",
	-exclude =>
		[
		'Miscellanea::RequireRcsKeywords',
		'NamingConventions::ProhibitMixedCaseSubs',
		'ControlStructures::ProhibitPostfixControls',
		'CodeLayout::ProhibitParensWithBuiltins',
		'Documentation::RequirePodAtEnd',
		'ControlStructures::ProhibitUnlessBlocks',
		'CodeLayout::RequireTidyCode',
		'CodeLayout::ProhibitHardTabs',
		'CodeLayout::ProhibitTrailingWhitespace',
		'ValuesAndExpressions::ProhibitCommaSeparatedStatements', # too many false positives. See RT #27654
		], 
		
	-profile => 'xt/author/perlcriticrc' ;

all_critic_ok() ;
	

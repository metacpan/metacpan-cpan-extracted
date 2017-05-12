#!perl  -T

use Test::More tests => 2;
use strict;

# ... to be written ....

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE::Object' }

#--------------------------------------------------------------------#
# Test 2: autoload => string & caller

{	
	require JE;
	my $j = new JE;
	my $o = new JE::Object $j;
	{
		package thingeemajig;
		$o->prop({ name => 'foo', autoload => 'return bar()'});
	}
	sub thingeemajig::bar { 636 }
	is $o->{foo}, '636', 'autoload => string evals in calling package'
}	


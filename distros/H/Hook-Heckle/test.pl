# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Hook::Heckle;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

	sub one
	{
		$_ = "one" and print;
		
		return $_;
	}
	
	sub two
	{
		$_ = "two" and print;
		
		return $_;
	}
	
	my $start = sub 
	{ 			
		my $this = shift;
		
		printf '<%s>', $this->victim;
	};

	my $stop = sub 
	{ 			
		my $this = shift;
		
		printf "</%s>\n", $this->victim;

		printf "Results: %s\n", join( '', $this->result );
		
	};

	Hook::Heckle->new( context => __PACKAGE__, victim => 'one', pre => $start, post => $stop );
	
	Hook::Heckle->new( context => __PACKAGE__, victim => 'two', pre => $start, post => $stop );

	one();
	two();
	
ok(2);
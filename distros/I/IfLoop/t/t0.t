# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 17 };
use IfLoop;

#--------------------------------------------------------------------------1
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $i=10;
#--------------------------------------------------------------------------2
ifwhile($i > 0 ){--$i}
ok($i,0);

#--------------------------------------------------------------------------3
if(0){;}elsifuntil($i == 10){++$i}
ok($i,10);

#--------------------------------------------------------------------------4
if($i == 10)
{
    if(1)
    {
	if(0){;}
	elsifwhile(0){ $i = 10 }
	else
	{
	    $i = 13
	}
    }
}
ok($i,13);

#----------------------------------------------------------------------5...9
my ($j,$k,$m) = (5,0,5);
ifwhile($j > 0)
{
    ifuntil($k > 5)
    {
	ifwhile($m > 0)
	{
	    ok(1);
	    --$m;
	}
	++$k;
    }
    --$j;
}

#-------------------------------------------------------------------------10
ok($j == 0 && $k == 6 && $m == 0);

#--------------------------------------------------------------------10...16
($j,$k,$m) = (5,0,5);
ifwhile($j > 0)
{
    ifuntil($k > 5)
    {
	#ifwhile($m > 0)
	#{
	    ok(1);
	#    --$m;
	#}
	++$k;
    }
    --$j;
}


#-------------------------------------------------------------------------17
ok($j == 0 && $k == 6 && $m == 5);

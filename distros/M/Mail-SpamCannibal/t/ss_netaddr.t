# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..35\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use NetAddr::IP::Lite;
use Mail::SpamCannibal::ScriptSupport qw(
        list2NetAddr
        matchNetAddr
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2	instantiate netaddr array
#
# A multi-formated array of IP address that will never be tarpitted.
#
# WARNING: if you are using a private network, then you should include the 
# address description for the net/subnets that you are using or you might
# find your DMZ or internal mail servers blocked since many DNSBLS list the
# private network addresses as BLACKLISTED
#
#       127./8, 10./8, 172.16/12, 192.168/16
#
#       class A         xxx.0.0.0/8
#       class B         xxx.xxx.0.0/16
#       class C         xxx.xxx.xxx.0/24	0
#       128 subnet      xxx.xxx.xxx.xxx/25	128
#        64 subnet      xxx.xxx.xxx.xxx/26	192
#        32 subnet      xxx.xxx.xxx.xxx/27	224
#        16 subnet      xxx.xxx.xxx.xxx/28	240
#         8 subnet      xxx.xxx.xxx.xxx/29	248
#         4 subnet      xxx.xxx.xxx.xxx/30	252
#         2 subnet      xxx.xxx.xxx.xxx/31	254
#       single address  xxx.xxx.xxx.xxx/32	255
#
@tstrng = (
	    # a single address
	'11.22.33.44',
	    # a range of ip's, ONLY VALID WITHIN THE SAME CLASS 'C'
	'22.33.44.55 - 22.33.44.65',
	'45.67.89.10-45.67.89.32',
	    # a CIDR range
	'5.6.7.16/28',
	    # a range specified with a netmask
	'7.8.9.128/255.255.255.240',
	    # this should ALWAYS be here
	'127.0.0.0/8',  # ignore all test entries and localhost
);
my @NAobject;
my $rv = list2NetAddr(\@tstrng,\@NAobject);
print "wrong number of NA objects\ngot: $rv, exp: 6\nnot "
	unless $rv == 6;
&ok;

## test 3	check disallowed terms
print "accepted null parameter\nnot "
	if matchNetAddr();
&ok;

## test 4	check disallowed parm
print "accepted non-numeric parameter\nnot "
	if matchNetAddr('junk');
&ok;

##test 5	check non-ip short
print "accepted short ip segment\nnot "
	if matchNetAddr('1.2.3');
&ok;

# yeah, it will accept a long one, but that's tough!

## test 6-35	bracket NA objects
#
my @chkary =	# 5 x 6 tests 
    #	out left	in left		middle		in right	out right
qw(	11.22.33.43	11.22.33.44	11.22.33.44	11.22.33.44	11.22.33.45
	22.33.44.54	22.33.44.55	22.33.44.60	22.33.44.65	22.33.44.66
	45.67.89.9	45.67.89.10	45.67.89.20	45.67.89.32	45.67.89.33
	5.6.7.15	5.6.7.16	5.6.7.20	5.6.7.31	5.6.7.32
	7.8.9.127	7.8.9.128	7.8.9.138	7.8.9.143	7.8.9.144
	126.255.255.255	127.0.0.0	127.128.128.128	127.255.255.255	128.0.0.0
);

for(my $i=0;$i <= $#chkary; $i+=5) {
  print "accepted outside left bound $chkary[$i]\nnot "
	if matchNetAddr($chkary[$i],\@NAobject);
  &ok;
  print "rejected inside left bound $chkary[$i+1]\nnot "
	unless matchNetAddr($chkary[$i+1],\@NAobject);
  &ok;
  print "rejected inside middle bound $chkary[$i+2]\nnot "
	unless matchNetAddr($chkary[$i+2],\@NAobject);
  &ok;
  print "rejected inside right bound $chkary[$i+3]\nnot "
	unless matchNetAddr($chkary[$i+3],\@NAobject);
  &ok;
  print "accepted outside right bound $chkary[$i+4]\nnot "
	if matchNetAddr($chkary[$i+4],\@NAobject);
  &ok;
}

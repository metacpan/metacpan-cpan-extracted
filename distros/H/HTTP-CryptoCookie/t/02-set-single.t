# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { 
	use_ok('HTTP::CryptoCookie');
	use_ok('Time::HiRes',qw(gettimeofday tv_interval));
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $key = '12345678901234567890123456789012';
my $debug = 1;
my $cc = new HTTP::CryptoCookie($key,$debug);

isa_ok($cc,'HTTP::CryptoCookie');

my $struct = {
	foo  => 'bar',
	sing => [qw(do re me fa so la ti da)],
	sung => {
		one => 1,
		two => 2,
	},
	blargh => [1..25],
};

my $rv = eval { $cc->set_cookie(
	cookie => $struct,
	cookie_name => 'TEST',
) };
is($rv, 1, 'setting of single cookie');



my $t0 = [gettimeofday];
my $cc2 = new HTTP::CryptoCookie($key);
for(1..1000) {
	$struct->{now} = [gettimeofday];
	$cc2->set_cookie(
		cookie => $struct,
		cookie_name => "TEST$_",
	);
}
my $elapsed = sprintf("%0.3f",tv_interval ($t0));
diag("ran at $elapsed ms per cookie over 1000 cookies");


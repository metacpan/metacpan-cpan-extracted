use Test::More;
#use lib '/home/mshekhawa/Locale-India/lib/';
BEGIN { plan tests => 5 };
use Locale::India;
ok(1);

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $u = new Locale::India;

use Data::Dumper;

my $code  = 'IN-RJ';
my $state = 'RAJASTHAN';
my $utcode = 'IN-DL';
my $ut = 'DELHI';

is ( $u->{code2state}{$code}, $state, "Code to state test" );

is ( $u->{state2code}{$state}, $code, "State to code test" );

is ( $u->{code2ut}{$utcode}, $ut, "Code to union territory test");

is ( $u->{ut2code}{$ut}, $utcode, "Union territory to code test");

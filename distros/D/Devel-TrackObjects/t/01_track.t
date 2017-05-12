use Test;
BEGIN { plan tests => 6 };
use Devel::TrackObjects qr/^myTest::/, '-noend';

#################################################
# some packages to play with
#################################################

package myTest::Zero;
sub new { bless {}, shift }

package myTest::One;
use base 'myTest::Zero';
# gets new() from myTest::Zero

package notMyTest;
sub new { bless {}, shift }

#################################################
# Test starts here
#################################################

package main;

# create one of each
my $o0 = myTest::Zero->new;
my $o1 = myTest::One->new;
my $on = notMyTest->new;

my $o = Devel::TrackObjects->show_tracked;
ok( delete $o->{'myTest::Zero'} == 1 );
ok( delete $o->{'myTest::One'}  == 1 );
ok( ! %$o ); # that's all because notMyTest is not tracked

{
	# create another myTest::One inside block
	my $o1_1 = myTest::One->new;
	$o = Devel::TrackObjects->show_tracked;
	ok( $o->{'myTest::Zero'} == 1 );
	ok( $o->{'myTest::One'}  == 2 );
}

# outside block the additional object (o1_1) should
# be destroyed
$o = Devel::TrackObjects->show_tracked;
ok( $o->{'myTest::One'}  == 1 );




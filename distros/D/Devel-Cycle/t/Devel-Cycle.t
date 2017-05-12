# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Devel-Cycle.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
use Scalar::Util qw(weaken isweak);
BEGIN { use_ok('Devel::Cycle') };

#########################

my $test = {fred   => [qw(a b c d e)],
	    ethel  => [qw(1 2 3 4 5)],
	    george => {martha => 23,
		       agnes  => 19},
	   };
$test->{george}{phyllis} = $test;
$test->{fred}[3]      = $test->{george};
$test->{george}{mary} = $test->{fred};

my ($test2,$test3);
$test2 = \$test3;
$test3 = \$test2;

my $counter = 0;
find_cycle($test,sub {$counter++});
is($counter,4,'found four cycles in $test');

$counter = 0;
find_cycle($test2,sub {$counter++});
is($counter,1,'found one cycle in $test2');

# now fix them with weaken and make sure that gets noticed
$counter = 0;
weaken($test->{george}->{phyllis});
find_cycle($test,sub {$counter++});
is($counter,2,'found two cycles in $test after weaken()');

# uncomment this to test the printing
# diag "Not Weak";
# find_cycle($test);
# diag "Weak";
# find_weakened_cycle($test);

$counter = 0;
find_weakened_cycle($test,sub {$counter++});
is($counter, 4, 'found four cycles (including weakened ones) in $test after weaken()');

$counter = 0;
weaken($test->{fred}[3]);
find_cycle($test,sub {$counter++});
is($counter,0,'found no cycles in $test after second weaken()');

$counter = 0;
find_weakened_cycle($test,sub {$counter++});
is($counter,4,'found four cycles (including weakened ones) in $test after second weaken()');

my $a = bless {},'foo';
my $b = bless {},'bar';
$a->{'b'} = $b;
$counter = 0;
find_cycle($a,sub {$counter++});
is($counter,0,'found no cycles in reference stringified on purpose to create a false alarm');

SKIP:
{
    skip 'These tests require PadWalker 1.0+', 1
        unless Devel::Cycle::HAVE_PADWALKER;

    $counter = 0;

    my %cyclical = ( a => [],
                     b => {},
                   );
    $cyclical{a}[0]   = $cyclical{a};
    $cyclical{b}{key} = $cyclical{a};

    my @cyclical = [];
    $cyclical[0] = \@cyclical;

    my $sub = sub { return \@cyclical, \%cyclical; };

    find_cycle($sub,sub {$counter++});
    is($counter,3,'found three cycles in $cyclical closure');
}

{
    *FOOBAR = *FOOBAR if 0; # cease -w
    my $test2 = { glob => \*FOOBAR };

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    find_cycle($test2);
    pass("No failure if encountering glob");
    like("@warnings", qr{unhandled type.*glob}i, "Expected warning");

    @warnings = ();
    find_cycle($test2);
    is("@warnings", "", "Warn only once");
}

package foo;
use overload q("") => sub{ return 1 };  # show false alarm

package bar;
use overload q("") => sub{ return 1 };

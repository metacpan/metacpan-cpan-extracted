use strict;
use warnings;

use Test::More tests => 15;

use FindBin '$Bin';
use Gearman::WorkerSpawner;

my $left_hand = 3;
my $right_hand = 5;

my $spawner = Gearman::WorkerSpawner->new;

push @INC, "$Bin/lib";

# test that different workers coexist
$spawner->add_worker(class => 'TestWorker');

$spawner->add_worker(
    class        => 'MethodWorker',
    num_workers  => 2,
    config       => {
        left_hand => $left_hand,
    },
);

# triples of [$function_name, $function_arg, $result_callback]
my @tests = (

    [constant => 0, sub {
        my $number = shift;
        is(ref $number, '', 'numeric scalar');
        is($number, 123, 'numeric scalar value');
    }],

    [constant => 1, sub {
        my $string = shift;
        is(ref $string, '', 'string scalar');
        is($string, 'string', 'string scalar value');
    }],

    [echo => undef, sub {
        my $echoed = shift;
        is(ref $echoed, '', 'undef');
        is($echoed, undef, 'undef value');
    }],

    [echo => 'foo', sub {
        my $echoed = shift;
        is(ref $echoed, '', 'scalar');
        is($echoed, 'foo', 'scalar value');
    }],

    [echo => ['foo'], sub {
        my $echoed = shift;
        is(ref $echoed, 'ARRAY', 'arrayref');
        is_deeply($echoed, ['foo'], 'array value');
    }],

    [echo => {'foo' => 'bar'}, sub {
        my $echoed = shift;
        is(ref $echoed, 'HASH', 'hashref');
        is_deeply($echoed, {'foo' => 'bar'}, 'hash value');
    }],

    [echo_ref => \'bar', sub {
        my $echoed_ref = shift;
        is(ref $echoed_ref, 'SCALAR', 'string scalar ref');
        is($$echoed_ref, 'bar', 'string scalar ref value');
    }],

    [add => { right_hand => $right_hand }, sub {
        my $return = shift;
        is($return->{sum}, $left_hand + $right_hand, 'addition');
    }],

);

my $tester;
$tester = sub {
    exit unless @tests;
    my $test = shift @tests;
    $spawner->run_method($test->[0], $test->[1], {
        on_complete => sub {
            $test->[2]->(@_);
            $tester->();
        },
        on_fail => sub {
            my $err = shift;
            fail("$test->[0] tripped on_failure: $err"),
            $tester->();
        },
        timeout => 3,
    });
};
$tester->();

Danga::Socket->EventLoop;

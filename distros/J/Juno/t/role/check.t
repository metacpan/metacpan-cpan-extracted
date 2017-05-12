#!perl

use strict;
use warnings;

use Test::More tests => 25;
use Test::Fatal;

use Juno;
use AnyEvent;

# this will help us test the majority of things
{
    package Juno::Check::TestCheckZd7DD;
    use Moo;
    use Test::More;
    with 'Juno::Role::Check';

    sub check {1}

    sub run {
        my $self = shift;
        isa_ok( $self, 'Juno::Check::TestCheckZd7DD' );
        ok( $self->does('Juno::Role::Check'), 'Does check role' );

        ok( $self->has_on_success, 'Got on_success' );
        ok( $self->has_on_fail,    'Got on_fail'    );
        ok( $self->has_on_result,  'Got on_result'  );

        is(
            $self->on_success->(),
            'success!',
            'Correct on_success',
        );

        is(
            $self->on_fail->(),
            'fail!',
            'Correct on_fail',
        );

        is(
            $self->on_result->($self),
            'result!',
            'Correct on_result',
        );

        is_deeply(
            $self->hosts,
            ['A', 'B'],
            'Hosts provided by Juno.pm',
        );

        cmp_ok(
            $self->interval,
            '==',
            30,
            'Interval provided by Juno.pm',
        );

        $self->clear_watcher;
    }
}

# this helps us check that attributes were overwritten
{
    package Juno::Check::TestCheckF7A23;
    use Moo;
    use Test::More;
    with 'Juno::Role::Check';

    sub check {1}

    sub run {
        my $self = shift;
        isa_ok( $self, 'Juno::Check::TestCheckF7A23' );
        ok( $self->does('Juno::Role::Check'), 'Does check role' );

        is_deeply(
            $self->hosts,
            ['C', 'D'],
            'Hosts were overwritten',
        );

        cmp_ok(
            $self->interval,
            '==',
            40,
            'Interval was overwritten',
        );

        $self->clear_watcher;
    }
}

# this helps us check that the check() method actually works
{
    package Juno::Check::TestCheckFzVS33;
    use Moo;
    use Test::More;
    with 'Juno::Role::Check';

    has count => ( is => 'rw', default => sub {0} );

    sub check {
        my $self = shift;
        isa_ok( $self, 'Juno::Check::TestCheckFzVS33' );
        ok( $self->does('Juno::Role::Check'), 'Does check role' );

        $self->count( $self->count() + 1 );

        $self->on_success->( $self, 'finished' );
    }
}

# uses the first check
{
    my $juno = Juno->new(
        hosts    => ['A', 'B'],
        interval => 30,
        checks   => {
            TestCheckZd7DD => {
                on_success => sub { 'success!' },
                on_fail    => sub { 'fail!'    },
                on_result  => sub {
                    shift->clear_watcher;
                    'result!';
                },
            },
        },
    );

    isa_ok( $juno, 'Juno' );

    $juno->run;
}

# uses the second check
{
    my $juno = Juno->new(
        hosts  => ['A', 'B'],
        checks => {
            TestCheckF7A23 => {
                hosts    => ['C', 'D'],
                interval => 40,
            },
        },
    );

    isa_ok( $juno, 'Juno' );

    $juno->run;
}

# uses the third check
{
    my $cv   = AnyEvent->condvar;
    my $juno = Juno->new(
        interval => 0.1,
        checks   => {
            TestCheckFzVS33 => {
                on_success => sub {
                    my $self = shift;
                    my $msg  = shift;

                    isa_ok( $self, 'Juno::Check::TestCheckFzVS33' );
                    is( $msg, 'finished', 'Got correct msg' );

                    if ( $self->count == 2 ) {
                        $self->clear_watcher;
                        $cv->send;
                    }
                },
            },
        },
    );

    isa_ok( $juno, 'Juno' );

    $juno->run;

    $cv->recv;
}

my $cv    = AnyEvent->condvar;
my $w; $w = AnyEvent->timer(
    after => 0.5,
    cb    => sub {
        undef $w;
        $cv->send;
    },
);

$cv->recv;


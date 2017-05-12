package ClientTest;

use strict;
use warnings;

use Gearman::Spawner;
use Gearman::Spawner::Server;
use Test::More;

sub new {
    my $class = shift;

    my $address = Gearman::Spawner::Server->address;

    my $self = bless {
        class       => 'MethodWorker',
        left_hand   => 3,
        right_hand  => 5,
        server      => $address,
    }, $class;

    $self->{spawner} = Gearman::Spawner->new(
        servers => [$address],
        workers => {
            $self->{class} => {
                data => {
                    left_hand => $self->{left_hand},
                },
            },
        },
    );

    return $self;
}

sub server { shift->{server} }
sub class { shift->{class} }

sub tests {
    my $self = shift;

    return (

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

        [add => { right_hand => $self->{right_hand} }, sub {
            my $return = shift;
            is($return->{sum}, $self->{left_hand} + $self->{right_hand}, 'addition');
        }],
    );
}

1;

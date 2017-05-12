package Flux::Test::Out;

# ABSTRACT: Test::Class-based collection of tests for output streams

use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;
use Params::Validate qw(:all);

sub new {
    my $class = shift;
    my ($out_gen) = validate_pos(@_, { type => CODEREF });
    my $self = $class->SUPER::new;
    $self->{out_gen} = $out_gen;
    return $self;
}

sub setup :Test(setup) {
    my $self = shift;
    $self->{out} = $self->{out_gen}->();
}

sub teardown :Test(teardown) {
    my $self = shift;
    delete $self->{out};
}

sub is_stream_out :Test(1) {
    my $self = shift;
    ok($self->{out}->does('Flux::Out'));
}

sub write_scalar :Test(1) {
    my $self = shift;
    $self->{out}->write('abc');
    $self->{out}->write(5);
    $self->{out}->write(123);
    pass('write succeeded');
}

sub write_chunk_scalar :Test(1) {
    my $self = shift;
    $self->{out}->write_chunk([ 'a', 'b', 5 ]);
    $self->{out}->write_chunk([ 'a', 'b', 6 ]);
    pass('write_chunk succeeded');
}

sub commit_scalar :Test(1) {
    my $self = shift;
    $self->{out}->write('abc');
    $self->{out}->write(5);
    $self->{out}->write_chunk([ 'a'..'e' ]);
    $self->{out}->commit;
    $self->{out}->write('a b');
    $self->{out}->commit;
    pass('commit with mixed writes succeeded');
}

1;

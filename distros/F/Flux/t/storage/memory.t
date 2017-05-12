#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';
use lib 't/lib';
use parent qw(Test::Class);
use Flux::Test::Out;
use Flux::Test::StorageWithClients;
use Flux::Test::StorageRW;

use Flux::Storage::Memory;

sub check_lag :Tests {
    my $self = shift;

    my $ms = Flux::Storage::Memory->new();
    my $in = $ms->in('blah');
    $ms->write('foo');
    $ms->write('bar');
    $ms->write('bar2');
    is $in->lag, 10;
    $in->read;
    is $in->lag, 7;
    $in->read;
    $in->read;
    $in->read;
    is $in->lag, 0;
}

sub pos_after_null_read :Tests {
    my $ms = Flux::Storage::Memory->new();
    my $in = $ms->in('blah');
    is $in->read, undef;
    $ms->write('aaa');
    $ms->commit;
    is $in->read, 'aaa';
}

my $basic_test = Flux::Test::Out->new(sub {
    Flux::Storage::Memory->new()
});

my $client_test = Flux::Test::StorageWithClients->new(sub {
    Flux::Storage::Memory->new()
});

my $rw_test = Flux::Test::StorageRW->new(sub {
    Flux::Storage::Memory->new()
});

Test::Class->runtests(
    $basic_test,
    $client_test,
    $rw_test,
    __PACKAGE__->new,
);

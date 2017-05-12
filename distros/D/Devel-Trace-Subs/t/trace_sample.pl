#!/usr/bin/perl
use strict;
use warnings;

use Devel::Trace::Subs qw(trace trace_dump);

package One;
use Devel::Trace::Subs qw(trace trace_dump);

sub new {
    trace();
    my $self = bless {}, shift;
    return $self;
}

sub set
{
    trace();
    my $self = shift;
    $self->{greeting} = shift || 'bye!';
    return $self->get;
}

sub get {
    trace();
    my $self = shift;
    return $self->{greeting} || '';
}

package Two;
use Devel::Trace::Subs qw(trace trace_dump);

sub new {
    trace();
    my $self = bless {}, shift;
    return $self;
}

sub add {
    trace();
    my $self = shift;
    $self->check;
    $self->{one} = One->new;
}

sub check {
    trace();
    my $self = shift;
    return 0 if ! $self->{undefined};
}

package main;

my $two = Two->new;

$two->add;

$two->{one}->set('hello, world!');

trace_dump(type => 'html', file => 'index.html');

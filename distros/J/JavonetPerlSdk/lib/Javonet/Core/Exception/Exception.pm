package Javonet::Core::Exception::Exception;
use strict;
use warnings FATAL => 'all';
use Moose;
use lib 'lib';

my $message;
my $stack_trace;



sub new {
    my ($proto, $exception_message, $stack_trace) = @_;
    my $self = bless {}, $proto;
    $message = $exception_message;
    return $self;
}

sub get_message(){
    my $self = @_;
    return $message;
}

sub get_stack_trace(){
    my $self = @_;
    return $stack_trace;
}

1;
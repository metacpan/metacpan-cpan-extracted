package Javonet::Core::Handler::CommandHandler::InvokeStaticMethodHandler;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;
use Nice::Try;
use aliased 'Javonet::Core::Exception::Exception' => 'Exception';
extends 'Javonet::Core::Handler::CommandHandler::AbstractCommandHandler';

sub new {
    my $class = shift;
    my $self = {
        required_parameters_count => 2
    };
    return bless $self, $class;
}

sub process {
    my ($self, $command) = @_;
    try {
        my $current_payload_ref = $command->{payload};
        my @cur_payload = @$current_payload_ref;
        my $parameters_length = @cur_payload;
        if ($parameters_length < $self->{required_parameters_count}) {
            die Exception->new("Exception: InvokeStaticMethod parameters mismatch");
        }
        my $clazz = $command->{payload}[0];
        my $method_name = $command->{payload}[1];

        if (my $method = $clazz->can($method_name)) {
            if ($parameters_length == $self->{required_parameters_count}) {
                return $method->();
            }
            else {
                my @method_arguments;
                for (my $i = 2; $i < $parameters_length; $i++) {
                    push @method_arguments, $command->{payload}[$i];
                }
                return $method->(@method_arguments);
            }
        }
        else {
            die Exception->new("Exception InvokeStaticMethod: method not found");
        }
    }
    catch ($e){
        return Exception->new($e);
    }
}

1;
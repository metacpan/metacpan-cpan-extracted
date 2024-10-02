package Javonet::Core::Exception::ExceptionSerializer;
use strict;
use warnings FATAL => 'all';
use Moose;
use lib 'lib';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';


sub serialize {
    my ($self, $exception) = @_;
    my $name = ref($exception);
    my $message = $exception->get_message;
    my $stack_trace = $exception->get_stack_trace;
    my $command =  PerlCommand->new(
        runtime      => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Exception'),
        payload      => [0, undef , $name , $message, $stack_trace, undef, undef, undef]
    );

    return $command

}

no Moose;
1;
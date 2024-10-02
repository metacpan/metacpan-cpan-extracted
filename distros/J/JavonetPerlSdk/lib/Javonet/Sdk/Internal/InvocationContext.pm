package Javonet::Sdk::Internal::InvocationContext;
use strict;
use warnings FATAL => 'all';
use Moose;

use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Core::Handler::PerlHandler' => 'PerlHandler';
use aliased 'Javonet::Core::Interpreter::Interpreter' => 'Interpreter', qw(execute_);
use aliased 'Javonet::Core::Exception::ExceptionThrower' => 'ExceptionThrower';

extends 'Javonet::Sdk::Internal::Abstract::AbstractInstanceContext',
    'Javonet::Sdk::Internal::Abstract::AbstractMethodInvocationContext',
    'Javonet::Sdk::Internal::Abstract::AbstractInvocationContext';

my $perl_handler = Javonet::Core::Handler::PerlHandler->new();

sub new {
    my $class = shift;

    my $self = {
        runtime_name     => shift,
        connection_type  => shift,
        tcp_address      => shift,
        current_command  => shift,
        isExecuted       => shift,
        response_command => 0,
    };


    bless $self, $class;
    return $self;
}

# DESTROY {
#     my $self = $_[0];
#     if ($self->{current_command}->{command_type} == Javonet::Sdk::Core::PerlCommandType::get_command_type('Reference') &&
#         $self->{isExecuted} == 1) {
#         $self->{current_command} = PerlCommand->new(
#             runtime      => $self->{runtime_name},
#             command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('DestructReference'),
#             payload      => $self->{current_command}->{payload}
#         );
#         $self->execute();
#     }
# }

#@override
sub execute {
    my $self = $_[0];
    $self->{response_command} = Interpreter->execute_($self->{current_command}, $self->{connection_type}, $self->{tcp_address});

    if ($self->{response_command}->{command_type} == Javonet::Sdk::Core::PerlCommandType::get_command_type('Exception')) {
        ExceptionThrower->throwException($self->{response_command})
    }

    if ($self->{current_command}->{command_type} == Javonet::Sdk::Core::PerlCommandType::get_command_type('CreateClassInstance')) {
        $self->{current_command} = $self->{response_command};
        $self->{isExecuted} = 1;
        return $self;
    }

    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->{response_command},
        1
    );
}


#@override
sub invoke_instance_method {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('InvokeInstanceMethod'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub get_instance_field {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetInstanceField'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub set_instance_field {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('SetInstanceField'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub create_instance {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('CreateClassInstance'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub invoke_static_method {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('InvokeStaticMethod'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub set_generic_type {
}

#@override
sub get_static_field {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetStaticField'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub set_static_field {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('SetStaticField'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub get_index {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('ArrayGetItem'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub get_size {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('ArrayGetSize'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub get_rank {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('ArrayGetRank'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub set_index {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('ArraySetItem'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub invoke_generic_static_method {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('InvokeGenericStaticMethod'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub invoke_generic_method {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('InvokeGenericMethod'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub get_enum_name {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetEnumName'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

#@override
sub get_enum_value {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetEnumValue'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub get_ref_value {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetRefValue'),
        payload => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->get_connection_type(),
        $self->get_tcp_address(),
        $self->build_command($command),
        0
    );
}

sub create_null {
    my ($self, @arguments) = @_;
    my $command = PerlCommand->new(
        runtime      => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('CreateNull'),
        payload      => \@arguments
    );
    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->get_connection_type(),
        $self->get_tcp_address(),
        $self->build_command($command),
        0
    );
}

sub get_current_command {
    my $self = shift;
    return $self->{current_command};
}

#@override
sub get_value {
    my $self = shift;
    return $self->{current_command}->{payload}[0]
}

sub build_command {
    my ($self, $command) = @_;
    my $payload_length = @{$command->{payload}};
    for (my $i = 0; $i < $payload_length; $i++) {
        $command->{payload}[$i] = $self->encapsulate_payload_item($command->{payload}[$i]);
    }
    return $command->prepend_arg_to_payload($self->{current_command});
}

sub encapsulate_payload_item {
    my ($self, $payload_item) = @_;

    if(!defined $payload_item) {
        return PerlCommand->new(
            runtime => $self->{runtime_name},
            command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Value'),
            payload => []
        );
    }

    if ($payload_item->isa('Command')) {
        my $payload_length = @{$payload_item->{payload}};
        for (my $i = 0; $i < $payload_length; $i++) {
            $payload_item->{payload}[$i] = $self->encapsulate_payload_item($payload_item->{payload}[$i]);
        }
        return $payload_item;
    }
    elsif ($payload_item->isa('Javonet::Sdk::Internal::InvocationContext')) {
        return $payload_item->get_current_command();
    }
    elsif (ref($payload_item) eq 'ARRAY') {
        my $payload_length = @$payload_item;
        for (my $i = 0; $i < $payload_length; $i++) {
            $payload_item->[$i] = $self->encapsulate_payload_item($payload_item->[$i]);
        }
        return PerlCommand->new(
            runtime => $self->{runtime_name},
            command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Array'),
            payload => $payload_item
        );
    }
    else {
        return PerlCommand->new(
            runtime => $self->{runtime_name},
            command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Value'),
            payload => [$payload_item]
        );
    }
}

no Moose;
1;
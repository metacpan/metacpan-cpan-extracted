package Javonet::Sdk::Internal::RuntimeContext;
use strict;
use warnings FATAL => 'all';
use Moose;

use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Internal::InvocationContext' => 'InvocationContext';
use aliased 'Javonet::Core::Handler::PerlHandler' => 'PerlHandler';
use aliased 'Javonet::Core::Interpreter::Interpreter' => 'Interpreter', qw(execute_);
use aliased 'Javonet::Core::Exception::ExceptionThrower' => 'ExceptionThrower';

extends 'Javonet::Sdk::Internal::Abstract::AbstractModuleContext',
    'Javonet::Sdk::Internal::Abstract::AbstractTypeContext';

my $perl_handler = Javonet::Core::Handler::PerlHandler->new();
our %memoryRuntimeContexts;
our %networkRuntimeContexts;
our %configRuntimeContexts;

#@override
sub new {
    my $class = shift;

    my $self = {
        runtime_name     => shift,
        connection_type => shift,
        tcp_address     => shift,
        response_command => 0,
    };
    bless $self, $class;
    return $self;
}

sub get_instance {
    my $runtime_name = shift;
    my $connection_type = shift;
    my $tcp_address = shift;
    my $path = shift;

    if($connection_type eq Javonet::Sdk::Internal::ConnectionType::get_connection_type("InMemory")) {
        if(exists $memoryRuntimeContexts{$runtime_name}) {
            my $runtimeCtx = $memoryRuntimeContexts{$runtime_name};
            $runtimeCtx->{current_command} = undef();
            return $runtimeCtx;
        }
        else {
            my $runtimeCtx = Javonet::Sdk::Internal::RuntimeContext->new($runtime_name, $connection_type, '');
            $memoryRuntimeContexts{$runtime_name} = $runtimeCtx;
            return($runtimeCtx);
        }
    }

    if($connection_type eq Javonet::Sdk::Internal::ConnectionType::get_connection_type("Tcp")) {
        my $networkRuntimeContextsKey = $runtime_name . $tcp_address;
        if(exists $networkRuntimeContexts{$networkRuntimeContextsKey}) {
            my $runtimeCtx = $networkRuntimeContexts{$networkRuntimeContextsKey};
            $runtimeCtx->{current_command} = undef();
            return $runtimeCtx;
        }
        else {
            my $runtimeCtx = Javonet::Sdk::Internal::RuntimeContext->new($runtime_name, $connection_type, $tcp_address);
            $networkRuntimeContexts{$networkRuntimeContextsKey} = $runtimeCtx;
            return($runtimeCtx);
        }
    }

    if($connection_type eq Javonet::Sdk::Internal::ConnectionType::get_connection_type("WithConfig")) {
        my $configRuntimeContextsKey = $runtime_name . $path;
        if(exists $configRuntimeContexts{$configRuntimeContextsKey}) {
            my $runtimeCtx = $configRuntimeContexts{$configRuntimeContextsKey};
            $runtimeCtx->{current_command} = undef();
            return $runtimeCtx;
        }
        else {
            my $runtimeCtx = Javonet::Sdk::Internal::RuntimeContext->new($runtime_name, $connection_type, $tcp_address);
            $configRuntimeContexts{$configRuntimeContextsKey} = $runtimeCtx;
            return($runtimeCtx);
        }
    }
}


sub execute {
    my $self = $_[0];
    my $command = shift;
    my $connection_type = shift;
    my $tcp_address = shift;
    $self->{response_command} = Interpreter->execute_($command, $connection_type, $tcp_address);
    if ($self->{response_command}->{command_type} == Javonet::Sdk::Core::PerlCommandType::get_command_type('Exception')) {
        ExceptionThrower->throwException($self->{response_command})
    }
}


#@override
sub load_library {
    my $self = shift;
    my @load_library_parameters = @_;

    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('LoadLibrary'),
        payload => \@load_library_parameters
    );

    execute($self->build_command($command), $self->{connection_type}, $self->{tcp_address});
    return $self;
}

#@override
sub get_type {
    my $self = shift;
    my @arguments = @_;

    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetType'),
        payload => \@arguments
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
sub cast {
    my $self = shift;
    my @arguments = @_;

    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Cast'),
        payload => \@arguments
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
sub get_enum_item {
    my $self = shift;
    my @arguments = @_;

    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetEnumItem'),
        payload => \@arguments
    );

    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub as_out {
    my $self = shift;
    my @arguments = @_;

    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('AsOut'),
        payload => \@arguments
    );

    return Javonet::Sdk::Internal::InvocationContext->new(
        $self->{runtime_name},
        $self->{connection_type},
        $self->{tcp_address},
        $self->build_command($command),
        0
    );
}

sub as_ref {
    my $self = shift;
    my @arguments = @_;

    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('AsRef'),
        payload => \@arguments
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

sub health_check {
    my $self = shift;

    my $command = PerlCommand->new(
        runtime => $self->{runtime_name},
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Value'),
        payload => ['health_check']
    );

    execute($self->build_command($command), $self->{connection_type}, $self->{tcp_address});
}

no Moose;
1;
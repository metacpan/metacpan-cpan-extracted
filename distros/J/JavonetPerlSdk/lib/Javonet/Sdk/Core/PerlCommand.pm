package Javonet::Sdk::Core::PerlCommand;
use strict;
use warnings;
use lib 'lib';
use Moose;
use Scalar::Util;

use aliased 'Javonet::Sdk::Core::PerlCommandType' => 'PerlCommandType';

has 'runtime' => (
    is => 'ro',
    isa => 'Int',
    required => 1,
    reader => '_get_runtime'
);

has 'command_type' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    reader   => '_get_command_type'
);

has 'payload' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {[]},
    reader  => '_get_payload'
);

# Constructor with params object[] (list of objects)
sub new {
    my ($class, %args) = @_;
    my $runtime = $args{runtime};
    my $command_type = $args{command_type};
    my $payload = $args{payload};
    
    # If payload is not provided or is undef, use empty array
    if (!defined $payload) {
        $payload = [];
    }
    # If payload is already an array reference, use it directly
    elsif (ref $payload eq 'ARRAY') {
        # Reuse array reference directly - no conversion overhead
        $payload = $payload;
    }
    # If payload is a list (not a reference), convert to array reference
    else {
        # This handles the case where payload might be passed as a list
        # Convert to array reference
        my @payload_array = ref $payload ? @$payload : ($payload);
        $payload = \@payload_array;
    }
    
    my $self = {
        runtime => $runtime,
        command_type => $command_type,
        payload => $payload
    };
    
    bless $self, $class;
    return $self;
}

# Static factory method: CreateResponse
sub CreateResponse {
    my ($class, $response, $runtime_name) = @_;
    return $class->new(
        runtime => $runtime_name,
        command_type => PerlCommandType->get_command_type('Value'),
        payload => [$response]
    );
}

# Static factory method: CreateReference
sub CreateReference {
    my ($class, $guid, $runtime_name) = @_;
    return $class->new(
        runtime => $runtime_name,
        command_type => PerlCommandType->get_command_type('Reference'),
        payload => [$guid]
    );
}

# Static factory method: CreateArrayResponse
sub CreateArrayResponse {
    my ($class, $array, $runtime_name) = @_;
    # Convert array to array reference if needed
    my $payload = ref $array eq 'ARRAY' ? $array : [$array];
    return $class->new(
        runtime => $runtime_name,
        command_type => PerlCommandType->get_command_type('Array'),
        payload => $payload
    );
}

# DropFirstPayloadArg - matches C# DropFirstPayloadArg
sub DropFirstPayloadArg {
    my ($self) = @_;
    my $class = ref($self) || $self;
    my $current_payload_ref = $self->{payload};
    my @cur_payload = @$current_payload_ref;
    my $payload_length = @cur_payload;
    
    if ($payload_length <= 1) {
        return $class->new(
            runtime => $self->{runtime},
            command_type => $self->{command_type},
            payload => []
        );
    }
    
    my $new_length = $payload_length - 1;
    my @new_payload = @cur_payload[1 .. $#cur_payload];
    
    return $class->new(
        runtime => $self->{runtime},
        command_type => $self->{command_type},
        payload => \@new_payload
    );
}

# AddArgToPayload - matches C# AddArgToPayload
sub AddArgToPayload {
    my ($self, $arg) = @_;
    my $class = ref($self) || $self;
    my $current_payload_ref = $self->{payload};
    my @cur_payload = @$current_payload_ref;
    my $old_length = @cur_payload;
    my @new_payload = (@cur_payload, $arg);
    
    return $class->new(
        runtime => $self->{runtime},
        command_type => $self->{command_type},
        payload => \@new_payload
    );
}

# PrependArgToPayload - matches C# PrependArgToPayload
sub PrependArgToPayload {
    my ($self, $arg_command) = @_;
    
    if (!defined $arg_command) {
        return $self;
    }
    
    my $class = ref($self) || $self;
    my $current_payload_ref = $self->{payload};
    my @cur_payload = @$current_payload_ref;
    my $old_length = @cur_payload;
    my @new_payload = ($arg_command, @cur_payload);
    
    return $class->new(
        runtime => $self->{runtime},
        command_type => $self->{command_type},
        payload => \@new_payload
    );
}

# Legacy method name for backward compatibility
sub addArgumentToPayload {
    my ($self, $payload_ref) = @_;
    my @payload_array = ref $payload_ref eq 'ARRAY' ? @$payload_ref : ($payload_ref);
    return $self->AddArgToPayload($payload_array[0]) if @payload_array == 1;
    # For multiple items, add them one by one
    my $result = $self;
    for my $item (@payload_array) {
        $result = $result->AddArgToPayload($item);
    }
    return $result;
}

# Legacy method name for backward compatibility
sub drop_first_payload_argument {
    return $_[0]->DropFirstPayloadArg();
}

# Legacy method name for backward compatibility
sub prepend_arg_to_payload {
    return $_[0]->PrependArgToPayload($_[1]);
}

# ToString method - matches C# ToString
sub ToString {
    my ($self) = @_;
    eval {
        my $result = "RuntimeName " . $self->{runtime} . " ";
        $result .= "CommandType " . $self->{command_type} . " ";
        $result .= "Payload ";
        
        my $payload_ref = $self->{payload};
        my @payload = @$payload_ref;
        my $len = @payload;
        
        for (my $i = 0; $i < $len; $i++) {
            my $item = $payload[$i];
            $result .= defined $item ? $item : "null";
            
            if ($i < $len - 1) {
                $result .= " ";
            }
        }
        
        return $result;
    };
    if ($@) {
        return "Error while converting command to string: " . $@;
    }
}

no Moose;

1;

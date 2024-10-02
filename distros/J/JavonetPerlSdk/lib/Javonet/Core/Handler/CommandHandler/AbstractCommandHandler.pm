package Javonet::Core::Handler::CommandHandler::AbstractCommandHandler;
use strict;
use warnings FATAL => 'all';
use Moose;
use Scalar::Util qw( blessed );
use Attribute::Abstract;


sub new {
    my $class = shift;
    my $self = {
        required_parameters_count  => 0
    };
    return bless $self, $class;
}


sub handle_command {
    my ($self, $command) = @_;
    iterate($command);
    return $self->process($command);
}

sub iterate {
    my $command = shift;
    my $payload_ref = $command->{payload};
    my @payload_array = @$payload_ref;
    my $length = @payload_array;
    for (my $i=0; $i< $length; $i++){
        my $payload_item = $command->{payload}[$i];
        if(blessed($payload_item) and $payload_item->isa('Javonet::Sdk::Core::PerlCommand')
            and !($payload_item->{command_type} eq Javonet::Sdk::Core::PerlCommandType::get_command_type('Value'))) {
            $command->{payload}[$i] = Javonet::Core::Handler::HandlerDictionary::get_handler(
                $command->{payload}[$i]->{command_type})->handle_command($command->{payload}[$i]
            );
        }
        if(blessed($payload_item) and $payload_item->isa('Javonet::Sdk::Core::PerlCommand')
            and $payload_item->{command_type} eq Javonet::Sdk::Core::PerlCommandType::get_command_type('Value')) {
            $command->{payload}[$i] = $payload_item->{payload}[0];
        }
    }
}

sub process : Abstract;


no Moose;
1;
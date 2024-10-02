package Javonet::Core::Handler::CommandHandler::SetStaticFieldHandler;
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
        required_parameters_count => 3
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
            die Exception->new("Exception: SetStaticField parameters mismatch");
        }
        my $class_name = $command->{payload}[0];
        my $static_field_name = $command->{payload}[1];
        my $new_value = $command->{payload}[2];

        no strict 'refs';
        ${"${class_name}::${static_field_name}"} = $new_value;

        return 0;
    }
    catch ($e){
        return Exception->new($e);
    }
}

no Moose;
1;

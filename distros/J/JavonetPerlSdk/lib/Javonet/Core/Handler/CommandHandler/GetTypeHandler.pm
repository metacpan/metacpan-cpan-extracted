package Javonet::Core::Handler::CommandHandler::GetTypeHandler;
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
        required_parameters_count => 1
    };
    return bless $self, $class;
}

sub process {
    my ($self, $command) = @_;
    try {
        my $current_payload_ref = $command->{payload};
        my @cur_payload = @$current_payload_ref;
        my $parameters_length = @cur_payload;
        if ($parameters_length != $self->{required_parameters_count}) {
            die Exception->new("Exception: GetTypeHandler parameters mismatch");
        }
        my $class_name = $command->{payload}[0];

        no strict 'refs';
        eval("use $class_name;");
        my $var = ${class_name};
        return $var;
    }
    catch ($e){
        return Exception->new($e);
    }
}

no Moose;
1;

package Javonet::Core::Handler::CommandHandler::DestructReferenceHandler;
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
        # my $current_payload_ref = $command->{payload};
        # my @cur_payload = @$current_payload_ref;
        # my $parameters_length = @cur_payload;
        # if ($parameters_length < $self->{required_parameters_count}){
        #     die Exception->new("Exception: DestructReferenceHandler parameters mismatch");
        # }
        # my $reference_guid = $command->{payload}[0];
        # my $reference_cache = ReferencesCache->new();
        # $reference_cache->delete_reference($reference_guid);

        return 0;
    }
    catch ($e){
        return Exception->new($e);
    }
}

no Moose;
1;

package Javonet::Core::Handler::CommandHandler::ResolveInstanceHandler;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;
use Nice::Try;
use aliased 'Javonet::Core::Exception::Exception' => 'Exception';
use aliased 'Javonet::Core::Handler::ReferencesCache' => 'ReferencesCache', qw(get_instance resolve_reference);
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
        if ($parameters_length < $self->{required_parameters_count}) {
            die Exception->new("Exception: ResolveInstance parameters mismatch");
        }
        my $reference_cache = ReferencesCache->new();
        my $resolved_reference = $reference_cache->resolve_reference($command);
        return $resolved_reference;
    }
    catch ($e){
        return Exception->new($e);
    }
}
1;
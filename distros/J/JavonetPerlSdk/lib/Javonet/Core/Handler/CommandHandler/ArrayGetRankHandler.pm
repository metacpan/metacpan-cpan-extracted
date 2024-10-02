package Javonet::Core::Handler::CommandHandler::ArrayGetRankHandler;
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
        die Exception->new("ArrayGetRankHandler not implemented");
    }
    catch ( $e ) {
        return Exception->new($e);
    }
}

no Moose;
1;

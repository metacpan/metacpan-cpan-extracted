package Javonet::Core::Handler::CommandHandler::CastingHandler;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;
use Nice::Try;
use aliased 'Javonet::Core::Exception::Exception' => 'Exception';
extends 'Javonet::Core::Handler::CommandHandler::AbstractCommandHandler';

sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub process {
    die Exception->new("Explicit cast is forbidden in dynamically typed languages");
}


no Moose;
1;
package Javonet::Core::Handler::HandlerDictionary;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;

our %handler_dict;

sub add_handler_to_dict {
    my $command_type = shift;
    my $handler = shift;
    $handler_dict{$command_type} = $handler;
}

sub get_handler {
    my $command_type = shift;
    my $handler = $handler_dict{$command_type};
    return $handler;
}

no Moose;
1;
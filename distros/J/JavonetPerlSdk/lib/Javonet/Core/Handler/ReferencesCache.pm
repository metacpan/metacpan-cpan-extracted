package Javonet::Core::Handler::ReferencesCache;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Exporter;
use Moose;
use Data::UUID;
use feature 'state';

our %reference_cache;
my $ug    = Data::UUID->new;

sub new {
    my ($class) = @_;
    state $instance;

    if (! defined $instance) {
        $instance = bless {}, $class;
    }
    return $instance;
}

sub cache_reference{
    my ($self, $object_reference) = @_;
    my $uuid = $ug->create_str();
    my $guid = $uuid;
    $reference_cache{$guid} = $object_reference;
    return $guid;
}

sub resolve_reference{
    my ($self, $perl_command) = @_;
    return $reference_cache{$perl_command->{payload}[0]}
}

sub delete_reference{
    my ($self, $perl_command) = @_;
    delete $reference_cache{$perl_command->{payload}[0]};
}


no Moose;
1;
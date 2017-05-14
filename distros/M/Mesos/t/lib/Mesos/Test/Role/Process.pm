package Mesos::Test::Role::Process;
use Symbol;
use Moo::Role;
use strict;
use warnings;

use Mesos::Channel::Pipe;

has channel => (
    is      => 'ro',
    default => sub { Mesos::Channel::Pipe->new },
);

has return => (
    is      => 'rw',
    default => sub { {} },
);

sub create_method {
    my ($self, $method, $code) = @_;
    my $package = ref $self || $self;
    no strict 'refs';
    *{qualify($method, ref $self)} = $code;
}

our $AUTOLOAD;
sub AUTOLOAD {
    (my $method = $AUTOLOAD) =~ s{.*::}{};
    my ($self, @args) = @_;
    $self->return->{$method} = \@args;
}

1;

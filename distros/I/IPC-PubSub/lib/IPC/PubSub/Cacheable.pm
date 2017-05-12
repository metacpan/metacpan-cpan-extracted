package IPC::PubSub::Cacheable;
use strict;
use warnings;
use Scalar::Util qw( refaddr );

my %Cache;
sub new {
    my $class = shift;
    my $self  = bless(\@_, $class);
    $self->BUILD;
    return $self;
}

sub BUILD {
    my $self    = shift;
    $Cache{ refaddr($self) } ||= do {
        require "IPC/PubSub/Cache/$self->[0].pm";
        "IPC::PubSub::Cache::$self->[0]"->new(@{$self->[1]});
    };
}

sub AUTOLOAD {
    no strict 'refs';
    no warnings 'uninitialized';

    my $meth    = (substr(our $AUTOLOAD, rindex($AUTOLOAD, '::') + 2) || $AUTOLOAD);
    my $code    = sub {
        my $self    = shift;
        my $cache   = $self->BUILD;
        unshift @_, $cache;
        goto &{$cache->can($meth)};
    };
    *$meth = $code;
    goto &$code;
}

sub DESTROY {
    my $self = shift;
    delete $Cache{ refaddr($self) };
}

1;

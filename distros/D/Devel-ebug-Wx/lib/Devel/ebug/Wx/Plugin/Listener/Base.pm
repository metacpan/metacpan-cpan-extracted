package Devel::ebug::Wx::Plugin::Listener::Base;

use strict;
use base qw(Class::Accessor::Fast);
use Scalar::Util qw(weaken);

__PACKAGE__->mk_accessors( qw(_subscribed) );

sub add_subscription {
    my( $self, $source, @args ) = @_;

    $self->_subscribed( [] ) unless $self->_subscribed;
    $source->add_subscriber( @args );
    push @{$self->_subscribed}, [ $source, @args ];
    foreach my $ref ( @{$self->_subscribed->[-1]} ) {
        next unless ref $ref;
        weaken( $ref );
    }
}

sub delete_subscriptions {
    my( $self ) = @_;

    foreach my $sub ( @{$self->_subscribed || []} ) {
        next unless $sub->[0] && $sub->[1]; # might have been destroyed
        $sub->[0]->delete_subscriber( @$sub[1 .. $#$sub] );
    }
    $self->_subscribed( undef );
}

1;

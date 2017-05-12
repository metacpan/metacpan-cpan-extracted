package Devel::ebug::Wx::Plugin::Configurable::Base;

use strict;
use base qw(Class::Accessor::Fast Class::Publisher
            Devel::ebug::Wx::Plugin::Listener::Base);

sub register_configurable {
    my( $self ) = @_;

    $self->add_subscription
        ( ref( $self ), 'configuration_changed',
          sub { $self->configuration_changed( $_[2] ) } );
}

sub configuration_changed {
    my( $self, $data ) = @_;

    $self->apply_configuration( $data );
}

sub set_configuration {
    my( $class, $sm, $data ) = @_;
    my $cfg = $sm->get_service( 'configuration' )
                 ->get_config( $data->{section} );

    foreach my $key ( @{$data->{keys}} ) {
        $cfg->set_value( $key->{key}, $key->{value} );
    }
    $class->notify_subscribers( 'configuration_changed', $data );
}

sub get_configuration {
    my( $class, $sm ) = @_;
    my $keys = $class->get_configuration_keys;
    my $cfg = $sm->get_service( 'configuration' )
                 ->get_config( $keys->{section} );
    my $use_defaults = 1;

    foreach my $key ( @{$keys->{keys}} ) {
        $key->{value} = $cfg->get_value( $key->{key} ),
        $use_defaults &&= !defined $key->{value};
    }
    if( $use_defaults ) {
        foreach my $key ( @{$keys->{keys}} ) {
            $key->{value} = $key->{default};
        }
    }

    return $keys;
}

1;

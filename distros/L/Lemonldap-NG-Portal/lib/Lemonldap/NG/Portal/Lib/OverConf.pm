package Lemonldap::NG::Portal::Lib::OverConf;

use Mouse::Role;

# To avoid "tied" destroy, tied configurations are kept here
our @overC;

# Override portal loadPlugin() to use a wrapped configuration
sub loadPlugin {
    my ( $self, $plugin, $over ) = @_;
    my $obj = $self->loadModule( $plugin, $over );
    return 0
      unless ( $obj and $obj = $self->p->findEP( $plugin, $obj ) );
    return $obj;
}

sub loadModule {
    my ( $self, $plugin, $over ) = @_;
    my $obj;
    my $nc;
    if ($over) {
        require Lemonldap::NG::Common::Conf::Wrapper;
        tie %$nc, 'Lemonldap::NG::Common::Conf::Wrapper', $self->conf, $over;
        push @overC, $nc;
    }
    else {
        $nc = $self->conf;
    }
    return 0
      unless ( $obj = $self->p->loadModule( "$plugin", $nc ) );
    return $obj;
}

1;

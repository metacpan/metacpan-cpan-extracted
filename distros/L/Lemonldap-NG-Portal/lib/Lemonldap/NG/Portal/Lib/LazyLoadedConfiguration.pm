package Lemonldap::NG::Portal::Lib::LazyLoadedConfiguration;
use Mouse::Role;

requires qw(load_config);

has config_expires_at => ( is => 'rw', default => sub { {} } );
has config_is_loaded  => ( is => 'rw', default => sub { {} } );
has config_info       => ( is => 'rw', default => sub { {} } );

sub lazy_load_config {
    my ( $self, $config_name ) = @_;

    my $expires_at = $self->config_expires_at->{$config_name};
    my $is_loaded  = $self->config_is_loaded->{$config_name};
    if ( $is_loaded and ( not defined $expires_at or time < $expires_at ) ) {

        # Already loaded, nothing to do
        $self->logger->debug("Config for $config_name is already loaded");
        return $self->config_info->{$config_name};
    }
    else {
        $self->logger->debug("Reloading config for $config_name");
        my $config_result = $self->load_config($config_name);
        if ($config_result) {
            $self->config_is_loaded->{$config_name} = 1;
            my $ttl = $config_result->{ttl};
            if ( defined $ttl ) {
                my $will_expire_at = time + $ttl;
                $self->config_expires_at->{$config_name} = $will_expire_at;
                $self->logger->debug(
"Config for $config_name will be valid until $will_expire_at"
                );
            }
            my $info = $config_result->{info};
            $self->config_info->{$config_name} = $info if $info;
            return $info;
        }
        return;
    }
}
1;

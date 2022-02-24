package Lemonldap::NG::Portal::Lib::CustomModule;

# Fake 'new' method here
sub new {
    my ( $class, $self ) = @_;

    my $configKey = $class->custom_config_key;
    my $name      = $class->custom_name;

    my $module = $self->{conf}->{$configKey};
    unless ($module) {
        die "Custom $name module not defined";
    }

    $module = "Lemonldap::NG::Portal$module" if ( $module =~ /^::/ );

    eval "require $module";
    if ($@) {
        die "Custom $name module failed to compile: $@";
    }

    my $obj = eval { $module->new($self); };
    if ($@) {
        die "Custom $name module failed to create instance: $@";
    }

    $self->{p}->logger->debug("Custom $name module loaded");
    return $obj;
}
1;

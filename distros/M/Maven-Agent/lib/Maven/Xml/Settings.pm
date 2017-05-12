use strict;
use warnings;

package Maven::Xml::Settings;
$Maven::Xml::Settings::VERSION = '1.14';
# ABSTRACT: Maven Settings element
# PODNAME: Maven::Xml::Settings

use Maven::Xml::Common::BaseProfile;
use Maven::Xml::Common::Configuration;
use Maven::Xml::Common::Repository;

use parent qw(Maven::Xml::XmlFile);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
    qw(
        localRepository
        interactiveMode
        usePluginRegistry
        offline
        settings
        proxies
        servers
        mirrors
        profiles
        activeProfiles
        pluginGroups
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'settings' );
    return if ( $name eq 'proxies' );
    return if ( $name eq 'servers' );
    return if ( $name eq 'mirrors' );
    return if ( $name eq 'profiles' );
    return if ( $name eq 'activeProfiles' );
    return if ( $name eq 'pluginGroups' );

    if ( $name eq 'proxy' ) {
        push( @{ $self->{proxies} }, $value );
    }
    elsif ( $name eq 'server' ) {
        push( @{ $self->{servers} }, $value );
    }
    elsif ( $name eq 'mirror' ) {
        push( @{ $self->{mirrors} }, $value );
    }
    elsif ( $name eq 'profile' ) {
        push( @{ $self->{profiles} }, $value );
    }
    elsif ( $name eq 'activeProfile' ) {
        push( @{ $self->{activeProfiles} }, $value );
    }
    elsif ( $name eq 'pluginGroup' ) {
        push( @{ $self->{pluginGroups} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'proxy' ) {
        return Maven::Xml::Settings::Proxy->new();
    }
    elsif ( $name eq 'server' ) {
        return Maven::Xml::Settings::Server->new();
    }
    elsif ( $name eq 'mirror' ) {
        return Maven::Xml::Settings::Mirror->new();
    }
    elsif ( $name eq 'profile' ) {
        return Maven::Xml::Settings::Profile->new();
    }
    return $self;
}

package Maven::Xml::Settings::Proxy;
$Maven::Xml::Settings::Proxy::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        active
        protocol
        username
        password
        port
        host
        nonProxyHosts
        id
        )
);

package Maven::Xml::Settings::Server;
$Maven::Xml::Settings::Server::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        username
        password
        privateKey
        passphrase
        filePermissions
        directoryPermissions
        configuration
        id
        )
);

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'configuration' ) {
        return Maven::Xml::Common::Configuration->new();
    }
    return $self;
}

package Maven::Xml::Settings::Mirror;
$Maven::Xml::Settings::Mirror::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        mirrorOf
        name
        url
        layout
        mirrorOfLayouts
        id
        )
);

package Maven::Xml::Settings::Profile;
$Maven::Xml::Settings::Profile::VERSION = '1.14';
use parent qw(Maven::Xml::Common::BaseProfile);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        properties
        )
);

sub _get_parser {
    my ( $self, $name ) = @_;

    if ( $name eq 'properties' ) {
        return Maven::Xml::Settings::Profile::Properties->new();
    }

    return $self->Maven::Xml::Common::BaseProfile::_get_parser($name);
}

package Maven::Xml::Settings::Profile::Properties;
$Maven::Xml::Settings::Profile::Properties::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;

1;

__END__

=pod

=head1 NAME

Maven::Xml::Settings - Maven Settings element

=head1 VERSION

version 1.14

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Maven::Agent|Maven::Agent>

=back

=cut

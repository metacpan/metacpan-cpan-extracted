use strict;
use warnings;

package Maven::Xml::Pom::BaseBuild;
$Maven::Xml::Pom::BaseBuild::VERSION = '1.15';
# ABSTRACT: Maven BaseBuild element
# PODNAME: Maven::Xml::Pom::BaseBuild

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        defaultGoal
        directory
        finalName
        filters
        resources
        testResources
        plugins
        pluginManagement
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'filters' );
    return if ( $name eq 'resources' );
    return if ( $name eq 'testResources' );

    if ( $name eq 'filter' ) {
        push( @{ $self->{filters} }, $value );
    }
    elsif ( $name eq 'resource' ) {
        push( @{ $self->{resources} }, $value );
    }
    elsif ( $name eq 'testResource' ) {
        push( @{ $self->{testResources} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'resource' ) {
        return Maven::Xml::Pom::BaseBuild::Resource->new();
    }
    elsif ( $name eq 'testResource' ) {
        return Maven::Xml::Pom::BaseBuild::Resource->new();
    }
    elsif ( $name eq 'plugins' ) {
        return Maven::Xml::Pom::BaseBuild::Plugins->new();
    }
    elsif ( $name eq 'pluginManagement' ) {
        return Maven::Xml::Pom::BaseBuild::PluginManagement->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::BaseBuild::Resource;
$Maven::Xml::Pom::BaseBuild::Resource::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        targetPath
        filtering
        directory
        includes
        excludes
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'includes' );
    return if ( $name eq 'excludes' );

    if ( $name eq 'include' ) {
        push( @{ $self->{includes} }, $value );
    }
    elsif ( $name eq 'exclude' ) {
        push( @{ $self->{excludes} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

package Maven::Xml::Pom::BaseBuild::Plugins;
$Maven::Xml::Pom::BaseBuild::Plugins::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;

sub _add_value {
    my ( $self, $name, $value ) = @_;

    if ( $name eq 'plugin' ) {
        $self->{ $value->_key($name) } = $value;
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'plugin' ) {
        return Maven::Xml::Pom::BaseBuild::Plugin->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::BaseBuild::Plugin;
$Maven::Xml::Pom::BaseBuild::Plugin::VERSION = '1.15';
use Maven::Xml::Pom::Dependencies;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        groupId
        artifactId
        version
        extensions
        inherited
        configuration
        dependencies
        executions
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'executions' );

    if ( $name eq 'execution' ) {
        push( @{ $self->{executions} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'configuration' ) {
        return Maven::Xml::Common::Configuration->new();
    }
    elsif ( $name eq 'dependencies' ) {
        return Maven::Xml::Pom::Dependencies->new();
    }
    elsif ( $name eq 'execution' ) {
        return Maven::Xml::Pom::BaseBuild::Plugin::Execution->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

sub _key {
    my ( $self, $default ) = @_;
    return join( ':', $self->{groupId} || '', $self->{artifactId} );
}

package Maven::Xml::Pom::BaseBuild::Plugin::Execution;
$Maven::Xml::Pom::BaseBuild::Plugin::Execution::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        id
        goals
        phase
        inherited
        configuration
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'goals' );

    if ( $name eq 'goal' ) {
        push( @{ $self->{goals} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'configuration' ) {
        return Maven::Xml::Common::Configuration->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::BaseBuild::PluginManagement;
$Maven::Xml::Pom::BaseBuild::PluginManagement::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        plugins
        )
);

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'plugins' ) {
        return Maven::Xml::Pom::BaseBuild::Plugins->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::BaseBuild - Maven BaseBuild element

=head1 VERSION

version 1.15

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

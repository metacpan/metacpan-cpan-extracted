use strict;
use warnings;

package Maven::Xml::Pom::Dependencies;
$Maven::Xml::Pom::Dependencies::VERSION = '1.14';
# ABSTRACT: Maven Dependencies element
# PODNAME: Maven::Xml::Pom::Dependencies

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;

sub _add_value {
    my ( $self, $name, $value ) = @_;

    if ( $name eq 'dependency' ) {
        $self->{ $value->_key($name) } = $value;
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'dependency' ) {
        return Maven::Xml::Pom::Dependency->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::Dependency;
$Maven::Xml::Pom::Dependency::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        artifactId
        classifier
        exclusions
        groupId
        optional
        scope
        systemPath
        type
        version
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'exclusions' );

    if ( $name eq 'exclusion' ) {
        push( @{ $self->{exclusions} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'exclusion' ) {
        return Maven::Xml::Pom::Dependency::Exclusion->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

sub _key {
    my ( $self, $default ) = @_;
    return join( ':',
        $self->{groupId}, $self->{artifactId},
        ( $self->{type} || 'jar' ),
        ( $self->{classifier} || '' ) );
}

package Maven::Xml::Pom::Dependency::Exclusion;
$Maven::Xml::Pom::Dependency::Exclusion::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        groupId
        artifactId
        )
);

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::Dependencies - Maven Dependencies element

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

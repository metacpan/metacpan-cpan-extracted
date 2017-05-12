use strict;
use warnings;

package Maven::Xml::Pom::Contributor;
$Maven::Xml::Pom::Contributor::VERSION = '1.14';
# ABSTRACT: Maven Contributor element
# PODNAME: Maven::Xml::Pom::Contributor

use Maven::Xml::Common::Properties;

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        name
        email
        url
        organization
        organizationUrl
        roles
        timezone
        properties
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'roles' );

    if ( $name eq 'role' ) {
        push( @{ $self->{roles} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'properties' ) {
        return Maven::Xml::Common::Properties->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::Contributor - Maven Contributor element

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

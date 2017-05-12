use strict;
use warnings;

package Maven::Xml::Pom::CiManagement;
$Maven::Xml::Pom::CiManagement::VERSION = '1.14';
# ABSTRACT: Maven CiManagement element
# PODNAME: Maven::Xml::Pom::CiManagement

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        system
        url
        notifiers
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'notifiers' );

    if ( $name eq 'notifier' ) {
        push( @{ $self->{notifiers} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'notifier' ) {
        return Maven::Xml::Pom::CiManagement::Notifier->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::CiManagement::Notifier;
$Maven::Xml::Pom::CiManagement::Notifier::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        type
        sendOnError
        sendOnFailure
        sendOnSuccess
        sendOnWarning
        configuration
        )
);

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'configuration' ) {
        return Maven::Xml::Common::Configuration->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::CiManagement - Maven CiManagement element

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

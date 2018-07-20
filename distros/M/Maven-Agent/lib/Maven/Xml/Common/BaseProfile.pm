use strict;
use warnings;

package Maven::Xml::Common::BaseProfile;
$Maven::Xml::Common::BaseProfile::VERSION = '1.15';
# ABSTRACT: Maven BaseProfile element
# PODNAME: Maven::Xml::Common::BaseProfile

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        activation
        id
        pluginRepositories
        properties
        repositories
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'profile' );
    return if ( $name eq 'repositories' );
    return if ( $name eq 'pluginRepositories' );

    if ( $name eq 'repository' ) {
        push( @{ $self->{repositories} }, $value );
    }
    elsif ( $name eq 'pluginRepository' ) {
        push( @{ $self->{pluginRepositories} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'activation' ) {
        return Maven::Xml::Common::BaseProfile::Activation->new();
    }
    if ( $name eq 'properties' ) {
        return Maven::Xml::Common::Properties->new();
    }
    if ( $name eq 'repository' ) {
        return Maven::Xml::Common::Repository->new();
    }
    if ( $name eq 'pluginRepository' ) {
        return Maven::Xml::Common::Repository->new();
    }
    return $self;
}

package Maven::Xml::Common::BaseProfile::Activation;
$Maven::Xml::Common::BaseProfile::Activation::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        activeByDefault
        file
        jdk
        os
        property
        )
);

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'os' ) {
        return Maven::Xml::Common::BaseProfile::Activation::Os->new();
    }
    if ( $name eq 'property' ) {
        return Maven::Xml::Common::BaseProfile::Activation::Property->new();
    }
    if ( $name eq 'file' ) {
        return Maven::Xml::Common::BaseProfile::Activation::File->new();
    }
    return $self;
}

package Maven::Xml::Common::BaseProfile::Activation::Os;
$Maven::Xml::Common::BaseProfile::Activation::Os::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        arch
        name
        family
        version
        )
);

package Maven::Xml::Common::BaseProfile::Activation::Property;
$Maven::Xml::Common::BaseProfile::Activation::Property::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        name
        value
        )
);

package Maven::Xml::Common::BaseProfile::Activation::File;
$Maven::Xml::Common::BaseProfile::Activation::File::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        exists
        missing
        )
);

1;

__END__

=pod

=head1 NAME

Maven::Xml::Common::BaseProfile - Maven BaseProfile element

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

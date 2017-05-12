use strict;
use warnings;

package Maven::Xml::Pom::Reporting;
$Maven::Xml::Pom::Reporting::VERSION = '1.14';
# ABSTRACT: Maven Reporting element
# PODNAME: Maven::Xml::Pom::Reporting

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        outputDirectory
        plugins
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'plugins' );

    if ( $name eq 'plugin' ) {
        push( @{ $self->{plugins} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;

    if ( $name eq 'plugin' ) {
        return Maven::Xml::Pom::Reporting::Plugin->new();
    }

    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::Reporting::Plugin;
$Maven::Xml::Pom::Reporting::Plugin::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        artifactId
        version
        reportSets
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'reportSets' );

    if ( $name eq 'reportSet' ) {
        push( @{ $self->{reportSets} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'reportSet' ) {
        return Maven::Xml::Pom::Reporting::Plugin::ReportSet->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::Reporting::Plugin::ReportSet;
$Maven::Xml::Pom::Reporting::Plugin::ReportSet::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        id
        reports
        inherited
        configuration
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'reports' );

    if ( $name eq 'report' ) {
        push( @{ $self->{reports} }, $value );
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

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::Reporting - Maven Reporting element

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

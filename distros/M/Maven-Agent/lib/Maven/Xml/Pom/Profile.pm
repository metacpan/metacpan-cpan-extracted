use strict;
use warnings;

package Maven::Xml::Pom::Profile;
$Maven::Xml::Pom::Profile::VERSION = '1.14';
# ABSTRACT: Maven Profile element
# PODNAME: Maven::Xml::Pom::Profile

use parent qw(Maven::Xml::Common::BaseProfile);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        build
        dependencies
        dependencyManagement
        distributionManagement
        modules
        reporting
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'dependencies' );
    return if ( $name eq 'modules' );

    if ( $name eq 'dependency' ) {
        push( @{ $self->{dependencies} }, $value );
    }
    elsif ( $name eq 'module' ) {
        push( @{ $self->{modules} }, $value );
    }
    else {
        $self->Maven::Xml::Common::BaseProfile::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;

    if ( $name eq 'build' ) {
        return Maven::Xml::Pom::BaseBuild->new();
    }
    elsif ( $name eq 'dependency' ) {
        return Maven::Xml::Pom::Dependency->new();
    }
    elsif ( $name eq 'dependencyManagement' ) {
        return Maven::Xml::Pom::DependencyManagement->new();
    }
    elsif ( $name eq 'distributionManagement' ) {
        return Maven::Xml::Pom::DistributionManagement->new();
    }
    elsif ( $name eq 'module' ) {
        return Maven::Xml::Pom::Module->new();
    }
    elsif ( $name eq 'reporting' ) {
        return Maven::Xml::Pom::Reporting->new();
    }

    return $self->Maven::Xml::Common::BaseProfile::_get_parser($name);
}

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::Profile - Maven Profile element

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

use strict;
use warnings;

package Maven::Xml::Pom::Build;
$Maven::Xml::Pom::Build::VERSION = '1.15';
# ABSTRACT: Maven Build element
# PODNAME: Maven::Xml::Pom::Build

use parent qw(Maven::Xml::Pom::BaseBuild);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        sourceDirectory
        scriptSourceDirectory
        testSourceDirectory
        outputDirectory
        testOutputDirectory
        extensions
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'extensions' );

    if ( $name eq 'extension' ) {
        push( @{ $self->{extensions} }, $value );
    }
    else {
        $self->Maven::Xml::Pom::BaseBuild::_add_value( $name, $value );
    }
}

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'extension' ) {
        return Maven::Xml::Pom::Build::Extension->new();
    }
    return $self->Maven::Xml::Pom::BaseBuild::_get_parser($name);
}

package Maven::Xml::Pom::Build::Extension;
$Maven::Xml::Pom::Build::Extension::VERSION = '1.15';
use parent qw(Maven::Xml::Pom::BaseBuild);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        groupId
        artifactId
        version
        )
);

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::Build - Maven Build element

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

use strict;
use warnings;

package Maven::Xml::Pom::DistributionManagement;
$Maven::Xml::Pom::DistributionManagement::VERSION = '1.15';
# ABSTRACT: Maven DistributionManagement element
# PODNAME: Maven::Xml::Pom::DistributionManagement

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        repository
        snapshotRepository
        site
        relocation
        downloadUrl
        status
        )
);

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'repository' ) {
        return Maven::Xml::Pom::DistributionManagement::Repository->new();
    }
    elsif ( $name eq 'snapshotRepository' ) {
        return Maven::Xml::Pom::DistributionManagement::Repository->new();
    }
    elsif ( $name eq 'site' ) {
        return Maven::Xml::Pom::DistributionManagement::Site->new();
    }
    elsif ( $name eq 'relocation' ) {
        return Maven::Xml::Pom::DistributionManagement::Relocation->new();
    }
    return $self->Maven::Xml::XmlNodeParser::_get_parser($name);
}

package Maven::Xml::Pom::DistributionManagement::Repository;
$Maven::Xml::Pom::DistributionManagement::Repository::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        id
        name
        uniqueVersion
        url
        layout
        )
);

package Maven::Xml::Pom::DistributionManagement::Site;
$Maven::Xml::Pom::DistributionManagement::Site::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        id
        name
        url
        )
);

package Maven::Xml::Pom::DistributionManagement::Relocation;
$Maven::Xml::Pom::DistributionManagement::Relocation::VERSION = '1.15';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        groupId
        artifactId
        version
        message
        )
);

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::DistributionManagement - Maven DistributionManagement element

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

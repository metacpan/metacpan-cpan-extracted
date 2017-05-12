use strict;
use warnings;

package Maven::Xml::Common::Repository;
$Maven::Xml::Common::Repository::VERSION = '1.14';
# ABSTRACT: Maven Repositories element
# PODNAME: Maven::Xml::Common::Repository

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        releases
        snapshots
        id
        name
        url
        layout
        )
);

sub _get_parser {
    my ( $self, $name ) = @_;
    if ( $name eq 'releases' ) {
        return Maven::Xml::Common::Repository::RepositoryPolicy->new();
    }
    if ( $name eq 'snapshots' ) {
        return Maven::Xml::Common::Repository::RepositoryPolicy->new();
    }
    return $self;
}

package Maven::Xml::Common::Repository::RepositoryPolicy;
$Maven::Xml::Common::Repository::RepositoryPolicy::VERSION = '1.14';
use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        enabled
        updatePolicy
        checksumPolicy
        )
);

1;

__END__

=pod

=head1 NAME

Maven::Xml::Common::Repository - Maven Repositories element

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

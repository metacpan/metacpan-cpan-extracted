use strict;
use warnings;

package Maven::Xml::Pom::MailingList;
$Maven::Xml::Pom::MailingList::VERSION = '1.14';
# ABSTRACT: Maven MailingList element
# PODNAME: Maven::Xml::Pom::MailingList

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        name
        subscribe
        unsubscribe
        post
        archive
        otherArchives
        )
);

sub _add_value {
    my ( $self, $name, $value ) = @_;

    return if ( $name eq 'otherArchives' );

    if ( $name eq 'otherArchive' ) {
        push( @{ $self->{otherArchives} }, $value );
    }
    else {
        $self->Maven::Xml::XmlNodeParser::_add_value( $name, $value );
    }
}

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::MailingList - Maven MailingList element

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

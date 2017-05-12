use strict;
use warnings;

package Maven::Xml::Pom::License;
$Maven::Xml::Pom::License::VERSION = '1.14';
# ABSTRACT: Maven License element
# PODNAME: Maven::Xml::Pom::License

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(
        name
        url
        distribution
        comments
        )
);

1;

__END__

=pod

=head1 NAME

Maven::Xml::Pom::License - Maven License element

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

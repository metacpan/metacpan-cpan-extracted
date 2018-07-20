use strict;
use warnings;

package Maven::Xml::Common::Properties;
$Maven::Xml::Common::Properties::VERSION = '1.15';
# ABSTRACT: Maven Properties element
# PODNAME: Maven::Xml::Common::Properties

use parent qw(Maven::Xml::XmlNodeParser);
__PACKAGE__->follow_best_practice;

1;

__END__

=pod

=head1 NAME

Maven::Xml::Common::Properties - Maven Properties element

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

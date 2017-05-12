=head1 NAME

DynGig::RCE - Remote Code Execution

=cut
package DynGig::RCE;

=head1 VERSION

Version 1.00

=cut
our $VERSION = '1.01';

=head1 MODULES

=head2 DynGig::RCE::Server 

RCE server. Extends DynGig::Util::TCPServer.

=head2 DynGig::RCE::Client 

RCE client. Extends DynGig::Multiplex::TCP.

=head2 DynGig::RCE::Access 

Process access policy for RCE server

=head2 DynGig::RCE::Code 

Process plug-in for RCE server

=head2 DynGig::RCE::Query 

Process query for RCE server/client

=head1 AUTHOR

Kan Liu

=head1 COPYRIGHT and LICENSE

Copyright (c) 2010. Kan Liu

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__

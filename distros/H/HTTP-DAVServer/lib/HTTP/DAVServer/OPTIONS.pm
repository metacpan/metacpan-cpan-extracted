

package HTTP::DAVServer::OPTIONS;

our $VERSION=0.1;

use strict;
use warnings;

=head1 NAME

HTTP::DAVServer::OPTIONS - Implements the OPTIONS method

=cut


sub handle {

    my ($self, $r, $url, $responder, $request) = @_;

    $responder->notImplemented( $r );

}


=head1 SUPPORT

For technical support please email to jlawrenc@cpan.org ... 
for faster service please include "HTTP::DAVServer" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.ca/

=head1 COPYRIGHT

Copyright (c) 2003 Jay J. Lawrence, Infonium Inc. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

Thank you to the authors of my prequisite modules. With out your help this code
would be much more difficult to write!

 XML::Simple - Grant McLean
 XML::SAX    - Matt Sergeant
 DateTime    - Dave Rolsky

Also the authors of litmus, a very helpful tool indeed!

=head1 SEE ALSO

HTTP::DAV, HTTP::Webdav, http://www.webdav.org/, RFC 2518

=cut

1;


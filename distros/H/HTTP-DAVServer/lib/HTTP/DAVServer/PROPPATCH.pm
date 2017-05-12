

package HTTP::DAVServer::PROPPATCH;

our $VERSION=0.1;

use strict;
use warnings;

=head1 NAME

HTTP::DAVServer::PROPPATCH - Implements the PROPPATCH method

=cut

use File::stat qw(stat);

sub handle {

    my ($self, $r, $url, $responder, $req) = @_;

    my $root = $HTTP::DAVServer::ROOT;
    my $host = $HTTP::DAVServer::HOST;


    my $xml .= qq(<response>\n<href>http://$host$url</href>\n<prop>\n);

    # Property names response
    if ( exists $req->{'{DAV:}set'} ) {

    }

    if ( exists $req->{'{DAV:}remove'} ) {

    }

    $xml .= "</response>\n";

    $responder->multiStatus( $r, $xml );

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


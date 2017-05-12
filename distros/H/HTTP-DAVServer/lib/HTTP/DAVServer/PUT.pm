

package HTTP::DAVServer::PUT;

our $VERSION=0.1;

use strict;
use warnings;

=head1 NAME

HTTP::DAVServer::PUT - Implements the PUT method

=cut

sub handle {

    my ($self, $r, $url, $responder, $request) = @_;

	my $fullpath = $HTTP::DAVServer::ROOT . $url;
    $url =~ m#^(.*)/([^/]+)$#;
    my $path     = $HTTP::DAVServer::ROOT . $1;
    my $file     = $2;

    if ( -d $fullpath ) {
        $responder->conflict( $r, "PUTONCOLL");
    }
    unless ( -d $path ) {
        $responder->conflict( $r, "PUTNODIR");
    }

    my $exists = -f $fullpath ? 1 : 0;

    # XXX Not checking for content-* headers => 501 Not Implemented error

    open FOUT, ">$fullpath" or $responder->forbidden( $r, "PUTDENY" );
    local undef $/;
    print FOUT <>;

    close FOUT or $responder->diskFull( $r, "PUTFULL" );

    if ($exists) {
        $responder->ok( $r, "PUT" );
    } else {
        $responder->created( $r, "PUT" );
    }


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


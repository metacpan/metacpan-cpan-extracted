

package HTTP::DAVServer::DELETE;

our $VERSION=0.1;

use strict;
use warnings;

=head1 NAME

HTTP::DAVServer::DELETE - Implements the DELETE method

=cut

sub handle {

    my ($self, $r, $url, $responder, $request) = @_;

	my $fullPath = $HTTP::DAVServer::ROOT . $url;
    $url =~ m#^(.*)/([^/]+)$#;
    my $path     = $HTTP::DAVServer::ROOT . $1;
    my $file     = $2;

    if ( -d $fullPath ) {
        $responder->multiStatus( $r, join "", deleteDir( $fullPath, $url ) );
    }

    if ( -f $fullPath ) {
        $responder->multiStatus( $r, deleteFile( $fullPath, $url ) );
    }

    $responder->notFound( $r );

}

sub deleteFile {

    my ( $fullpath, $url ) = @_;

    my $response = qq(<response>\n<href>$HTTP::DAVServer::HOST$url</href>\n);
    warn "DELETE $fullpath\n" if $HTTP::DAVServer::TRACE;
    unless (unlink $fullpath) {
        $response .= qq(<status>403 Forbidden</status>\n);
    }
    $response .= "</response>";

    return $response;

}

sub deleteDir {

    my ( $directory, $url ) = @_;

    my @responses=();
    opendir MYDIR, $directory;

    while (my $entry = readdir MYDIR) {

        next if $entry =~ /^\.\.?$/;

        if ( -f "$directory/$entry" ) {
            push @responses, deleteFile( "$directory/$entry", "$url/$entry" );
        } else {
            push @responses, deleteDir( "$directory/$entry", "$url/$entry" );
        }

    }

    my $response = qq(<response>\n<href>$HTTP::DAVServer::HOST$url</href>\n);
    my $resp=`rmdir $directory`;
    warn "DELETE $directory\n" if $HTTP::DAVServer::TRACE;
    $response .= "</response>";

    push @responses, $response;

    return @responses;

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


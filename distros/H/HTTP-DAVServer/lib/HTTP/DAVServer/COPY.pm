

package HTTP::DAVServer::COPY;

our $VERSION=0.1;

use strict;
use warnings;

use File::Copy qw(copy);

=head1 NAME

HTTP::DAVServer::COPY - Implements the COPY method

=cut


sub handle {

    my ($self, $r, $url, $responder, $request) = @_;

	my $fullPath = $HTTP::DAVServer::ROOT . $url;
    $url =~ m#^(.*)/([^/]+)$#;
    my $path     = $HTTP::DAVServer::ROOT . $1;
    my $file     = $2;
    my $dest     = $HTTP::DAVServer::ROOT . $ENV{'HTTP_DESTINATION'};

    if ( -d $fullPath ) {
        $responder->multiStatus( $r, join "", copyDir( $fullPath, $url, $dest) );
    }

    if ( -f $fullPath ) {
        $responder->multiStatus( $r, copyFile( $fullPath, $url, $dest ) );
    }

    $responder->notFound( $r );

}

sub copyFile {

    my ( $fullpath, $url, $dest ) = @_;

    my $response = qq(<response>\n<href>$HTTP::DAVServer::HOST$url</href>\n);
    warn "COPY $fullpath $dest\n" if $HTTP::DAVServer::TRACE;
    unless (copy $fullpath, $dest) {
        $response .= qq(<status>403 Forbidden</status>\n);
    }
    $response .= "</response>";

    return $response;

}

sub copyDir {

    my ( $directory, $url, $dest ) = @_;

    my @responses=();
    opendir MYDIR, $directory;

    while (my $entry = readdir MYDIR) {

        next if $entry =~ /^\.\.?$/;

        if ( -f "$directory/$entry" ) {
            push @responses, copyFile( "$directory/$entry", "$url/$entry", "$dest/$entry" );
        } else {
            push @responses, copyDir( "$directory/$entry", "$url/$entry", "$dest/$entry" );
        }

    }

    my $response = qq(<response>\n<href>$HTTP::DAVServer::HOST$url</href>\n);
    my $resp=mkdir $directory;
    warn "COPY $directory\n" if $HTTP::DAVServer::TRACE;
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



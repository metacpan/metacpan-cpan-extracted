

package HTTP::DAVServer::PROPFIND;

our $VERSION=0.1;

use strict;
use warnings;

=head1 NAME

HTTP::DAVServer::PROPFIND - Implements the PROPFIND method

=cut

use File::stat qw(stat);

our %fileProps = (
    creationdate       => 1,
    displayname        => 1,
    getcontentlanguage => 1,
    getcontentlength   => 1,
    getetag            => 1,
    getlastmodified    => 1,
    getcontenttype     => 1,
    lockdiscovery      => 1,
    resourcetype       => 1,
    source             => 1,
    supportedlock      => 1,
);

our %collProps = (
    creationdate  => 1,
    displayname   => 1,
    resourcetype  => 1,
    supportedlock => 1,
);

sub handle {

    my ($self, $r, $url, $responder, $req) = @_;

    $responder->badRequest( $r, "PROPFINDVAGUE" ) unless exists $req->{'{DAV:}prop'} 
                                            || exists $req->{'{DAV:}allprop'} 
                                            || exists $req->{'{DAV:}propname'};

    $url =~ s#/*$##;

    my $depth=$r->http('Depth');
       $depth="infinite" unless $depth =~ /^(0|1|infinite)$/;

    my $root = $HTTP::DAVServer::ROOT;
    my $host = $HTTP::DAVServer::HOST;


    # Property names response
    if ( exists $req->{'{DAV:}propname'} ) {

        my $xml="<response>";

        if ( $depth eq "0") {

            $xml .= qq(<propstat>\n<href>http://$host$url</href>\n<prop>\n);

            map { $xml .= qq(\t<$_/>\n) } keys %fileProps if -f "$root/$url";
            map { $xml .= qq(\t<$_/>\n) } keys %collProps if -d "$root/$url";

            if (-r "$root/$url") {
                $xml .= qq(</prop>\n<status>HTTP/1.1 200 OK</status>\n</propstat>\n);
            } else {
                $xml .= qq(</prop>\n<status>HTTP/1.1 404 Not Found</status>\n</propstat>\n);
            }

        } else {

            if ( -f "$root/$url" ) {
                $xml .= qq(<propstat>\n<href>http://$host$url</href>\n<prop>\n);
                map { $xml .= qq(\t<$_/>\n) } keys %fileProps;
                $xml .= qq(</prop>\n<status>HTTP/1.1 200 OK</status>\n</propstat>\n);
            } 

            if ( -d "$root/$url" ) {

                $xml .= qq(<propstat>\n<href>http://$host$url</href>\n<prop>\n);
                map { $xml .= qq(\t<$_/>\n) } keys %collProps;
                $xml .= qq(</prop>\n<status>HTTP/1.1 200 OK</status>\n</propstat>\n);

                opendir DIR, "$root/$url";
                while ( my $file = readdir DIR ) {
                    if (-f "$root/$url/$file") {
                        $xml .= qq(</response>\n<response>\n);
                        $xml .= qq(<propstat>\n<href>http://$host$url/$file</href>\n<prop>\n);
                        map { $xml .= qq(\t<$_/>\n) } keys %fileProps;
                        $xml .= qq(</prop>\n<status>HTTP/1.1 200 OK</status>\n</propstat>\n);
                        last;
                    }
                }
            }
        }

        $xml .= "</response>\n";

        $responder->multiStatus( $r, $xml );

    }


    my $reqProps=$req->{'{DAV:}prop'} || undef;
    
    # Property values response
    my $response=[];
    fetchProps( $root, $url, "http://$host", $reqProps, $depth, $response );
    my $xml = qq(<response>\n) . join ( qq(</response>\n<response>\n), @$response) . qq(</response>\n);
    $responder->multiStatus( $r, $xml );


}

sub fetchProps {

    my ($root, $url, $urlPrefix, $reqProps, $depth, $response) = @_;

    $DB::single=1;
    my $path="$root$url";

    if ($depth eq "0") {

        if (-d $path) {

            return push @$response, collection( $path, $url, $urlPrefix, $reqProps );

        } else {

            return push @$response, file( $path, $url, $urlPrefix, $reqProps );

        }

    }

    if ($depth eq "1") {

        if (-d $path) {

            fetchProps($root, $url, $urlPrefix, $reqProps, 0, $response);

            opendir PATH, $path;
            while (my $item = readdir PATH) {
                next if $item =~ /^\.\.?$/;
                fetchProps($root, "$url/$item", $urlPrefix, $reqProps, 0, $response);
            }
            closedir PATH;

        } else {
            fetchProps($root, $url, $urlPrefix, $reqProps, 0, $response);
        }

    }

    if ($depth eq "infinite") {

        if (-d $path) {

            opendir PATH, $path;
            while (my $item = readdir PATH) {
                fetchProps($root, "$url/$item", $urlPrefix, $reqProps, $depth, $response);
            }
            closedir PATH;

        } else {
            fetchProps($root, $url, $urlPrefix, $reqProps, 0, $response);
        }

    }

}





sub collection {

    my ($path, $url, $urlPrefix, $reqProps) = @_;

    $reqProps ||= \%collProps;

    my $stat=stat($path);

    my $ret=qq(\t<href>$urlPrefix$url/</href>\n)
            . qq(\t<propstat>)
            . qq(<prop>\n);

    foreach my $reqProp ( keys %{$reqProps} ) {

        $reqProp =~ s/^{DAV:}//;

        $ret .= qq(\t<$reqProp><collection/></$reqProp>\n) and next if $reqProp eq "resourcetype";

        if ($reqProp eq "creationdate") {
            $ret .= qq(\t<$reqProp>) . HTTP::DAVServer::dateEpoch( $stat->mtime ) . qq(</$reqProp>\n);
            next;
        }

        if ($reqProp eq "displayname") {
            $path =~ /([^\/]+\/)$/;
            $ret .= qq(\t<$reqProp>$1</$reqProp>\n);
            next;
        }

        warn "Collection property $reqProp not known\n" if $HTTP::DAVServer::WARN;

    }

    $ret .= qq(</prop>)
            . qq(<status>HTTP/1.1 200 OK</status>)
            . qq(</propstat>);

    return $ret;

}


sub file {

    my ($path, $url, $urlPrefix, $reqProps) = @_;
    $reqProps ||= \%fileProps;

    my $stat=stat($path);

    my $ret=qq(\t<href>$urlPrefix$url</href>\n)
            . qq(\t<propstat>)
            . qq(<prop>\n);

    foreach my $reqProp ( keys %{$reqProps} ) {

        $reqProp =~ s/^{DAV:}//;

        $ret .= qq(\t<$reqProp/>\n) and next if $reqProp eq "resourcetype";

        if ($reqProp eq "creationdate") {
            $ret .= qq(\t<$reqProp>) . HTTP::DAVServer::dateEpoch( $stat->mtime ) . qq(</$reqProp>\n);
            next;
        }

        if ($reqProp eq "displayname") {
            $path =~ /([^\/]+\/)$/;
            $ret .= qq(\t<$reqProp>$1</$reqProp>\n);
            next;
        }

        if ($reqProp eq "getcontentlength") {
            $ret .= qq(\t<$reqProp>) . $stat->size . qq(</$reqProp>\n);
            next;
        }

        warn "Collection property $reqProp not known\n" if $HTTP::DAVServer::WARN;

    }

    $ret .= qq(</prop>)
            . qq(<status>HTTP/1.1 200 OK</status>)
            . qq(</propstat>);

    return $ret;

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


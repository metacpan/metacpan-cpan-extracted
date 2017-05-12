
############################################################################
#
# HTTP::Webdav - Perl interface to Neon HTTP and WebDAV client library
#
# Copyright (c) 2001 Gerald Richter / ecos gmbh (www.ecos.de)
# 
# You may distribute under the terms of either the GNU General Public 
# License or the Artistic License, as specified in the Perl README file.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# $Id: propfind.pl,v 1.9 2001/06/06 19:51:36 richter Exp $
#
############################################################################

#
# This this an example how to retrieve properties from a dav server
#

use HTTP::Webdav ;
use HTTP::Webdav::Constants ;

sub auth
    {
    my ($userdata, $realm) = @_ ;

    print "auth called userdata = $userdata  realm = $realm\n" ;

    # return username, password
    return ("richter", "x") ;
    }

sub iterator
    {
    my ($userdata, $propname, $propvalue, $propstatus) = @_ ;

    print "propfind userdata = $userdata  nspace = $propname->{nspace}  name = $propname->{name}  value = $propvalue\n" ;
    
    return 0 ;
    }

sub callback
    {
    my ($userdata, $href, $results) = @_ ;

    print "propfind callback userdata = $userdata  href = $href\n" ;

    $x = $results -> iterate (\&iterator) ;
    print "iterate returns: $x\n" ;
    }



$sess = HTTP::Webdav -> new ;

$sess -> server ("www.gr.ecos.de", 8765) ;
$sess -> set_server_auth (\&auth) ;

print "--> propfind: all properties\n\n" ;

$sess -> simple_propfind ("/dav", NE_DEPTH_ONE, undef, \&callback) ;

print "Status: ", $sess -> get_error , "\n\n" ;



print "--> propfind: DAV:getlastmodified\n\n" ;

$sess -> simple_propfind ("/dav", NE_DEPTH_ONE, { nspace => 'DAV:', name => 'getlastmodified'}, \&callback) ;

print "Status: ", $sess -> get_error , "\n\n" ;


print "--> propfind: DAV:getlastmodified and DAV:getcontenttype\n\n" ;

$sess -> simple_propfind ("/dav", NE_DEPTH_ONE, 
                                [
                                { nspace => 'DAV:', name => 'getlastmodified'},
                                { nspace => 'DAV:', name => 'getcontenttype'}
                                ],
                                \&callback) ;

print "Status: ", $sess -> get_error , "\n\n" ;

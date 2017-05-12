
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
# $Id: proppatch.pl,v 1.8 2001/08/10 12:46:35 richter Exp $
#
############################################################################

#
# This this an example how to use the dav_proppatch function to set and
# remove properties
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


# remove property 'test3'
# set value of property 'test' to 'bar'

@props = (
    { name => {nspace => 'DAV:', name => 'test'}, type => 1},
    { name => {nspace => 'DAV:', name => 'test2'}, value => 'bar'},
    ) ;

$sess = HTTP::Webdav -> new ;

$sess -> server ("www.gr.ecos.de", 8765) ;
$sess -> set_server_auth (\&auth) ;

$sess -> proppatch ("/dav/foo.htm", \@props) ;

print "Status: ", $sess -> get_error , "\n" ;


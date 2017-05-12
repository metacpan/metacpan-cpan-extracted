
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
# $Id: showheader.pl,v 1.4 2001/06/01 10:36:07 richter Exp $
#
############################################################################

#
# This example shows how to install a callback to receives all headers
# and a callback to get call for a specific header and uses the request object
# to pass the data back
#

use HTTP::Webdav ;


sub hdr

    {
    my ($userdata, $value) = @_ ;
    
    print "Received Header: $value\n" ;
    } 

sub datehdr

    {
    my ($userdata, $value) = @_ ;
    
    print "In callback: Received Date: $value\n" ;
    
    $userdata -> {date} = $value ;
    } 



# setup session
$sess = HTTP::Webdav -> new ;

# setup host & port
$sess -> server ("www.ecos.de", 80) ;

# get request object
$request = $sess -> request_create ("HEAD", "/") ;

# install callback which gets all headers
$request -> add_response_header_catcher (\&hdr) ;

# install callback which gets only Date header
$request -> add_response_header_handler ('Date', \&datehdr) ;

$request -> begin_request ;

$request -> end_request ;

$status =  $request -> get_status ;
print "Status: \n" ;
while (($k, $v) = each %$status)
    {
    print "  $k = $v\n" ;
    }


print "\nEnd Of Request: Date: $request->{date}\n" ;





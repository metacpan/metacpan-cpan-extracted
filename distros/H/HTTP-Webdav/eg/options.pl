
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
# $Id: options.pl,v 1.1 2001/08/10 12:46:35 richter Exp $
#
############################################################################

#
# This example for a simple GET
#

use HTTP::Webdav ;

$sess = HTTP::Webdav -> new ;

$sess -> server ("www.i.ecos.de", 80) ;

$sess -> options ("/dav", \%result) ;

print "Options returned:\n" ;
while (($k, $v) = each %result)
    {
    print "$k = $v\n" ;
    }


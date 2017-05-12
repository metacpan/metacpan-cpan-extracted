
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
# $Id: get.pl,v 1.4 2001/06/01 10:36:07 richter Exp $
#
############################################################################

#
# This example for a simple GET
#

use HTTP::Webdav ;

$sess = HTTP::Webdav -> new ;

$sess -> server ("www.ecos.de", 80) ;

# instead of STDOUT you can use any open Perl filehandle
$sess -> get ("/", STDOUT) ;



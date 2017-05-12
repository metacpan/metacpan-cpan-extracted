package Lemonldap::Handlers::Generic;
use strict;
use warnings;
#####  use ######
use Apache2::URI();
use Apache::Constants qw(:common :response);
use MIME::Base64;
use LWP::UserAgent;
use Lemonldap::Config::Parameters;
use Lemonldap::Config::Initparam;
use Lemonldap::Handlers::Utilities;
use Lemonldap::Handlers::Core;
use Apache2::Log();
use Apache2::ServerRec ();

#### common declaration #######
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.0.0';
our $VERSION_LEMONLDAP = "3.0.0";
our $VERSION_INTERNAL  = "3.0.0";

####
####
##############################

=pod

=for html <center> <H1> Lemonldap::Handlers::Generic4a2 </H1></center> 


=head1 NAME

    Lemonldap::Handlers::Generic  - Perl extension for Lemonldap sso system

    Lemonldap::Handlers::Generic4a2 - Handler for Apache2 Lemonldap SSO
    system


=head1 SYNOPSIS
 
In httpd.conf 

  .....
  perltranshandler Lemonldap::Handlers::Generic4a2
  .....
 

=head1 DESCRIPTION

 Generic4a2 is the central piece of  websso framework .
 This module provides several methods but the principal goal of this is the handler function .
 It can be combined with mod_proxy or mod_rewrite and all other apache's  modules .
 It provides also an built-in  http proxy with LWP .
 see http://lemonldap.sf.net for more infos .
 

=head2 Parameters (see also doc folder)

 A minimal configuration  must provide  infos about :

=over 1

=item  config

 PerlSetVar ConfigFile /usr/local/apache/conf/config_demo1.xml 

 The filename of the mean XML Config   :It's REQUIRED

=item domain
 
 PerlSetVar Domain demo.net
 
 It fixes the value of domain for the  application protected by  this handler (see below) 

=item  xml section in config 
 
 Perlsetvar HandlerID <xml section>

 It fixes the value of XML section in config 

=back 


=head2 Example (a KISS example, see also eg folder) 
 
In httpd.conf 

 <virtualHost 127.0.0.1:80>
 servername authen.demo.net
 PerlModule Apache2::compat
 PerlModule Bundle::Apache2
 PerlModule Lemonldap::Handlers::Generic4a2 
 perltranshandler Lemonldap::Handlers::Generic4a2
 PerlSetVar Domain demo.net
 PerlSetVar Configfile /usr/local/apache/conf/application_new.xml
 PerlSetVar HandlerID myintranet
 proxypass /intranet http://lemonldap.sourceforge.net
 proxypassreverse /intranet  http://lemonldap.sourceforge.net
 documentroot /usr/local/apache/htdocs
 </virtualhost>


 In /usr/local/apache/conf/application_new.xml
  <lemonconfig>
        <domain    id="demo.net"
                   Cookie="lemondemo"
		            >
		 <handler 
        		 id="myintranet" 
		 	  DisableAccessControl= "1"
		        />  
        </domain>
  </lemonconfig>

   
 Now you can put http://authen.demo.net/intranet/ in your browser and you will see lemonldap's  site
 AND now you can control who and where goes on your site .
  
 You can pass parameters from httpd.conf with perlsetvar  facilities  or put them in xml file

=head2 Functions

=over 1

=item handler

 It's the mean  function which does all jobs . If the enebledproxy parameter is set to 1  ,this function
 will push proxy_handler function reference on  the handler's stack . If not it returns DECLINED (mod_proxy will be actived) 

=item proxy_handler 

 It's the built-in proxy (LWP)  web embedded  in lemonldap framework . It is  actived by  enabledproxy parameter .
 Some parameters are about this proxy and its behaviour     

=item _lemonldap_debug 

  append this keyword at the end of url and you will can see all headers send to host.
  Available  ONLY with built-in proxy


=back


=head2 Features

Generic4a2 is build arround perl's modules .

Those modules are :

=over 1

=item Utilities :

  collection of functions

=item Core :
 
  It provides basics services like the cache service, forge header service or authorization service.
  
 Core.pm  can use YOUR own services for all this cycle . It's plugger . Lemonldap framework is available 
 with somes services but you can with Core.pm propose your own schemas.
 News parameters  were added in XML DTD in order to describe the sequence.

=item  MatrixPolicy :
 
 manage authorization process , based on the hash of session (like preceding version)   

=item Memsession : 
 
 manage the backend of session (cache level 3 and 4 ) 

=item AuthorizationHeader :
 
 manage the construction of header 

=item RewriteHTML :

 Rewrite on fly html source in order to ajust somes tags like BASE , href or src
 Available  ONLY with built-in proxy
  

=back

=head4 More features

=over 1

=item Authentification
 
 Keep in mind  that the handler doesn't know HOW authenticate anybody but only knows WHERE authenticate . 
 The parameter 'portal' tells it where to send the authentification request. 

=item Caches 

 Thre are three levels of cache in lemonldap . 

 *First cache (level 1) is a very KISS  , it's a memory structure in the program .
 *Next  cache (level 2) is realised by using berkeleyDB hash
 *Last cache (level 3) is realised by using memcached (see Apache::Session::Memorycached on CPAN)

=back

=head1 SEE ALSO

Lemonldap(3), Lemonldap::Portal::Standard

http://lemonldap.sourceforge.net/

"Writing Apache Modules with Perl and C" by Lincoln Stein E<amp> Doug
MacEachern - O'REILLY

=over 1

=item Eric German, E<lt>germanlinux@yahoo.frE<gt>

=item Isabelle Serre, E<lt>isabelle.serre@justice.gouv.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Eric German E<amp> Isabelle Serre

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.

=item Portage under Apache2 is made with help of : Ali Pouya and 
Shervin Ahmadi (MINEFI/DGI) 

=back

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; version 2 dated June, 1991.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  A copy of the GNU General Public License is available in the source tree;
  if not, write to the Free Software Foundation, Inc.,
  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut


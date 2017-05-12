package Lemonldap::Portal::CAS;

use strict;
use warnings;
our $VERSION = '1.0.0';



1;
__END__

=head1 NAME

Lemonldap::Portal::CAS - Perl extension for lemonldap websso

Look at   LoginCAS.PM  example

=head1 SYNOPSIS

  use Lemonldap::Portal::LoginCAS
  


=head1 DESCRIPTION

 Lemonldap is a  Reverse-proxy webSSO  and CAS (Central Authentification Service) is an another websso from Yales university .
 CAS acts like Authentification service NOT for authorization service .
  
  These modules give the capacity at a lemonldap to resquest authentication upon  CAS server.
  So ,  an user will be  authenticate on CAS server AND authozized by lemonldap
 
  Need  AuthCAS module .

=head1 INSTALLATION

First intall lemonlap (see http://lemonldap.objecweb.org) ) 

Configures your Apache like this :   
   
 PerlSetVar Domain demo.net
 PerlSetVar Configfile /usr/local/monapache/conf/application.xml
 <location /portail>
  setHandler modperl
  perlresponsehandler Lemonldap::Handlers::LoginCAS
  PerlOptions +GlobalRequest
 </location>



Your application.xml is like this 

<domain    id="demo.net"
           Cookie="lemondemo"
           Sessionstore="memcached"
           Portal= "http://authen.demo.net/portail/accueil.pl"
           PortalCAS= "https://10.75.204.108:8443/esup/login"
           CASUrl   ="https://10.75.204.108:8443"
           CASValidate ="/esup/serviceValidate"
           CASFile     ="/certificate/ca.cer"
           ldap_server="ldap.demo.net"
           ldap_branch_people="ou=personnes,dc=demo,dc=net"    
         >


=head2 EXPORT

None by default.



=head1 SEE ALSO

  lemonldap websso framework 

=head1 AUTHOR

Eric German , E<lt>germanlinux@yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by lemonasso

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

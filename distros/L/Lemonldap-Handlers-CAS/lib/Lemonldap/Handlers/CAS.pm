package Lemonldap::Handlers::CAS;
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '1.1';


1;
__END__

=pod

=head1 NAME

Lemonldap::Handlers::CAS - Perl extension for Lemonldap webSSO

=head1 SYNOPSIS

  use Lemonldap::Handlers::Validate   ### Validate service ticket 
  use Lemonldap::Handlers::LoginCASFake  ###  Fake login : user must be egal to password (like CAS server demo) 
  use Lemonldap::Handlers::LogoutCAS ### logout SSO
  
=head1 DESCRIPTION
  
  Lemonldap is a  Reverse-proxy webSSO  and CAS (Central Authentification Service) is an another websso from Yales university .
  CAS acts like Authentification service NOT for authorization service .
  
  These modules give the capacity at a lemonldap to become CAS server.
  So ,  an user will be  authenticate on CAS server AND on lemonldap.
  Then the service ticket is send to serviceValidate the lemonldap can retrieve  all session for user and process to authorization like a lemonldap .
  
=head1 Compatibility with CAS protocol.

Lemonldap manages those parameters :

=over 4

=item  service

=item  renew 

=item  gateway

=back


=head1 INSTALLATION

 You must have an lemonldap websso installed (see doc on lemonldap.objectweb.org)  

 Configures your Apache like this :   
   
  <virtualhost 192.168.204.100>
  servername authen.demo.net
  loglevel debug
  documentroot /usr/local/apache2/htdocs
  alias /portal /usr/local/monapache/portal/
  ErrorLog logs/error_log
  <location /cas/login>
  setHandler modperl
  perlresponsehandler Lemonldap::Handlers::LoginCASFake
  PerlSetVar Domain demo.net
  PerlSetVar Configfile /usr/local/monapache/conf/application.xml
  PerlOptions +GlobalRequest
  </location>
  <location /cas/serviceValidate>
  setHandler modperl
  perlresponsehandler Lemonldap::Handlers::ValidateCAS
  PerlSetVar Domain demo.net
  PerlSetVar HandlerID validate
  PerlSetVar Configfile /usr/local/monapache/conf/application.xml
  PerlOptions +GlobalRequest
  </location>
  <location /cas/logout>
  setHandler modperl
  perlresponsehandler Lemonldap::Handlers::LogoutCAS
  PerlSetVar Domain demo.net
  PerlSetVar Configfile /usr/local/monapache/conf/application.xml
  PerlOptions +GlobalRequest
  </location>
  </virtualhost>

 YOU CAN MIXED lemonldap handler et CAS server 
  
  Your application.xml is like this 
    <domain    id="demo.net"
           Cookie="lemondemo"
           Sessionstore="memcached"
           portal= "http://authen.demo.net/portail/accueil.pl"
           LoginCASPage="/tmp/login.htmlcas"
           LogoutCASPage="/tmp/logout.htmlcas"
           LoginPage="/tmp/login.html"
           ldap_server="192.168.247.30"
           ldap_branch_people="ou=personnes,dc=demo,dc=net"    
         >
         <handler 
                id="validate"
                MultiHoming="pied,tete" 
              />
        <handler id="pied"
             MotifIn="/192.168.204.108\/caspied"
             applcode= "mail"
             pluginpolicy="Lemonldap::Handlers::RowPolicy"
          />
         <handler id="tete"
             MotifIn="/192.168.204.108\/castete"
             disableaccessControl="1"
          />
#### here normal lemonldap application ##### 
        <handler 
                id="appli1" 
                applcode= "APT"
                pluginpolicy="Lemonldap::Handlers::RowPolicy"
                enableLWP="1"
                basepub="http://myappli.demo.net"
                basepriv="http://www.eyrolles.com"
                >
        </handler>

   etc..

    Put your login.html and logout.cas in the good directory (here /tmp) and the right name (here /tmp/login.htmlcas ) 

    See the caspied and castete php examples  (basic and standard CAS  application) 
    
=head1 NOTES 

=over 4

=item   Lemonldapcas is just an emulation of CAS server , use the real CAS server if you have only CAS application .

=item  Lemonldap provides CAS version 1 and version 2 protocol ,if your location of validation  contents the word 'Validate' (eg serviceValidation)  the hanlder will use CAS version 2 overwise  (eg service) it's CAS version 1

=item  Lemonlap DOESN'T provide 'proxycas' service (in process) .
  
=item  Lemonldap shares its sessions  with other lemonldap (unlike CAS server) .

=item  YOU MUST use HTTPS (by mod_ssl) in your apache server 

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.



=head1 AUTHOR

root, E<lt>germanlinux@yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by germanlinux at yahoo.fr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

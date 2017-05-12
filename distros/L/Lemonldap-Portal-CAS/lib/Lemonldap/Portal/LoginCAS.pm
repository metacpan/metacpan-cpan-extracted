package Lemonldap::Handlers::LoginCAS;
use strict;
use warnings;
use Lemonldap::Config::Parameters;
use Lemonldap::Portal::Standard;
use Apache2::Const qw(DONE FORBIDDEN OK SERVER_ERROR REDIRECT);
use Apache2::Log();
use APR::Table;
use Apache2::RequestRec ();
use Apache2::ServerRec();
use Data::Dumper;
use Template;
use URI::Escape;
use CGI ':cgi-lib';
use Apache::Session::Memorycached;
use MIME::Base64;
use Encode qw(encode);
use Lemonldap::Portal::Session;
use Net::LDAP::Entry;
use IO::File;
our $VERSION = '1.0.0';
use AuthCAS;

my $client_addr;
my $sessCacheRefreshPeriod;
my $log;
my $dump;
my $html;
my $Stack_User;

#my $UserAttributes;
my $Major;
my $MyApplicationXmlFile;
my $MyDomain;
my $LoginPage;
my $RedirectPage;
my $Parameters;
my $Conf_Domain;
my $Login_Url;
my $Cookie_Name;

#my $ipCheck;
#my $inactivityTimeout;
my $Ldap_Server;
my $Ldap_Branch_People;
my $Ldap_Dn_Manager;
my $Ldap_Pass_Manager;
my $Ldap_Port;
my @attrs;
my $Ldap_Search_Bases;
my @base;
my $MemcachedServer;
my $CookieName;
my $line_session;
my $_username;

#my $InactivityTimeout;
#my $Encryptionkey;
my $page_html;
my $Menu;
my $Messages = {
    1 =>
      'Votre connexion a expir&eacute; vous devez vous authentifier de nouveau',
    2 =>
'Les champs &quot;Identifiant&quot; et &quot;Mot de passe&quot doivent &ecirc;tre remplis',
    3 => 'Wrong directory manager account or password',
    4 => 'n\'a pas &eacute;t&eacute; trouv&eacute; dans l\'annuaire',
    5 => 'Mot de passe erron&eacute;',
    6 =>
'Votre adresse IP a &eacute;t&eacute; modifi&eacute;. Vous devez vous authentifier de nouveau',
    7 => 'Serveral Entries found on ldap server for this user',
    8 => 'Bad connection to ldap server',
};

sub my_none {
    return 0;
}
########  only use if you don't have ldap server

sub my_entry {
    my $self =shift;
    my $entry = Net::LDAP::Entry->new();
    my $user =$self->user;
    $entry->dn("uid=$user,dc=demo,dc=net") ;
    $entry->add(uid =>$user ); 
    $entry->add(mail =>"$user\@demo.net" ); 
    $entry->add(roleprofil =>'APPLIX;my_role' ); 
    $self->{entry}=$entry;
   my $fh = IO::File->new_tmpfile ;
   $entry->dump($fh);    
   my @a;
   seek ($fh,0,0);
   for (<$fh>) { 
   push @a,$_;
   }
   my $a =join '<br>', @a;
   $self->{dump} =$a;
    undef $fh;
    return 1;
}
#############################
sub my_credential {
    1;

}

sub My_Session {
    my $self     = shift;
    my $paramxml = $self->{line_session};
      my %Session;

    my $entry = $self->{entry};
    my $l = Dumper ($paramxml) ;
    my $obj = Lemonldap::Portal::Session->init( $paramxml, 'entry' => $entry );
      $self->{infosession} = $obj;

}

sub handler {
    my $r = shift;
    my $Stack_User;
    $log = $r->log;
    ###  1 tester le TGT  cookie
    my %Param = Vars();
       my $origine = $Param{'url'};
    $MyApplicationXmlFile = $r->dir_config('ConfigFile');
    $MyDomain             = lc( $r->dir_config('Domain') );
    $Major                = $r->dir_config('Organization');
    if ( !defined($Major) ) {
        $Major = "authz_headers";
    }
    $Parameters =
      Lemonldap::Config::Parameters->new( file => $MyApplicationXmlFile, );
    $Conf_Domain = $Parameters->getDomain($MyDomain);
    my $myaddress   = $Conf_Domain->{Portal};
    my $Login_Url   = $Conf_Domain->{PortalCAS};
    my $CASUrl      = $Conf_Domain->{CASUrl};
    my $CASValidate = $Conf_Domain->{CASValidate};
    my $CAFile      = $Conf_Domain->{CAFile};
    $Cookie_Name = $Conf_Domain->{Cookie};
   
    my $CookieNamep = $Cookie_Name . "_prov";
        	$Ldap_Server = $Conf_Domain->{ldap_server};
	        $Ldap_Branch_People = $Conf_Domain->{ldap_branch_people};
	        $Ldap_Dn_Manager = $Conf_Domain->{DnManager};
	        $Ldap_Pass_Manager = $Conf_Domain->{passwordManager};
	        $Ldap_Port = $Conf_Domain->{ldap_port};
        	$Ldap_Search_Bases = $Ldap_Branch_People;
	         @base = split(/\s*:\s*/,$Ldap_Search_Bases);
	 $line_session = $Conf_Domain->{DefinitionSession};
	

    $MemcachedServer =
      $Parameters->formateLineHash(
        $Parameters->findParagraph( 'session', 'memcached' )->{SessionParams} );
################  recup cookie prov ######################
    my $entete2 = $r->headers_in();

    #Recuperation du Cookie
    my $idx_tmp      = $entete2->{'Cookie'};
    my $local_cookie = $CookieNamep;
       my @tab = split /;/, $idx_tmp;
    my $cookie;
    my $idrecup;
    my $needticket=1;

    foreach (@tab) {
        if (/$local_cookie=([^; ]+)/) {
            $cookie = $1;
        }
    }

     my $etat;
    if ($cookie) {    # il peut peut etre deja ok ? ######
        my %_it;
        my $Memcachedfast= $MemcachedServer;
	$Memcachedfast->{timeout}= 100 ;
        tie %_it, 'Apache::Session::Memorycached', $cookie, $Memcachedfast;
        my $or = $_it{origine};
        untie %_it;
         if ($or) {
            #### il est de retour avec son tiket
            my $ticket = $Param{'ticket'};
            $etat = 1;
                      if ($ticket) {    ### un petit coup de cas ?
                $needticket = 0;
                 my $cas = new AuthCAS(
                    'casUrl'              => $CASUrl,
                    'serviceValidatePath' => $CASValidate,
                    'CAFile'              => $CAFile,
                );
                my $user = $cas->validateST( $myaddress, $ticket );
                if ( !$user ) {    #  erreur il faut arreter
                    return FORBIDDEN;
                }
                else {
                    ### tout est ok
                    ## je retrouve le  service initial et je continue la pile
                    $Param{identifiant} = $user;
                    $Param{secret} = $user;
                    $Param{url}         = $or;

                }
            }
            else {
                return FORBIDDEN;

            }

        }
    }

    if ($needticket) {
########  attibution d un numero provisoire ###############
   
        my %_it;
        tie %_it, 'Apache::Session::Memorycached', undef, $MemcachedServer;
        $_it{origine} = $origine || 'Tk9ORQ=='; #NONE in base64 representation
        my $idprov = $_it{'_session_id'};
        untie %_it;
#### won genere un cookie lemonldap avec le numero de session prov
        my $dotdomain   = "." . $MyDomain;
        my $pathlemon   = '/';
        my $LemonCookie = CGI::cookie(
            -name   => $CookieNamep,
            -value  => $idprov,
            -domain => $dotdomain,
            -path   => $pathlemon,
        );

        my $redirection = $Login_Url;
        $redirection .= "?service=" . uri_escape($myaddress);
           print CGI::header(
            -Refresh => '0; URL=' . $redirection,
            -cookie  => $LemonCookie
        );
        return DONE;
    } else
     {
    ### tout est ok il faut deroule la pile 
    		$Stack_User = Lemonldap::Portal::Standard->new(
			'msg' => $Messages, 
                        'credentials'   => \&my_credential,
			'setSessionInfo' => \&My_Session,
                        'line_session' =>  $line_session,
	           	   );               
			   
        
     my  $Retour  = $Stack_User->process( 'param' => \%Param,
					   'server' => $Ldap_Server, 
					   'base' => \@base,
				     );
    my $Message = '';
		my $Erreur;
    if ($Retour) {
        $Message = $Retour->message;
        $Erreur  = $Retour->error;
    }
    if ($Erreur)  {
         return FORBIDDEN;
    }
		my $MyHashSession = $Retour->infoSession;	
                my $l = Dumper($MyHashSession) ;
		my %Session;
		tie %Session, 'Apache::Session::Memorycached', undef, $MemcachedServer;	
		foreach (keys %{$MyHashSession}){
			 $Session{$_}= $MyHashSession->{$_} if $MyHashSession->{$_} ;
		}
		
		
		my $Session_Id = $Session{'_session_id'};
	my $l =Dumper (\%Session);	
		$l =~	 s/\n/\<br\>/g;
                $l=~ s/\$var\d+/Item/ig;
		untie %Session;
		
		# Cookie creation
 		my $PathCookie = "/";
               my $LemonldapCookie = CGI::cookie(
                	    -name   => $Cookie_Name,
	                    -value  => $Session_Id,
        	            -domain => ".".$MyDomain,
                	    -path   => $PathCookie,
                	);
		my $LemonldapCookieprov = CGI::cookie(
                	    -name   => "$CookieNamep",
	                    -value  => 0,
        	            -domain => ".".$MyDomain,
                	    -path   => $PathCookie,
                	);
		
my 		$UrlDecode = $Retour->getRedirection();
		undef $UrlDecode if $UrlDecode=~ /none/i ;

  if ($UrlDecode) {
       print CGI::header( -Refresh => '0; URL='.$UrlDecode, -cookie => [$LemonldapCookie, $LemonldapCookieprov] );
               return OK;		
	 }  else {	  
	      	$r->content_type('text/html');
        $r->headers_out->add( 'Set-Cookie' => $LemonldapCookieprov );
        $r->headers_out->add( 'Set-Cookie' => $LemonldapCookie );
        $r->print ;
        $r->print(<<END1);
<html>
  <head>
    <title>lemonldap websso</title>
    <style type="text/css" media="all">
     p { color: #060;
         font-size: 1.0em;
         font-family: Verdana, Arial, sans-serif;   
         font-weight: bold; 
       } 
     h1 { color: #000;
          font-size: 1.5em;
          font-family: Verdana, Arial, sans-serif;   
          font-weight: bold; 
          border-bottom: 3px solid #019733;
          margin: 40px 0 20px 0px;
          padding: 0 0.5em 0.5em 0.5em;
        } 
      body { background-color: #77E0AB;       }
      label { background-color: #94DBB7;
              color: #018023;
              font-weight: bold;
              padding: 4px;  
              font-family: Verdana, Arial, sans-serif;   
              font-size: 0.9em;
              width: 500px; 
            }  

      br { display: none;
         } 
      .nodisp { display: none; }
    </style>
  </head>
<body>
<h1>Hello on lemonldap and CAS  websso 'world</h1>
<p>
 <center><label>Your are Authenticate on lemondap webSSO  and CAS server</label>  
</center>
</body>
</html>
END1





return OK;
}
}
}
1;

=pod

=head1 NAME

Lemonldap::Portal::CAS - Perl extension for lemonldap websso

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

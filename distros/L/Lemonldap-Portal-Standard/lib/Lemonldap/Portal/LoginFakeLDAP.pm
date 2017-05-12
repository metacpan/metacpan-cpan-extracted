package Lemonldap::Portal::LoginFakeLDAP;
	
use strict;
use warnings;

	
use Lemonldap::Config::Parameters;
use Lemonldap::Portal::Standard;
use Apache2::Const qw(FORBIDDEN OK SERVER_ERROR REDIRECT);

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
our $VERSION = '3.1.0';

my $client_addr;
my $sessCacheRefreshPeriod;
my $log;
my @base;
my $dump;
my $html;
my $Stack_User;
my $UserAttributes;
my $Major;
my $MyApplicationXmlFile; 
my $MyDomain; 
my $LoginPage; 
my $RedirectPage; 
my $Parameters; 
my $Conf_Domain; 
my $Login_Url; 
my $Cookie_Name; 
my $ipCheck; 
my $inactivityTimeout; 
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
my $InactivityTimeout; 
my $Encryptionkey; 
my $page_html;
my $Menu; 
my $Messages = { 1 => 'Votre connexion a expir&eacute; vous devez vous authentifier de nouveau',
                 2 => 'Les champs &quot;Identifiant&quot; et &quot;Mot de passe&quot doivent &ecirc;tre remplis',
                 3 => 'Wrong directory manager account or password' ,
                 4 => 'n\'a pas &eacute;t&eacute; trouv&eacute; dans l\'annuaire',
                 5 => 'Mot de passe erron&eacute;' ,
                 6 => 'Votre adresse IP a &eacute;t&eacute; modifi&eacute;. Vous devez vous authentifier de nouveau',
                 7 => 'Serveral Entries found on ldap server for this user',
                 8 => 'Bad connection to ldap server',
                };
sub my_none {
return 0; 
}


sub My_Session {
	my $self = shift;
	my $paramxml = $self->{line_session};

	my %Session;

	my $entry = $self->{entry};
	my $obj = Lemonldap::Portal::Session->init ($paramxml,'entry' =>$entry) ;
	$self->{infosession} = $obj;
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


    }


		
sub handler {	
	my $r = shift;
 	$log = $r->log;	
	
	if ( $Stack_User->{'AlreadyCreated'} ){
		undef $Stack_User->{'error'};
	}else{
		$log = $r->log;
        	$MyApplicationXmlFile = $r->dir_config('ConfigFile');
	        $MyDomain = lc($r->dir_config('Domain'));
	        $LoginPage = $r->dir_config('LoginPage');
	        $Major = $r->dir_config('Organization');
        	if ( ! defined($Major) ){
                	$Major = "authz_headers";
        	}
	        $Parameters = Lemonldap::Config::Parameters->new( file => $MyApplicationXmlFile, );
	        $Conf_Domain = $Parameters->getDomain($MyDomain);
	        $Login_Url = $Conf_Domain->{Portal};
	        $Cookie_Name = $Conf_Domain->{Cookie};
	        $page_html = $Conf_Domain->{LoginPage};
                        	$Ldap_Server = $Conf_Domain->{ldap_server};
	        $Ldap_Branch_People = $Conf_Domain->{ldap_branch_people};
	        $Ldap_Dn_Manager = $Conf_Domain->{DnManager};
	        $Ldap_Pass_Manager = $Conf_Domain->{passwordManager};
	        $Ldap_Port = $Conf_Domain->{ldap_port};
    

		if (! $html) {
		    my $file ;
		    open($file ,"<$page_html");
                    local $/;
		    $/ ='';
                    $html = <$file>;
                    close $file;
                      }
	        $ipCheck = $Conf_Domain->{ClientIPCheck};
		
		   
		 $inactivityTimeout = $Conf_Domain->{InactivityTimeout};
	        $sessCacheRefreshPeriod = $Conf_Domain->{SessCacheRefreshPeriod};
        	$Ldap_Server = $Conf_Domain->{ldap_server};
	        $Ldap_Branch_People = $Conf_Domain->{ldap_branch_people};
	        $Ldap_Dn_Manager = $Conf_Domain->{DnManager};
	        $Ldap_Pass_Manager = $Conf_Domain->{passwordManager};
	        $Ldap_Port = $Conf_Domain->{ldap_port};

        	#<Recuperation de l'adresse IP cliente>
	        if ($ipCheck){
        	        my $connection = $r->connection();
                	$client_addr = $connection->remote_ip();
        	}
	        #</Recuperation de l'adresse IP cliente>

	        $UserAttributes = $r->dir_config('LdapUserAttributes');
        	if (defined($r->dir_config('LdapUserAttributes'))){
	         @attrs = split(/\s+/,$r->dir_config('LdapUserAttributes'));
        	}else{
	         @attrs = ();
        	}

        	$Ldap_Search_Bases = $Ldap_Branch_People;
	       # if (defined($r->dir_config('LdapSearchBases'))){
        #	        $Ldap_Search_Bases = $r->dir_config('LdapSearchBases').":".$Ldap_Search_Bases;
      #  	}
	         @base = split(/\s*:\s*/,$Ldap_Search_Bases);

		$MemcachedServer = $Parameters->formateLineHash($Parameters->findParagraph('session','memcached')->{SessionParams});
		$CookieName = $Conf_Domain->{Cookie};
		$InactivityTimeout = $Conf_Domain->{InactivityTimeout};
		$Encryptionkey = $Conf_Domain->{Encryptionkey};
		$Menu = $Conf_Domain->{'Menu'};

 $line_session = $Conf_Domain->{DefinitionSession};

		$Stack_User = Lemonldap::Portal::Standard->new(
			'msg' => $Messages, 
                        'setSessionInfo' => \&My_Session,
                                            #  'controlUrlOrigin' => \&my_none,
                      'controlTimeOut' => \&my_none,
                   # 'controlSyntax' => \&my_none,
                      'controlIP'    =>  \&my_none,
	           #   'bind'     =>  \&my_none,
                   #   'formateFilter' =>\&my_none,
                   #   'formateBaseLDAP' =>\&my_none,
                   #   'contactServer'  =>\&my_none,
                   #   'search'  =>\&my_entry,
                   #   'unbind'  =>\&my_none,
                   #   'credentials' =>\&my_none,
                           
 	   );               
 	       $Stack_User->{'AlreadyCreated'} = "true";
               $Stack_User->{line_session} = $line_session;
   
	    }
		
	my $UrlCode;
	my $UrlDecode;
	my $Erreur;

	my %Params ;
        my $buf;
# copy POST data, if any
    if ( $r->method eq 'POST' ) {
        my $len = $r->header_in('Content-length');
        $r->read( $buf, $len );
      my @arams= split '&',$buf;
       for (@arams) {
           (my $cle,my $val) = /(.+?)=(.+)/;       
      $Params{$cle}= $val if $cle; 
} 
}  else {
 # method GET 

 my $buf= $r->args;
   my @arams= split '&',$buf;
       for (@arams) {
           (my $cle,my $val) = /(.+?)=(.+)/;
      $Params{$cle}= $val if $cle;
}
 

}	
        
        my $l= Dumper (\%Params);
	my $Retour = $Stack_User->process( 'param' => \%Params, 
					   'server' => $Ldap_Server, 
					   'base' => \@base,
	  );
	my $Message = '';

	if ( $Retour ){
		$Message = $Retour->message;
		$Erreur = $Retour->error;
	}	

	if ( $Erreur ) {

		if ( $Erreur == 3 ){
			# Wrong directory manager account or password
			$log->error("LemonLDAP: ".$Message);
			return Apache2::Const::SERVER_ERROR ;		
		}
		if ( $Erreur == 4 || $Erreur == 5 ){
			# If bad login or password, refresh the login page with no information
			$log->info("LemonLDAP: ".$Message);
			#$Message = 'Authentification echou&eacute;e';
			$Message = '';
		}	
	
		# Login Page sending
		my $Identifiant = $Retour->user;
		my $secret = $Retour->secret;
		($UrlCode, $UrlDecode) = $Stack_User->getAllRedirection;
		my $html_ok =$html;
                $html_ok=~ s/%user%/$Identifiant/g;
                $html_ok=~ s/%secret%/$secret/g;
                $html_ok=~ s/%message%/$Message/g;
                $html_ok=~ s/%urldc%/$UrlDecode/g;
                $html_ok=~ s/%urlc%/$UrlCode/g;


#		
#$Data = { 'urlc' => $UrlCode,
#			     'urldc' => $UrlDecode,
#			     'message' => $Message,
#			     'identifiant' => $Identifiant
#			    };

        $r->content_type('text/html');
        $r->send_http_header;

$r->print($html_ok);

########## ici page en cas d erreur #############
	}	
	else 	
	{	
		# Sending Redirect to Generic
				
		my $MyHashSession = $Retour->infoSession;	
                my $l = Dumper($MyHashSession) ;

		if (defined($sessCacheRefreshPeriod) && defined($inactivityTimeout)){
                        $MemcachedServer->{timeout} = $sessCacheRefreshPeriod + $inactivityTimeout;
                }
	
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
		
# second acces 
                tie %Session, 'Apache::Session::Memorycached', $Session_Id, $MemcachedServer;	
              my $ll = Dumper (\%Session);	
		$ll =~	 s/\n/\<br\>/g;
                $ll=~ s/\$var\d+/Item/ig;
                
                if (! $Session{mail} ) {
                  $ll ="<b> Your memcached server seem to be down</b>";
		  }
		untie %Session;
		# Habib Timeout
		#Positionnement de la valeur time_end
	$dump =$Retour->{dump};	
		
		my $val_test;

		if(defined($InactivityTimeout) && $InactivityTimeout != 0 ){
        		my $time_end = time() + $InactivityTimeout;
	        	if (defined($Encryptionkey)){
        	        	my $timeout_key = $Encryptionkey;
	                	my $cipher = new Crypt::CBC(-key => $timeout_key,-cipher => 'Blowfish',-iv => 'lemonlda',-header => 'none');
        		        $time_end = $cipher->encrypt_hex($time_end);
                	}
        		#Chaine utilise comme separateur entre l'id de session et le time_end
	       	 	#concatenation des deux valeurs
			my $separator = "_";
			$val_test = $Session_Id.$separator.$time_end;
		}else{
		        $val_test = $Session_Id;
		}
 		
		$log->info("Set-Cookie: -name   => $CookieName  -value  => $val_test -domain => ".".$MyDomain -path   => $PathCookie");
        
		my $LemonldapCookie = CGI::cookie(
                	    -name   => $CookieName,
	                    -value  => $val_test,
        	            -domain => ".".$MyDomain,
                	    -path   => $PathCookie,
                	);

		$UrlDecode = $Retour->getRedirection();

		$UrlDecode = $Menu if ( $UrlDecode eq '' );
  if ($UrlDecode) {

#$UrlDecode =~ s/priv//g;
$r->headers_out->add('Location' => $UrlDecode);
        $r->send_http_header;
        return REDIRECT;
	 }  else {	  
	      	$r->content_type('text/html');
        $r->headers_out->add( 'Set-Cookie' => $LemonldapCookie );
        $r->send_http_header;
$r->print(<<END1);
<html>
<head><title>lemonldap websso</title></head>
<body>
<h1>Hello in lemonldap websso 'world</h1>
Congratulation your are enter in the  lemonldap'world
<p>Your id_session is :$val_test<p>
<p> Your session have been created  like this :<br>
$l<p>
Your session stored on memcached server is like this :<br>
$ll<p>
<p>Your LDAP Entry :<br>$dump


</body>
</html>
END1
}
		
	}	
	
	return OK ;		
}	

1;

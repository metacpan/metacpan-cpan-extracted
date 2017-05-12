package Lemonldap::Portal::LoginDAC;
	
use strict;
use warnings;
   
use Apache2::Const;	
use Lemonldap::Config::Parameters;
use Lemonldap::Portal::Standard;
use Lemonldap::Portal::AccessPolicy;
use Apache2::Const;
use Data::Dumper;
use Template;
use URI::Escape;
use CGI ':cgi-lib';
use Apache::Session::Memorycached;
use MIME::Base64;
use Encode qw(encode);
use Sys::Hostname;
our $VERSION = '3.1.0';

my $client_addr;
my $SessCacheRefreshPeriod;
my $Stack_User;
my $LdapUserAttributes;
my $Org;
my $AccessPolicy;
my $Ldap_Filter_Attribute;
my $MyAttribute;
my $MyDomain; 
my $LoginPage; 
my $RedirectPage; 
my $Parameters; 
my $Conf_Domain; 
my $Login_Url; 
my $IpCheck; 
my $Ldap_Server; 
my $Ldap_Branch_People; 
my $Ldap_Dn_Manager; 
my $Ldap_Pass_Manager; 
my $Ldap_Port; 
my @attrs;
my @base; 
my $MemcachedServer;
my $CookieName;  
my $InactivityTimeout; 
my $Encryptionkey; 
my $Menu; 
my $MemcachedSessionId;
my $SessionParams;
my $DacHostname;
my $Messages = { 1 => 'Votre connexion a expir&eacute; vous devez vous authentifier de nouveau',
                 2 => 'Les champs &quot;Identifiant&quot; et &quot;Mot de passe&quot doivent &ecirc;tre remplis',
                 3 => 'Wrong directory manager account or password' ,
                 4 => 'n\'a pas &eacute;t&eacute; trouv&eacute; dans l\'annuaire',
                 5 => 'Mot de passe erron&eacute;' ,
                 6 => 'Votre adresse IP a &eacute;t&eacute; modifi&eacute;. Vous devez vous authentifier de nouveau',
                 7 => 'Serveral Entries found on ldap server for this user',
                 8 => 'Bad connection to ldap server',
                };
   
   
   
sub My_Session {
   	my $self = shift;
   	
   	my %Session;
   	my $Entry = $self->{entry};
   	$Session{dn} = $Entry->dn();
   	$self->{dn} = $Entry->dn();		
   	my $res = $self->{AccessPolicy};
	if ($res eq "default"){
                Lemonldap::Portal::AccessPolicy->$res($Entry,\%Session,$Org,$MyAttribute);
        }else{
                Lemonldap::Portal::AccessPolicy->$res($Entry,\%Session,$Org);
        }

   
   
	if (defined($client_addr)){
   		$Session{'clientIPAdress'}= $client_addr;
   	}
         if (defined($SessCacheRefreshPeriod)){
                $Session{'SessExpTime'}= time() + $SessCacheRefreshPeriod ;
        }
   	
   	$self->{infosession} = \%Session;
}  		
   		
sub handler {	
   	my $r = shift;
   	my $log = $r->log;	
   
   	my $connexion = $r->dir_config();
   	my $conf_httpd = &Lemonldap::Config::Initparam::init_param_httpd($log,$connexion);
   	my $conf_xml = {};
   	if ( defined $conf_httpd->{CONFIGFILE} ){
                         $conf_xml  = &Lemonldap::Config::Initparam::init_param_xml($conf_httpd);
        }
   	my $Conf = &Lemonldap::Config::Initparam::merge($conf_httpd, $conf_xml);
        $MyDomain = lc($Conf->{DOMAIN});
        $LoginPage = $Conf->{LOGINPAGE};
        $RedirectPage = $Conf->{REDIRECTPAGE};
        $Org = $Conf->{ORGANIZATION};
        if ( ! defined($Org) ){
            $Org = "authz_headers";
        }
        $Login_Url = $Conf->{PORTAL};
	$AccessPolicy = $Conf->{ACCESSPOLICY};
	 if ( ! defined($AccessPolicy) ){
            $AccessPolicy = 'default';
        }

        $IpCheck = $Conf->{CLIENTIPCHECK};
        $SessCacheRefreshPeriod = $Conf->{SESSCACHEREFRESHPERIOD};
        $Ldap_Filter_Attribute = $Conf->{LDAPFILTERATTRIBUTE};
	$Ldap_Server = $Conf->{LDAP_SERVER};
        $Ldap_Branch_People = $Conf->{LDAP_BRANCH_PEOPLE};
        $Ldap_Dn_Manager = $Conf->{DNMANAGER};
        $Ldap_Pass_Manager = $Conf->{PASSWORDMANAGER};
        $Ldap_Port = $Conf->{LDAP_PORT};
        $MemcachedSessionId = $Conf->{SESSIONSTORE};
        $CookieName = $Conf->{COOKIE};
        $InactivityTimeout = $Conf->{INACTIVITYTIMEOUT};
        $Encryptionkey = $Conf->{ENCRYPTIONKEY};
        $Menu = $Conf->{MENU};
        $LdapUserAttributes = $Conf->{LDAPUSERATTRIBUTES};
        if ($Ldap_Pass_Manager =~ /^\{CODED\}/ ){
		$Ldap_Pass_Manager = `/dactools/pass-crypt 1 $Ldap_Pass_Manager`;
		chomp($Ldap_Pass_Manager);
		
	} 


	if (defined($LdapUserAttributes)){
              @attrs = split(/\s+/,$LdapUserAttributes);
       	      $MyAttribute = $attrs[0];
	 }else{
              @attrs = ();
        }

        my @base = split(/\s*:\s*/,$Ldap_Branch_People);
        $MemcachedServer = $Conf->{SERVERS};

	if ( $Stack_User->{'AlreadyCreated'} ){
		undef $Stack_User->{'error'};		
	}else{


		$Stack_User = Lemonldap::Portal::Standard->new('msg' => $Messages, 'setSessionInfo' => \&My_Session, 'attrs' => \@attrs, 'base' => \@base ,'AccessPolicy' => $AccessPolicy, 'log' => $log);
		$Stack_User->{'AlreadyCreated'} = "true";
		$DacHostname = hostname();
	}
	
	my $UrlCode;
	my $UrlDecode;
	my $Erreur;
		
	my %Params = Vars;
	my $Data;
	my $Template = Template->new('ABSOLUTE' => 1);
		
	my $Retour = $Stack_User->process( 'param' => \%Params, 
					   'server' => $Ldap_Server, 
					   'port' => $Ldap_Port, 
					   'DnManager' => $Ldap_Dn_Manager,
					   'passwordManager' => $Ldap_Pass_Manager,
					   'branch' => $Ldap_Branch_People,
					   'Attributes' => $Ldap_Filter_Attribute,  
					   'filter' => undef,
					   'log' => $log
					);
	my $Message = '';
	if ( $Retour ){
		$Message = $Retour->message;
		$Erreur = $Retour->error;
	}	
	if ( $Erreur ) {
		if ( $Erreur == 1 ){
#			$log->info("LemonLDAP: Session expired for user ¨- ".$Retour->user );
		}	
		if ( $Erreur == 6 ){
#			my $conn = $r->connection();
#                       my $addr = $conn->remote_ip();
#                       $log->info("LemonLDAP: IP changes in $addr for user -> ".$Retour->user);
                }
		if ( $Erreur == 7 ){
                        $log->info("LemonLDAP: ".$Message." : ".$Retour->user);
                }
	
		
		# Login Page sending
		my $Identifiant = $Retour->user;
		($UrlCode, $UrlDecode) = $Stack_User->getAllRedirection;
		$Data = {    'urlc' => $UrlCode,
			     'urldc' => $UrlDecode,
			     'message' => $Message,
			     'identifiant' => $Identifiant,
			     'ip' => "DAC : ".$DacHostname
			    };
		 if ( $Erreur == 8 ){
                       
		       # bad connection to ldap server
                       # reafficher la page de login sans les champs de saisie et les boutons pour l'authentification
                       $Data->{debutcommentaire} = "<!--";
                       $Data->{fincommentaire} = "-->";
                 }
	
		print CGI::header();
		$Template->process( $LoginPage , $Data ) or die($Template->error());
	}	
	else 	
	{	
		# Sending Redirect to Generic
				
		my $MyHashSession = $Retour->infoSession;	
		if (defined($SessCacheRefreshPeriod) && defined($InactivityTimeout)){
                        $MemcachedServer->{timeout} = $SessCacheRefreshPeriod + $InactivityTimeout;
                }
		
		#No insertion in Memcached before untie
		$MemcachedServer->{updateOnly} = 1;
		
		my %Session;
		tie %Session, 'Apache::Session::Memorycached', undef, $MemcachedServer;	
		foreach (keys %{$MyHashSession}){
			 $Session{$_}= $MyHashSession->{$_} if $MyHashSession->{$_} ;
		}
		if (defined($SessCacheRefreshPeriod)){
        	        $Session{'SessExpTime'}= time() + $SessCacheRefreshPeriod ;
	        }
	
		if ($IpCheck){
                        my $connection = $r->connection();

                        $client_addr = $connection->remote_ip();

	                $Session{'clientIPAdress'}= $client_addr;
	        }
		
		
		my $Session_Id = $Session{'_session_id'};
			
		untie %Session;
		
		my %session ;
   		tie %session, 'Apache::Session::Memorycached', $Session_Id,$MemcachedServer;		
	
		if (keys(%session) < 3){
			$log->error("SERVER MEMCACHED UNREACHABLE. PLEASE CHECK IF YOUR SERVER IS ON OR IF YOUR CONFIGURATION FILE IS CORRECT");
			return Apache2::Const::SERVER_ERROR ;				
		}
	
		untie %session;
		# Cookie creation
 		my $PathCookie = "/";
		
		
		# Habib Timeout
		#Positionnement de la valeur time_end
		
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
 		
		
		my $LemonldapCookie = CGI::cookie(
                	    -name   => $CookieName,
	                    -value  => $val_test,
        	            -domain => ".".$MyDomain,
                	    -path   => $PathCookie,
                	);

		$UrlDecode = $Retour->getRedirection();
		$UrlDecode = $Menu if ( $UrlDecode eq '' );
		
		$Data = { 'urldc' => $UrlDecode, 'message' => 'Session '.$Session_Id.$LemonldapCookie };
		print CGI::header( -Refresh => '0; URL='.$UrlDecode, -cookie => $LemonldapCookie );
		
	}	
	
	return Apache2::Const::DONE ;		
}	

1;

__END__

=head1 NAME

Lemonldap::Portal::Login - Login module for the lemonldap open source SSO system

=head1 SYNOPSIS

In the lemonldap SSO system, Lemonldap::Portal::Login is the module which is reponsible ofdisplaying
un html authentication page to a user in order to authenticate him and create a session for fim. So
after that, this user can access his applications.

=head1 CONFIGURATION

In order to get Lemonldap::Portal::Login working, you must make some configuration with Apache. Here is
an example illustrating a lemonldap login virtual host :

Listen 443
<VirtualHost *:443>
        ServerName testdac.mysite.mydomain

        #LogLevel debug

        # https activation
        SSLEngine on
        SSLCertificateFile XXXXXXX.crt
        SSLCertificateKeyFile XXXXXXX.key

        # Loading Lemonldap::Portal::Login module
        PerlModule Lemonldap::Portal::Login
        <Location /DACLogin>
                # let execute under mod_perl
                SetHandler perl-script
                # execute in the response generation phase of apache request handling
                PerlResponseHandler Lemonldap::Portal::Login
                # the domain wich we control
                PerlSetVar Domain mysite.mydomain
                # the name of the organization
                PerlSetVar Organization MyOrganization
                # wich ldap attribut of the user we need
                PerlSetVar LdapUserAttributes "profilApplicatif"
                # wich attribut is the login of the user
                PerlSetVar LdapFilterAttribute uid
                # name of the lemonldap cookie
                PerlSetVar Cookie lemondgi
                # make a control based on ip adresse before using the lemonldap cookie
                PerlSetVar ClientIPCheck 1
                # Timeout inactivity berfore the session expires
                PerlSetVar InactivityTimeout 900
                # ldap server
                PerlSetVar Ldap_Server xxxxx
                # dn manager of the ldap server
                PerlSetVar DnManager xxxxxxxxxxxxxx
                # password of the dn manager
                PerlSetVar PasswordManager xxxxxxxx
                # branch where to do the ldap search
                PerlSetVar Ldap_Branch_People xxxxx
                # memcached local and central server
                PerlSetVar SessionParams "( local => ['localhost:11211'] , servers => [10.1.1.1:11211'])"
                # template of the login page
                PerlSetVar LoginPage /usr/local/apache2/htdocs/templates/login.thtml
        </Location>

</VirtualHost>

=head1 SEE ALSO
Lemonldap::Handlers::Generic4a2, Lemonldap::Portal::Standard
http://lemonldap.sourceforge.net/

=head1 AUTHORS
Eric GERMAN <germanlinux@yahoo.fr>
Hamza AISSAT <asthamza@hotmail.fr>
Habib ZITOUNI <zitouni.habib@gmail.com>
Olivier THOMAS <olivier.tho@gmail.com>
Ali POUYA <Ali.Pouya@dgi.finances.gouv.fr>
Shervin AHMADI <Shervin.Ahmadi@dgi.finances.gouv.fr>

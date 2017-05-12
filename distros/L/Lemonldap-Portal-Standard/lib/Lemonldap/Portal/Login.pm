package Lemonldap::Portal::Login;
	
use strict;
use warnings;

	
use Lemonldap::Config::Parameters;
use Lemonldap::Portal::Standard;
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
my $Major;
my $AccessPolicy;
#my $MyApplicationXmlFile; 
my $Ldap_Search_Attributes;
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
sub default {
	my $Entry = shift;
	my $Session = shift;
	my @ProfilApplicatif = $Entry->get_value('profilapplicatif');
        foreach my $Ligne (@ProfilApplicatif){
                my ($Arg1, $Arg2, $Arg3) = ( $Ligne =~ /^(.+?);(.+?);(.+)/ );
                $Arg1 =~ s/ //g;
                $Session->{$Major}{lc($Arg1)} = $Arg2;
        }
}





sub My_Session {
	my $self = shift;
	my $AccessRule = shift;
	my %Session;
	my $Entry = $self->{entry};
	$Session{dn} = $Entry->dn();
	$self->{dn} = $Entry->dn();		
	&{$self->{AccessPolicy}}($Entry,\%Session);
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
        $Major = $Conf->{ORGANIZATION};
        if ( ! defined($Major) ){
            $Major = "authz_headers";
        }
        $Login_Url = $Conf->{PORTAL};
	$AccessPolicy = $Conf->{ACCESSPOLICY};
	 if ( ! defined($AccessPolicy) ){
            $AccessPolicy = 'default';
        }

        $IpCheck = $Conf->{CLIENTIPCHECK};
        $SessCacheRefreshPeriod = $Conf->{SESSCACHEREFRESHPERIOD};
        $Ldap_Search_Attributes = $Conf->{LDAPSEARCHATTRIBUTES};
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
        if (defined($LdapUserAttributes)){
              @attrs = split(/\s+/,$LdapUserAttributes);
        }else{
              @attrs = ();
        }

        my @base = split(/\s*:\s*/,$Ldap_Branch_People);
        $MemcachedServer = $Conf->{SERVERS};

	if ( $Stack_User->{'AlreadyCreated'} ){
		undef $Stack_User->{'error'};		
	}else{
		$Stack_User = Lemonldap::Portal::Standard->new('msg' => $Messages, 'setSessionInfo' => \&My_Session, 'attrs' => \@attrs, 'base' => \@base ,'AccessPolicy' => \&$AccessPolicy);
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
					   'Attributes' => $Ldap_Search_Attributes  
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
			$Message = '';
		}	
	
		
		# Login Page sending
		my $Identifiant = $Retour->user;
		($UrlCode, $UrlDecode) = $Stack_User->getAllRedirection;
		$Data = { 'urlc' => $UrlCode,
			     'urldc' => $UrlDecode,
			     'message' => $Message,
			     'identifiant' => $Identifiant,
			     'ip' => "DAC : ".$DacHostname
			    };
		
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

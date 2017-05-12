package Lemonldap::Portal::LoginFake;
	
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
our $VERSION = '3.1.1';

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
#my $InactivityTimeout; 
#my $Encryptionkey; 
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
sub My_Session {
	my $self = shift;
	my $paramxml = $self->{line_session};

	my %Session;

	my $entry = $self->{entry};
	my $obj = Lemonldap::Portal::Session->init ($paramxml,'entry' =>$entry) ;
	$self->{infosession} = $obj;


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

################  enlevver ca ################

##############################################
		if (! $html) {
		    my $file ;
		    open($file ,"<$page_html");
                    local $/;
		    $/ ='';
                    $html = <$file>;
                    close $file;
                      }

        	$Ldap_Server = $Conf_Domain->{ldap_server};
	        $Ldap_Branch_People = $Conf_Domain->{ldap_branch_people};
	        $Ldap_Dn_Manager = $Conf_Domain->{DnManager};
	        $Ldap_Pass_Manager = $Conf_Domain->{passwordManager};
	        $Ldap_Port = $Conf_Domain->{ldap_port};
        	$Ldap_Search_Bases = $Ldap_Branch_People;
	        if (defined($r->dir_config('LdapSearchBases'))){
        	        $Ldap_Search_Bases = $r->dir_config('LdapSearchBases').":".$Ldap_Search_Bases;
        	}
	        my @base = split(/\s*:\s*/,$Ldap_Search_Bases);
		
		$MemcachedServer = $Parameters->formateLineHash($Parameters->findParagraph('session','memcached')->{SessionParams});
		$CookieName = $Conf_Domain->{Cookie};

 $line_session = $Conf_Domain->{DefinitionSession};

		$Stack_User = Lemonldap::Portal::Standard->new(
			'msg' => $Messages, 
                        'setSessionInfo' => \&My_Session,
                      'controlTimeOut' => \&my_none,
                   # 'controlSyntax' => \&my_none,
                      'controlIP'    =>  \&my_none,
	              'bind'     =>  \&my_none,
                      'controlCache' => \&my_none,
		       'formateFilter' =>\&my_none,
                      'formateBaseLDAP' =>\&my_none,
                      'contactServer'  =>\&my_none,
                      'search'  =>\&my_entry,
                      'unbind'  =>\&my_none,
                      'credentials' =>\&my_none,
                         );               
 	       $Stack_User->{'AlreadyCreated'} = "true";
               $Stack_User->{line_session} = $line_session;
   
	    }
		
	my $UrlCode;
	my $UrlDecode;
	my $Erreur;
	my %Params = Vars;
        my $buf;
# copy POST data, if any
#	if ( $r->method eq 'POST' ) {
#	my $entete =$r->headers_in();
#        my $len = $entete->{'Content-length'};
#        $r->read( $buf, $len );
#      my @arams= split '&',$buf;
#       for (@arams) {
#           (my $cle,my $val) = /(.+?)=(.+)/;       
#      $Params{$cle}= $val if $cle; 
#} 
#}	
        
        my $l= Dumper (\%Params);
	my $Retour = $Stack_User->process( 'param' => \%Params, 
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
        $r->print;

$r->print($html_ok);

########## ici page en cas d erreur #############
	}	
	else 	
	{	
		# Sending Redirect to Generic
				
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
		my $dotdomain= ".".$MyDomain;
		$log->info("Set-Cookie: -name   => $CookieName  -value  => $Session_Id -domain => ".".$dotdomain -path   => $PathCookie");
        
		my $LemonldapCookie = CGI::cookie(
                	    -name   => $CookieName,
	                    -value  => $Session_Id,
        	            -domain => $dotdomain,
                	    -path   => $PathCookie,
                	);

		$UrlDecode = $Retour->getRedirection();
		$UrlDecode = $Menu if ( $UrlDecode eq '' );
  if ($UrlDecode) {

#$UrlDecode =~ s/priv//g;
       print CGI::header( -Refresh => '0; URL='.$UrlDecode, -cookie => $LemonldapCookie );

               return DONE;		

  }  else {	  
	      	$r->content_type('text/html');
        $r->headers_out->add( 'Set-Cookie' => $LemonldapCookie );

        $r->print;
$r->print(<<END1);
<html>
<head><title>lemonldap websso</title></head>
<body>
<h1>Hello in lemonldap websso 'world</h1>
Congratulation your are enter in the  lemonldap'world
<p>Your id_session is :$Session_Id<p>
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

package Lemonldap::Handlers::Core;
use strict;
#A retirer en prod
use Data::Dumper;
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.1.0';
our $VERSION_LEMONLDAP = "3.1.0";
our $VERSION_INTERNAL  = "3.1.0";

sub locationRules  {
    my %param = @_;
# first retrieve session 
my $id = $param{'id'} ;
my $config =$param{'config'} ;
my $uri = $param{'uri'};
my $host = $param{'host'};
my $target =$param{'target'};
my $_session = Lemonldap::Handlers::Session->get ('id' => $id ,
                                                          'config' => $config) ;  


if (keys(%{$_session}) == 0){
return 0;
}


my $_trust  = Lemonldap::Handlers::Policy->get (  
	                                               'session' =>$_session ,
						       'parameters' => \%param );
my $result =$_trust->{profil} ; 
my $response = $_trust->{response} ;

my $h = {dn => $_session->{dn} ,uid=>$_session->{uid}, string => $_trust->{profil} , response => $_trust->{response} , clientIPAdress => $_session->{clientIPAdress} , SessExpTime => $_session->{SessExpTime} }; 

return $h;
}

sub getHeader {
    my %param = @_;
# first retrieve session 
my $result = $param{'profil'} ;
my $config =$param{'config'} ;
my $uid = $param{'uid'};
my $dn = $param{'dn'};
return Lemonldap::Handlers::Header->get('profil' => $result ,
                                               'dn' => $dn ,
                                               'config' => $config,
                                               'uid' => $uid);  
}

sub forgeHeader {
    my %param = @_;
# first retrieve session 
my $result = $param{'line'} ;
my $config =$param{'config'} ;
my $reponse= Lemonldap::Handlers::Header->forge('line' => $result ,
						'config' => $config,);
    my $h;
    if ( $reponse != 0 ){	
	$h ={header => $reponse->{header},content => $reponse->{content} ,decoded =>$reponse->{decoded} ,user =>$reponse->{user}};
    }
    return $h;
}
sub ParseHtml {
    my %param = @_;
# first retrieve session 
my $html = $param{'html'} ;
my $uri = $param{'uri'} ;
my $env = $param{'https'} ;
my $config =$param{'config'} ;
my $host= $param{'host'};
my $target= $param{'target'};
return Lemonldap::Handlers::Html->get('html' => $html ,
				       'host' => $host,
				       'uri' => $uri, 
                                       'target' => $target,
                                       'config' => $config,
                                        'https' =>$env,);
}

##########################################################
#Return code for Check refresh :			 #
#       0 : The sessExpTime hasn't been depassed yet     #
#       1 : The request LDAP has to be done		 #
#       2 : The request LDAP hasn't to be done		 #
##########################################################

sub Check_Refresh {     
	my %param = @_;
# first retrieve session
	my $id = $param{'id'} ;
	my $config = $param{'config'} ;
	my $uri = $param{'uri'};
	my $host = $param{'host'};
	my $sessExpTime = $param{'ExpTime'};
	my $target = $param{'target'};
	my $log = $param{'logs'};
if ( time() > $sessExpTime ) {

#The request must been done on the central Memcached, so we have to delete temporarly the local server
	

        my $local = $config->{SERVERS}->{'local'};
	
#We check if a level 4 memcached has been configured
        if ($config->{SERVERS}->{'servers'}){
		my $local = $config->{SERVERS}->{'local'};
		delete  $config->{SERVERS}->{'local'};
	}
#On effectue la requete sur le serveur principal
	my $HashSession = Lemonldap::Handlers::Session->get ('id' => $id ,
                                                          'config' => $config);
	     if ($config->{SERVERS}->{'servers'}){
     	           $config->{SERVERS}->{'local'} = $local;
             }

	if (keys(%{$HashSession}) == 0 ){
#the memcached is unreachable
$log->warn("$config->{HANDLERID}: The central memcached is unreachable.Please check if your server is on or if your configuration file is correct.");
		unless($config->{SERVERS}->{'local'}){
$log->err("$config->{HANDLERID}: Can't acces to any memcached server => Internal error");
#On a effectué une recherche infructueuse sur le serveur principal et il n'y a pas de serveur loca
#if the search has been done on the level 3 (means that there is no level 4) we must invite the user to re-authentification
			return (-1,{},0,0);
		}
#if not we must try to do it again on the level 3 cache
	
		my $central = $config->{SERVERS}->{'servers'};
                delete  $config->{SERVERS}->{'servers'};

#On effectue la requete sur le serveur local
		$HashSession = Lemonldap::Handlers::Session->get ('id' => $id ,
                                                          'config' => $config);

		$config->{SERVERS}->{'servers'}= $central;

		if (keys(%{$HashSession}) == 0){        
			return (-1,{},0,0);
        		$log->err("$config->{HANDLERID}: Can't acces to the local memcached server => Internal error"); 
	       }

	}	
 	
	my $_trust  = Lemonldap::Handlers::Policy->get ('session' =>$HashSession , 
							'parameters' => \%param);


my $test = $HashSession->{SessExpTime};
        if ( $HashSession->{SessExpTime} eq $sessExpTime){
#This Httpd process must refresh the cache by requesting the LDAP server
                return (1,$HashSession,$_trust->{profil},$_trust->{response});
        }else{
#The request LDAP has already be done by another process
                return (2,$HashSession,$_trust->{profil},$_trust->{response});
        }
    }else {
#The sessExptime is not yet expired 
        return (0,{},undef);
    }
}




package Lemonldap::Handlers::Html ;
sub get {
    my $class= shift;
     my %_param = @_;
    $_param{config}->{'REWRITEHTMLPLUGIN'}= 'Lemonldap::Handlers::RewriteHTML'    unless $_param{config}->{'REWRITEHTMLPLUGIN'} ; 
     my $api = $_param{config}->{'REWRITEHTMLPLUGIN'} ;
    eval "use $api;"; 
    my $session =$api->get(%_param) ;
#    bless $session, $class;
    return $session;


}
package Lemonldap::Handlers::Session ;
use Data::Dumper;
sub  get {
    my $class= shift;
     my %_param = @_;
    $_param{config}->{'SESSIONSTOREPLUGIN'}= 'Lemonldap::Handlers::Memsession'    unless $_param{config}->{'SESSIONSTOREPLUGIN'} ; 
     my $api = $_param{config}->{'SESSIONSTOREPLUGIN'} ;
    eval "use $api;"; 
    my $html =$api->get(%_param) ;
#    bless $session, $class;





  return $html;
  } 

package Lemonldap::Handlers::Policy ;

sub  get {
    my $class=shift;
    my %_param = @_;
    $_param{parameters}->{config}->{'PLUGINPOLICY'}= 'Lemonldap::Handlers::MatrixPolicy'    unless $_param{parameters}->{config}->{'PLUGINPOLICY'} ;
    my $api = $_param{parameters}->{config}->{'PLUGINPOLICY'} ;
    eval "use $api;" ;;
    my $trust =$api->get(%_param) ;
    #  bless $trust , $class; 
   return $trust;
  } 
package Lemonldap::Handlers::Header ;
sub  get {
    my $class=shift;
    my %_param = @_;
    $_param{config}->{'PLUGINHEADER'}= 'Lemonldap::Handlers::AuthorizationHeader' unless $_param{config}->{'PLUGINHEADER'} ;
    my $api = $_param{config}->{'PLUGINHEADER'} ;
    print STDERR "ERIC A SUP $api\n";
    eval "use $api;"; 
    my $header =$api->get(%_param) ;
    # bless $header , $class; 
   return $header;
  } 
sub  forge {
    my $class=shift;
    my %_param = @_;
    $_param{config}->{'PLUGINHEADER'}= 'Lemonldap::Handlers::AuthorizationHeader' unless $_param{config}->{'PLUGINHEADER'} ;
    my $api = $_param{config}->{'PLUGINHEADER'} ;
    eval "use $api;"; 
    my $header =$api->forge(%_param) ;
    # bless $header , $class; 
   return $header;
  } 

  


1;

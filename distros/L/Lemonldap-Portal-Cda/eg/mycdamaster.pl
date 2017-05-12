#!/usr/bin/perl -w
use Lemonldap::Portal::Cda;
use Lemonldap::Config::Parameters;
use CGI ':cgi-lib';
use MIME::Base64;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;
our $cookie_name;
our $domain;
my $message = '';
my %params =Vars;
my $ligne= Dumper(%params);
my $conf= Lemonldap::Config::Parameters->new ( 
  						file => "/opt/apache_dev/conf/application_new.xml" , 
                                                cache => 'CONF' );
my $config= $conf->getDomain('appli.dgi') ;
$cookie_name= $config->{cookie};
$domain= "."."appli.cp";
my $stack_user= Lemonldap::Portal::Cda->new(type=> 'master');
my $urlc;
my $urldc; 
my $config_slave= $conf->getDomain('appli.cp') ;
my $controlslave= $config_slave->{slavecda};
my $loginpage= $config->{login};
$retour=$stack_user->process(param           =>  \%params,           
                             );
    if ($retour)   { 
	$message=$retour->message;
	$erreur=$retour->error;
                   }
if ($erreur) {  #it's normal 
$session_id = CGI::cookie( -name => $cookie_name );
my $urlc;
my  $urldc;
($urlc,$urldc) = $retour->getAllRedirection;
if(  defined( $session_id ) )
{
##==============================================================================
##l utilisateur est deja authentifier  on le redirige vers l url demand en 
## ajoutant  un parametre cda=idsession
##==============================================================================
## optional 
##
# we can  retrieve the session
## but  it's an access on cache  
#my %session ;
#my $fg = eval $session;
#my  %session;
#   tie %session, 'Apache::Session::Memorycached', $session_id,
#     {
#       'servers' =>  $fg
#      };
#
#	unless ($session{uid}){  ### problem not sesssion attached  found 
#	 undef $session_id;
#	  last;
#	    }
  # good   what are you doing now ?
# we go to the page which give you the cookie    
print CGI::redirect($controlslave."?op=$session_id&url=".$urlc);
exit( 0 );

  
  }
unless ($session_id) {  # no cookie or no  valid session id  
                        # the user must pass to login page 
                        # the master domain
print CGI::redirect($loginpage."?op=c&url=".$urlc);
exit( 0 );
}

 }

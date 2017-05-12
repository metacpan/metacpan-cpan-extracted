#!/usr/bin/perl -w
use Lemonldap::Portal::Cda;
use Lemonldap::Config::Parameters;
use CGI ':cgi-lib';
use MIME::Base64;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;
use Template;
my $message = '';
#my %param;
my %params =Vars;
my $conf= Lemonldap::Config::Parameters->new ( 
  						file => "/opt/apache-dev/conf/application_new.xml" , 
                                                cache => 'CONF' );
my $config= $conf->getDomain('appli.cp') ;
my $cookie_name= $config->{cookie};
my $domain= "."."appli.cp";
my $menu= $config->{menu};
my $path = $config->{path};
my $template_config=$config->{templates_options};
my $tempopt= 'templates_dir';
my $valeur= $config->{$tempopt};
my $templates_opt=$conf->formateLineHash($template_config,$tempopt,$valeur);
$template_config= $templates_opt;

my $stack_user= Lemonldap::Portal::Cda->new(type=> 'slave');
my $urlc;
my $urldc; 
my $config_master= $conf->getDomain('appli.dgi') ;
my $loginpage= $config_master->{login};


$retour=$stack_user->process(param           =>  \%params,           
                             );
    if ($retour)   { 
	$message=$retour->message;
	$erreur=$retour->error;
                   }
if ($erreur) {  #it's normal 
my $session_id = $stack_user->getSession;
my $urlc;
my  $urldc;
($urlc,$urldc) = $retour->getAllRedirection;
if ($session_id)  {

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
##  we make the cookie on slave domain 
my $cookie = CGI::cookie(
                    -name   => $cookie_name,
                    -value  => $session_id,
                    -domain => $domain,
                    -path   => $path,
                );

$urldc = $menu  if( $urldc eq '' );
   my $data = {
     urldc   => $urldc,
     message => 'CDA successed Session '.$session_id,
   };
   my $template=Template->new( $template_config );
   print CGI::header( -Refresh=>'1; URL='.$urldc, -cookie=>$cookie );
   $template->process( 'redirect.thtml', $data ) or die($template->error());
exit( 0 );
 }

unless ($session_id) {  # no cookie or no  valid session id  
                        # the user must pass to login page 
                        # the master domain
print CGI::redirect($loginpage."?op=c&url=".$urlc);
exit( 0 );
}
#here all are ok   we must retrieve its session from session_id			}

 }

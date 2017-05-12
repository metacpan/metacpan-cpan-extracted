#!/usr/bin/perl 
use Lemonldap::Portal::Standard;
use Lemonldap::Config::Parameters;
use CGI ':cgi-lib';
use Template;
use Net::LDAP;
use MIME::Base64;
use Apache::Session::Memorycached;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;
#use ReverseProxyConfig;   # 
our $template_config;
our $login;
our $applications_list_url;
our $path;
our $cookie_name;
our $domain;
our $ldap_server;
our $ldap_port;
our $ldap_branch_people;
our $pass ;
our $session;
my $message = '';
#my %param;
my %params =Vars;
my $conf= Lemonldap::Config::Parameters->new ( 
  						file => "/opt/apache/portail/application_new.xml" , 
                                                cache => 'CONF' );
print STDERR "je passe ici $session\n";
my $config= $conf->getDomain('appli.cp') ;
print STDERR "je passe ici $session\n";
 $template_config=$config->{templates_options};
my $tempopt= 'templates_dir';
my $valeur= $config->{$tempopt};
my $templates_opt=$conf->formateLineHash($template_config,$tempopt,$valeur);
$template_config= $templates_opt;
$applications_list_url = $config->{menu};
$login= $config->{login}; 
$cookie_name= $config->{cookie};
$domain= ".".$config->{name};
$path= $config->{path};
$ldap_server= $config->{ldap_server};
$ldap_port= $config->{ldap_port};
$ldap_branch_people=$config->{ldap_branch_people};
$dnmanager= $config->{DnManager} ;
$pass = $config->{passwordManager};
my $sessionrr= $conf->findParagraph('session','memcached');  
$session =$sessionrr->{servers} ;

my $stack_user= Lemonldap::Portal::Standard->new();
my $urlc;
my $urldc; 


$retour=$stack_user->process(param           =>  \%params,           
                             server          => $ldap_server,
                             port            => $ldap_port,
                             DnManager       => $dnmanager,
                             passwordManager => $pass,
                             branch => $ldap_branch_people  
                             );
    if ($retour)   { 
	$message=$retour->message;
	$erreur=$retour->error;
                   }
if ($erreur) {
my $ident = $retour->user;
### il n y rien de passee , afficher  la grille 
##------------------------------------------------------------------------------
## Génération du HTML de la page de formulaire
##------------------------------------------------------------------------------
my $data = {
  'urlc'        => $urlc,
  'urldc'       => $urldc,
  'message' => $message,
  'identifiant' => $ident,
};

my $template=Template->new( $template_config );

print CGI::header();

$template->process( 'login.thtml', $data ) or die($template->error());

##==============================================================================
## Fin du fichier
##==============================================================================
exit;
}  
##==============================================================================## Ici tout est ok il faut creer le hash sur la session
##==============================================================================
my $monhash= $retour->infoSession;
my $fg = eval $session;

  my  %session;
   tie %session, 'Apache::Session::Memorycached', undef,
      {
       'servers' =>  $fg     
      };

foreach (keys %{$monhash}) {  
   $session{$_}=$monhash->{$_} if $monhash->{$_} ;   
   }

my $session_id = $session{_session_id};

my $urldc ;
my $urldc=$retour->getRedirection ;
   untie( %session );

##---------------------------------------------------------------------------
## Création du cookie
##---------------------------------------------------------------------------
   my $cookie = CGI::cookie(
                    -name   => $cookie_name,
                    -value  => $session_id,
                    -domain => $domain,
                    -path   => $path,
                );

 print STDERR "ericgerman : session $session_id\n";
  ##---------------------------------------------------------------------------
   ## Génération du HTML par le template
   ##---------------------------------------------------------------------------
   $urldc = $applications_list_url
      if( $urldc eq '' );

   my $data = {
     urldc   => $urldc,
     message => 'Session '.$session_id.$cookie ,
   };

   my $template=Template->new( $template_config );

   print CGI::header( -Refresh=>'1; URL='.$urldc, -cookie=>$cookie );
   $template->process( 'redirect.thtml', $data ) or die($template->error());

   exit( 0 );
  


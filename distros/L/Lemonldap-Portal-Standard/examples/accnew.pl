#!/usr/bin/perl 
use Lemonldap::Portal::Standard;
use CGI ':cgi-lib';
use Template;
use Net::LDAP;
use MIME::Base64;
use Apache::Session::Memorycached;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;
use ReverseProxyConfig;   # 
my $message = '';
#my %param;
my %params =Vars;
my $ligne= Dumper (\%params);
print STDERR "ericgerman $ligne\n"; 
my $stack_user= Lemonldap::Portal::Standard->new();
my $urlc;
my $urldc; 

$retour=$stack_user->process(param           =>  \%params,           
                             server          => $ReverseProxyConfig::ldap_serveur,
                             port            => $ReverseProxyConfig::ldap_port,
                             DnManager       => $ReverseProxyConfig::ldap_admin_dn,
                             passwordManager => $ReverseProxyConfig::ldap_admin_pd,
                             branch => $ReverseProxyConfig::ldap_branch_people  
                             );
    if ($retour)   { 
	$message=$retour->message;
	$erreur=$retour->error;
        print STDERR "DEBUG  $erreur - \n"; 

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

my $template=Template->new( $ReverseProxyConfig::template_config );

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

  my  %session;
   tie %session, 'Apache::Session::Memorycached', undef,
      {
                servers        => $ReverseProxyConfig::cache_servers,
                local        => $ReverseProxyConfig::cache_local,
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
                    -name   => $ReverseProxyConfig::cookie_name,
                    -value  => $session_id,
                    -domain => $ReverseProxyConfig::cookie_domain,
                    -path   => $ReverseProxyConfig::cookie_path,
                );

  ##---------------------------------------------------------------------------
   ## Génération du HTML par le template
   ##---------------------------------------------------------------------------
   $urldc = $ReverseProxyConfig::applications_list_URL
      if( $urldc eq '' );

   my $data = {
     urldc   => $urldc,
     message => 'Session '.$session_id.$cookie ,
   };

   my $template=Template->new( $ReverseProxyConfig::template_config );

   print CGI::header( -Refresh=>'1; URL='.$urldc, -cookie=>$cookie );
   $template->process( 'redirect.thtml', $data ) or die($template->error());

   exit( 0 );
  


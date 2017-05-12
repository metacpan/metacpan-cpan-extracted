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
use Crypt::CBC;
my $template_config;
my $login;
my $applications_list_url;
my $path;
my $cookie_name;
my $domain;
my  $ldap_server;
my $ldap_port;
my $ldap_branch_people;
my $pass ;
my $message = '';
#my %param;
my %params =Vars;
my $ligne=Dumper(\%params);
my $FILE = "/usr/local/apache2/lemonldap/application.xml" ;
my $DOMAIN="int.noisiel.dgi";
my $conf= Lemonldap::Config::Parameters->new ( 
  						file => $FILE , 
                                                cache => 'CONF' );
my $config= $conf->getDomain($DOMAIN) ;
$template_config=$config->{templates_options};
my $tempopt= 'templates_dir';
my $valeur= $config->{$tempopt};
my $templates_opt=$conf->formateLineHash($template_config,$tempopt,$valeur);
my $ligne=Dumper($templates_opt);
$template_config= $templates_opt;
$applications_list_url = $config->{Menu};
$login= $config->{Portal}; 
$cookie_name= $config->{Cookie};
$inactivity = $config->{InactivityTimeout};
$domain= ".".$DOMAIN;
$path= "/";
$ldap_server= $config->{ldap_server};
$ldap_branch_people=$config->{ldap_branch_people};
my $sessionrr= $conf->findParagraph('session','memcached'); 
my $serveur= $conf->formateLineHash($sessionrr->{SessionParams}); 
my $dnmanager= $config->{DnManager} ;
my $pass = $config->{passwordManager};


#######################
# exemple of call back
#######################
my $mess= {1 => 'Votre connexion a expir&eacute; vous devez vous authentifier de nouveau',
             2 => 'Les champs &quot;Identifiant&quot; et &quot;Mot de passe&quot doivent &ecirc;tre remplis',
             3 => 'Wrong directory manager account or password' ,
             4  => ' n\'a pas &eacute;t&eacute; trouv&eacute; dans l\'annuaire',
             5  => 'Mot de passe erron&eacute;' ,
             };
#######################
#######################
#sub id_massage {
# my $self = shift;
#my $ligne=Dumper ($self);
# my $user =$self->{user} ;
# $user.= "-cp" if $user !~ /-cp$/;
# $self->{user} = $user;
#
#}
sub my_session {
###################
# initial operation
###################
	my $self=shift;
	my %session;
	my $entry=$self->{entry} ;
   	$session{dn}   = $entry->dn();
   	$self->{dn}   = $entry->dn();
   	$session{uid}  = $entry->get_value('uid');
#   	$session{cn}   = $entry->get_value('cn');
#   	$session{personaltitle} = $entry->get_value('personaltitle');
#   	$session{mail}          = $entry->get_value('mail');
#   	$session{title}      = $entry->get_value('title');
## my overlay    
#   $session{departement}   = $entry->get_value('departement');
#   $session{codique}       = $entry->get_value('codique');
#   $session{boitier}       = "lemonintimpots";
#   $session{grade} = $entry->get_value('grade');
#   $session{fonction} = $entry->get_value('fonction');
#   $session{igap} = $entry->get_value('igap');
#   my @mefiapplidgcp = $entry->get_value('mefiapplidgcp');
#   my @mefiappliapt  = $entry->get_value('mefiapplihabilitdgcp');
#   my @mefiapplidgi  = $entry->get_value('mefiapplidgi');
   my @profilapplicatif  = $entry->get_value('profilapplicatif');
my $ligne = Dumper ($entry) ;
#print STDERR "on cherche le profil : $ligne\n";
#
   # construction tableau applidgcp
#   foreach my $ligne (@mefiapplidgcp)
#   {
#      my @tab        = split ';' ,$ligne;
#      my $cle        = 'APT_'.$tab[0];
#      my $valeur     = $ligne;
#      $session{$cle} = $valeur;
#   }
#   foreach my $ligne (@mefiappliapt)
#   {
#      my ($arg,$arg2) = ( $ligne =~ /^(.+?);(.+?)$/ );
#      $arg =~ s/ //g;
#      $session{dgcp}{$arg} = $arg2;
#   }
#
# mefiapplidgi
   foreach my $ligne (@profilapplicatif)
   {
      my ($arg1,$arg2,$arg3) = ( $ligne =~ /^(.+?);(.+?);(.+)/ );
      $arg1=~ s/ //g;
#                        $complement=":$suite";
  
    $session{profilapplicatif}{$arg1} = $arg2;
   }

       # all is done 
my $ligne = Dumper (%session) ;
       $self->{infosession}= \%session;
}

#################
# end of example
#################
my $stack_user= Lemonldap::Portal::Standard->new('msg' => $mess,
#                                                 'formateUser' => \&id_massage,
                                                 'setSessionInfo' => \&my_session
                                                 );
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
my ($urlc,$urldc ) = $stack_user->getAllRedirection;
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

  my  %session;
   tie %session, 'Apache::Session::Memorycached', undef, $serveur;     

foreach (keys %{$monhash}) {  
   $session{$_}=$monhash->{$_} if $monhash->{$_} ;   
   }

my $session_id = $session{_session_id};
my $ligne = Dumper (%session) ;

my $urldc ;
my $urldc=$retour->getRedirection ;
   untie( %session );

##---------------------------------------------------------------------------
## Création du cookie
##---------------------------------------------------------------------------
print STDERR "cook : $cookie_name - $domain -  $path - $session_id \n";
#Positionnement de la valeur time_end
my $val_test;
if(defined($config->{InactivityTimeout}) && $inactivity!=0 ){
	my $time_end = time() + $inactivity;
	if (defined($config->{Encryptionkey})){
		$timeout_key = $config->{Encryptionkey};
		my $cipher = new Crypt::CBC(-key => $timeout_key,-cipher => 'Blowfish',-iv => 'lemonlda',-header => 'none');
		$time_end = $cipher->encrypt_hex($time_end);
			
	}
	#Chaine utilise comme separateur entre l'id de session et le time_end
	$sep = "sep";
	#concatenation des deux valeurs
	$val_test = $session_id.$sep.$time_end;
}else{
	$val_test = $session_id;
}    
   my $cookie = CGI::cookie(
                    -name   => $cookie_name,
                    -value  => $val_test,
                    -domain => $domain,
                    -path   => $path,
                );

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
  

